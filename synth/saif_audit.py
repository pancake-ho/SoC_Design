"""Check physical gate-net activity against the measured, per-bit SAIF records."""
import json,math,re
from pathlib import Path

def canonical(name):
 if name.startswith('"') and name.endswith('"'):name=name[1:-1]
 for _ in range(6):
  new=name.replace('\\\\','\\').replace('\\[','[').replace('\\]',']')
  if new==name:break
  name=new
 return name

def saif_data(path,scope='tb_project/adapter/dut'):
 text=Path(path).read_text();stack=[[]]
 for t in re.findall(r'\(|\)|"(?:\\.|[^"\\])*"|(?:\\.|[^\s()"])+',text):
  if t=='(':new=[];stack[-1].append(new);stack.append(new)
  elif t==')':
   if len(stack)<2:raise ValueError('Unbalanced SAIF')
   stack.pop()
  else:stack[-1].append(t)
 if len(stack)!=1 or len(stack[0])!=1:raise ValueError('Incomplete SAIF')
 root=stack[0][0];duration=None;scale=None;records={};found=False
 for node in root[1:]:
  if isinstance(node,list) and node:
   if node[0]=='DURATION':duration=int(node[1])
   if node[0]=='TIMESCALE':scale=float(node[1])*{'fs':1e-6,'ps':1e-3,'ns':1.,'us':1e3}[node[2]]
 def walk(node,parents):
  nonlocal found
  if not isinstance(node,list) or not node:return
  if node[0]=='INSTANCE':
   parts=parents+[canonical(node[1])];full='/'.join(parts)
   if full==scope:found=True
   if full==scope or full.startswith(scope+'/'):
    relative=full[len(scope):].strip('/')
    for group in node[2:]:
     if isinstance(group,list) and group and group[0] in ('NET','PORT'):
      for item in group[1:]:
       if not isinstance(item,list) or len(item)<2:continue
       values={v[0]:int(v[1]) for v in item[1:] if isinstance(v,list) and len(v)==2 and v[0] in ('T0','T1','TX','TZ','TC','IG')}
       key='/'.join(v for v in [relative,canonical(item[0])] if v)
       if key in records and records[key]!=values:raise ValueError('Ambiguous SAIF name '+key)
       records[key]=values
   for child in node[2:]:
    if isinstance(child,list) and child and child[0]=='INSTANCE':walk(child,parts)
  else:
   for child in node[1:]:walk(child,parents)
 walk(root,[])
 if not found or not duration or not scale or not records:raise ValueError('Missing measured scope or SAIF duration')
 for name,v in records.items():
  if any(n<0 for n in v.values()) or sum(v.get(k,0) for k in ('T0','T1','TX','TZ'))!=duration:raise ValueError('Invalid activity duration '+name)
 return dict(duration_ticks=duration,duration_ns=duration*scale,nets=records)

def activity_records(path):
 text=Path(path).read_text(errors='replace');records={}
 pattern=r'^\((.*?): (?:scenario = [^,]+, )?probability = ([^,]+), toggle_rate = ([^,]+), type = ([a-z]+)\)'
 for m in re.finditer(pattern,text,re.M):records[canonical(m[1])]=dict(probability=float(m[2]),toggle_rate=float(m[3]),type=m[4])
 if not records:raise ValueError('Empty switching activity evidence '+str(path))
 return records

def missing_objects(path):
 text=Path(path).read_text();out={}
 for kind in ('ports','nets','pins'):
  m=re.search(r'List of Non-annotated '+kind+r'\s*:\s*\n(.*?)(?=\n\s*List of Non-annotated|\n-{5,}|\Z)',text,re.S)
  if not m:raise ValueError('Missing SAIF coverage section '+kind)
  names=[canonical(line.strip()) for line in m[1].splitlines() if line.strip()]
  out[kind]=[] if names==['0 '+kind] else names
 return out

