"""Conservative simulation representation of a reversed SAED32 ICG window.

This does NOT repair or recharacterize a Liberty library.  It makes a bounded
simulation-only constraint stricter; the original SDF and STA remain evidence.
No check, notifier, or propagation path is removed.
"""
import hashlib,json,re
from decimal import Decimal,ROUND_CEILING

CELL=re.compile(r'^\(CELL\n[ \t]+\(CELLTYPE "(CGLPPRX2_RVT)"\)\n'
                r'[ \t]+\(INSTANCE(?: ([^)\n]+))?\)\n.*?^\)',re.M|re.S)
CHECK=re.compile(r'^(?P<indent>[ \t]+)\((?P<kind>SETUP|HOLD) '
                 r'\((?P<edge>posedge|negedge) (?P<pin>SE|EN)\) '
                 r'\(posedge CLK\) \((?P<values>-?\d+(?:\.\d+)?(?::-?\d+(?:\.\d+)?){2})\)\)[ \t]*$',re.M)
Q=Decimal('0.001')

def prepare_icg_sdf(source,run_dir):
    original=source.read_text(encoding='ascii')
    if '(TIMESCALE 1ns)' not in original:raise ValueError('Unexpected ICG SDF time unit')
    audit=dict(policy='TIGHTEN_ONLY_NO_WAIVER',simulation_precision_ps=1,
               reversed_window_replacement_ps=2,maximum_hold_tightening_ps=5,
               raw_sdf_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
               changes=[],instances=[])
    def cell(m):
        text=m[0];checks={}
        for c in CHECK.finditer(text):
            key=(c['edge'],c['pin'],c['kind'])
            if key in checks:raise ValueError('Duplicate ICG check '+str(key))
            checks[key]=c
        pins={pin for edge,pin,kind in checks}
        if not pins or len(checks)!=4*len(pins):
            raise ValueError('Incomplete CGLPPRX2 timing checks: '+str(m[2]))
        timing=text.split('(TIMINGCHECK',1)[-1]
        records=[line for line in timing.splitlines() if line.lstrip().startswith('(')]
        if any(not CHECK.fullmatch(line) and not line.lstrip().startswith('(WIDTH ') for line in records):
            raise ValueError('Unsupported CGLPPRX2 timing record: '+str(m[2]))
        for pin in sorted(pins):
            for edge in ('posedge','negedge'):
                s=checks[edge,pin,'SETUP'];h=checks[edge,pin,'HOLD']
                sv=[Decimal(v) for v in s['values'].split(':')]
                hv=[Decimal(v) for v in h['values'].split(':')]
                after=[]
                for column,(a,b) in enumerate(zip(sv,hv)):
                    new=b
                    if a+b<0:
                        # A reversed window is invalid for the VCS NTC solver.
                        # Expand its HOLD boundary only. Never shorten setup,
                        # make hold more negative, or mask the resulting check.
                        new=max(b,(2*Q-a).quantize(Q,rounding=ROUND_CEILING))
                        if new-b>5*Q:raise ValueError('ICG inconsistency exceeds validated 5ps tightening: '+str(m[2]))
                        audit['changes'].append(dict(cell=m[1],instance=m[2],pin=pin,edge=edge,column=column,
                            setup_ns=str(a),original_hold_ns=str(b),simulation_hold_ns=str(new),
                            tightening_ps=str((new-b)*1000)))
                    if new<b:raise ValueError('ICG constraint must never be relaxed')
                    after.append(str(new))
                if after!=h['values'].split(':'):
                    replacement=h[0].replace('('+h['values']+')','('+':'.join(after)+')')
                    text=text.replace(h[0],replacement,1)
        audit['instances'].append(m[2])
        return text
    corrected=CELL.sub(cell,original)
    if len(audit['instances'])!=len(re.findall(r'\(CELLTYPE "CGLPPRX2_RVT"\)',original)):
        raise ValueError('Could not parse every CGLPPRX2 instance')
    target=source
    if corrected!=original:
        target=run_dir/'icg_checked.sdf';target.write_text(corrected,encoding='ascii')
    audit['simulation_sdf_sha256']=hashlib.sha256(target.read_bytes()).hexdigest()
    (run_dir/'icg_timing_audit.json').write_text(json.dumps(audit,indent=2)+'\n')
    return target,audit