def audit(saif,net_report,pin_report,connectivity,coverage,time_unit_ns=1.0,port_report=None):
 if not math.isfinite(time_unit_ns) or time_unit_ns<=0:raise ValueError('Invalid library time unit')
 data=saif_data(saif);nets=activity_records(net_report);pins=activity_records(pin_report);bad=[];unknown=[];compared=0
 constants={name:v for name,v in nets.items() if name not in data['nets'] and
  v['type']=='sta' and v['probability'] in (0.,1.) and v['toggle_rate']==0}
 unmeasured=[name for name in nets if name not in data['nets'] and name not in constants]
 def compare(kind,name,signal,actual):
  nonlocal compared
  v=data['nets'].get(signal)
  if v is None:return None
  # read_saif's documented default inertial-glitch derating is 0.5.
  expected_rate=(v.get('TC',0)+0.5*v.get('IG',0))/data['duration_ns']*time_unit_ns
  known=v.get('T0',0)+v.get('T1',0)
  expected_p=v.get('T1',0)/float(known) if known else None
  uncertain=v.get('TX',0)+v.get('TZ',0)
  if uncertain:unknown.append(dict(kind=kind,name=name,signal=signal,unknown_ticks=uncertain,unknown_fraction=uncertain/float(data['duration_ticks'])))
  compared+=1
  mismatch=(not math.isfinite(actual['probability']) or not math.isfinite(actual['toggle_rate']) or
   (expected_p is not None and not math.isclose(actual['probability'],expected_p,rel_tol=2e-6,abs_tol=2e-9)) or
   not math.isclose(actual['toggle_rate'],expected_rate,rel_tol=2e-6,abs_tol=2e-9))
  if mismatch:bad.append(dict(kind=kind,name=name,signal=signal,expected_probability=expected_p,actual_probability=actual['probability'],expected_toggle_rate=expected_rate,actual_toggle_rate=actual['toggle_rate'],type=actual['type']))
  return not mismatch
 for name,actual in nets.items():compare('net',name,name,actual)
 if port_report is not None:
  for name,actual in activity_records(port_report).items():compare('port',name,name,actual)
 connections={}
 for line in Path(connectivity).read_text().splitlines():
  if not line or line.startswith('pin\t'):continue
  name,direction,count,names=line.split('\t',3);connections[canonical(name)]=dict(direction=direction,count=int(count),nets=[canonical(n) for n in names.split(';') if n])
 for name,actual in pins.items():
  con=connections.get(name)
  if con and con['count']==1:
   signal=con['nets'][0]
   # SDF interconnect delay can move a pin transition across the window boundary.
   # A directly measured pin record is therefore more precise than its upstream net.
   measured=name if name in data['nets'] else signal
   compare('pin',name,measured,actual)
   if measured not in data['nets'] and signal in constants:
    expected=constants[signal];compared+=1
    if actual['probability']!=expected['probability'] or actual['toggle_rate']!=0:
     bad.append(dict(kind='constant_pin',name=name,signal=signal,expected_probability=expected['probability'],actual_probability=actual['probability'],expected_toggle_rate=0,actual_toggle_rate=actual['toggle_rate'],type=actual['type']))
 missing=missing_objects(coverage);excluded=[];unresolved=[]
 for name in missing['pins']:
  con=connections.get(name)
  if con and con['direction']=='out' and con['count']==0:excluded.append(name)
  else:unresolved.append(name)
 return dict(saif_records=len(data['nets']),audited_net_pin_and_port_records=compared,
  bitwise_mismatch_count=len(bad),bitwise_mismatches=bad,
  measured_unknown_records=len(unknown),unknown_activity_details=unknown,
  sta_inferred_constant_net_count=len(constants),sta_inferred_constant_nets=sorted(constants),
  unmeasured_nonconstant_net_count=len(unmeasured),unmeasured_nonconstant_nets=unmeasured,
  raw_non_annotated={k:len(v) for k,v in missing.items()},
  disconnected_output_pins=excluded,unresolved_non_annotated_pins=unresolved,
  unresolved_non_annotated_ports=missing['ports'],unresolved_non_annotated_nets=missing['nets'],
  activity_coverage_complete=compared>0 and not bad and not unmeasured and not unresolved and not missing['ports'] and not missing['nets'])

if __name__=='__main__':
 import argparse
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('saif',type=Path);p.add_argument('reports',type=Path);p.add_argument('--scenario',default='TT1P05V25C_CMAX');args=p.parse_args()
 r=audit(args.saif,args.reports/'all_net_activity.rpt',args.reports/'all_pin_activity.rpt',args.reports/'pin_connectivity.tsv',args.reports/(args.scenario+'_annotation.rpt'))
 (args.reports/'bitwise_audit.json').write_text(json.dumps(r,indent=2)+'\n')
 print(json.dumps({k:v for k,v in r.items() if not isinstance(v,list)},indent=2))
