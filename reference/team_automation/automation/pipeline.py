"""Team V8 queue transport. Keeps the course RTL harness and synthesis flow unchanged.

All VCS jobs compile and simulate with -R in ONE classroom slot. This is not the
instructor's signed grading runner. Missing physical evidence never becomes PASS.
Python 3.6+, standard library only. Run from an existing authenticated dice shell.
"""
import argparse
import datetime
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tarfile
import time
import uuid

PACKAGE=Path(__file__).resolve().parents[1]
SCENARIOS=tuple(p+'_'+rc for p in ('SS0P95V125C','TT1P05V25C','FF1P16VN40C') for rc in ('CMAX','CMIN'))
PUBLIC=['F%02d'%n for n in range(1,13)]
MAX_RUN_BYTES=2*1024**3
MAX_VCD_BYTES=256*1024**2
MIN_FREE_BYTES=10*1024**3
ACTIVE_RUN=None

def resource_guard():
    if ACTIVE_RUN is None: return
    if shutil.disk_usage(str(ACTIVE_RUN)).free<MIN_FREE_BYTES:
        raise RuntimeError('Team policy: less than 10 GiB free space; stop this job')
    total=0
    for p in ACTIVE_RUN.rglob('*'):
        if not p.is_file(): continue
        try: size=p.stat().st_size
        except FileNotFoundError: continue
        total+=size
        if p.suffix.lower()=='.vcd' and size>MAX_VCD_BYTES:
            raise RuntimeError('Team policy: one VCD exceeded 256 MiB; stop this job')
    if total>MAX_RUN_BYTES: raise RuntimeError('Team policy: run exceeded 2 GiB; stop this job')

def terminal_interrupt(signum,frame):
    raise KeyboardInterrupt('Terminal closed or stop signal '+str(signum))

def save(path,value):
    Path(path).write_text(json.dumps(value,indent=2,ensure_ascii=False,allow_nan=False)+'\n',encoding='utf-8')

def hashes(root):
    return {p.relative_to(root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(root.rglob('*')) if p.is_file()}

def prepare_source(release,rtl,run,hold_trial=False):
    """Select any compatible team's RTL; retain the exact V8 course harness."""
    reference=json.loads((PACKAGE/'automation/v8_reference_hashes.json').read_text())
    for name,digest in reference.items():
        if name.startswith('rtl/'): continue
        path=release/name
        if not path.is_file() or path.is_symlink() or hashlib.sha256(path.read_bytes()).hexdigest()!=digest:
            raise ValueError('Use the clean supplied V8 release; changed/missing file: '+name)
    if not rtl.is_dir() or rtl.is_symlink(): raise ValueError('RTL directory required')
    for path in rtl.rglob('*'):
        if path.is_symlink() or not (path.is_file() or path.is_dir()): raise ValueError('RTL links/special files not accepted')
    if not any(p.suffix in ('.v','.sv') for p in rtl.rglob('*') if p.is_file()): raise ValueError('No RTL sources')
    source=run/'source'; source.mkdir()
    for name in reference:
        if name.startswith('rtl/'): continue
        dest=source/name; dest.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(str(release/name),str(dest))
    shutil.copytree(str(rtl),str(source/'rtl'))
    # Add only RC export, preserving all instructor commands and constraints.
    tcl=source/'synth/topo_ndm.tcl'; original=tcl.read_bytes()
    addition=b'''# TEAM TRANSPORT ADDITION: export existing estimated RC; no constraint changes.
foreach scenario {SS0P95V125C_CMAX SS0P95V125C_CMIN TT1P05V25C_CMAX TT1P05V25C_CMIN FF1P16VN40C_CMAX FF1P16VN40C_CMIN} {
    write_parasitics -scenario $scenario -output outputs/${scenario}.spef
}
puts EE470_TEAM_PARASITICS_COMPLETE
'''
    marker=b'echo PROJECT1_BASELINE_TOPO_COMPLETE\n'
    if original.count(marker)!=1: raise ValueError('Unrecognized V8 synthesis completion marker')
    extended=original.replace(marker,addition+marker)
    if hold_trial:
        hook=PACKAGE/'automation/hold_try02.tcl'
        shutil.copy2(str(hook),str(source/'synth/hold_try02.tcl'))
        anchor=b'extract_rc -estimate\ncurrent_scenario SS0P95V125C_CMAX\n'
        if extended.count(anchor)!=1: raise ValueError('Unrecognized V8 post-mapping RC anchor')
        extended=extended.replace(anchor,b'extract_rc -estimate\nsource hold_try02.tcl\ncurrent_scenario SS0P95V125C_CMAX\n')
    tcl.write_bytes(extended)
    save(run/'synthesis_extension.json',dict(original_sha256=hashlib.sha256(original).hexdigest(),
         extended_sha256=hashlib.sha256(tcl.read_bytes()).hexdigest(),addition=addition.decode(),
         all_original_commands_preserved=True,hold_trial=hold_trial))
    return source

def load_course(source):
    sys.path.insert(0,str(source/'scripts'))
    spec=importlib.util.spec_from_file_location('course_runner',source/'scripts/runner.py')
    module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    return module

def execute(command,cwd,log,seconds=4500,env=None):
    """Direct argv, one foreground process group; terminate only this job on interrupt."""
    command=list(map(str,command)); save(Path(log).with_suffix('.command.json'),command)
    print('JOB='+json.dumps(command),flush=True)
    resource_guard()
    with Path(log).open('x',encoding='utf-8') as stream:
        process=subprocess.Popen(command,cwd=str(cwd),stdout=stream,stderr=subprocess.STDOUT,
                                 start_new_session=True,env=env)
        try:
            deadline=time.monotonic()+seconds
            while process.poll() is None:
                if time.monotonic()>deadline: raise subprocess.TimeoutExpired(command,seconds)
                resource_guard()
                time.sleep(2)
            code=process.returncode
        except BaseException as error:
            if process.poll() is None: os.killpg(process.pid,signal.SIGTERM)
            try: process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid,signal.SIGKILL); process.wait()
            stream.write('\nTEAM_TIMEOUT_OR_INTERRUPT\n')
            if not isinstance(error,subprocess.TimeoutExpired): raise
            code=124
    print('EXIT={} LOG={}'.format(code,log),flush=True)
    return code

def vcs_command(source,folder,sources,defines,plus,sdf=None):
    command=['vcs_queue','-full64','-sverilog','-timescale=1ns/1ps','-top','tb_project',
             '-o',str(folder/'simv')]
    command+=['+incdir+'+str(source/'tb'/p) for p in ('common','cases','student')]
    command+=['+define+'+d for d in defines]
    if sdf:
        command+=['+neg_tchk','-sdf','max:tb_project.adapter.dut:'+str(sdf)]
    return command+list(map(str,sources))+['-R']+plus

def validate_case(folder,case,code,metadata,course):
    log=(folder/'vcs.log').read_text(errors='replace')
    try: raw=json.loads((folder/'raw_result.json').read_text())
    except (OSError,ValueError): raw={}
    summaries=re.findall(r'^SUMMARY case=(\S+) checks=(\d+) errors=(\d+) cycles=(\d+)\s*$',log,re.M)
    passed=(code==0 and raw.get('case_id')==case and type(raw.get('checks')) is int
            and raw['checks']>0 and raw.get('errors')==0 and raw.get('protocol_errors')==0
            and raw.get('normal_completion') is True
            and raw.get('overflow_frames_passed')==metadata['overflow_expected_frames']
            and summaries==[(case,str(raw['checks']),'0',str(raw.get('cycles')))])
    result=dict(case=case,status='PASS' if passed else 'FAIL',exit_code=code,raw=raw,
                vector_sha256=metadata['vector_sha256'],official_grading=False,
                transport='vcs_queue_compile_run_one_slot')
    if passed and case=='F12':
        try: result['npu_timing']=course.npu_timing(raw)
        except (ValueError,KeyError) as error:
            result.update(status='FAIL',timing_error=str(error))
    save(folder/'case_result.json',result)
    return result

def case_inputs(course,source,folder,case,waves):
    profile=course.validate_profile(source/'config/public_profile.json')
    meta=course.generate(folder/'vectors',case,profile,470,None,
                         replay=source/'tb/vectors/F07_seed470.json' if case=='F07' else None)
    plus=['+CASE='+case,'+VECTORS='+str(folder/'vectors/vectors.hex'),'+WAVES='+str(int(waves))]
    if case in ('F01','F12'):
        kind='isa' if case=='F01' else 'integration'
        plus+=['+PROGRAM='+str(folder/'vectors'/(kind+'.hex')),
               '+PROGRAM_WORDS='+str(meta[kind+'_words']),'+TRACE='+str(folder/'vectors/isa_trace.hex'),
               '+START_PC='+str(meta['cpu_start_pc'])]
    return profile,meta,plus

def functional(course,source,run):
    site=json.loads((source/'config/site_manifest.json').read_text())
    macro=Path(site['sram_model'])
    if hashlib.sha256(macro.read_bytes()).hexdigest()!=site['files'][str(macro)]:
        raise ValueError('Actual SRAM model hash differs from course site manifest')
    sources=course.source_files(source/'rtl')+[source/'tb/adapter/dut_adapter.v',source/'tb/common/tb_project.v',macro]
    results=[]
    for case in PUBLIC:
        folder=run/'functional'/case; folder.mkdir(parents=True)
        profile,meta,plus=case_inputs(course,source,folder,case,case=='F12')
        command=vcs_command(source,folder,sources,course.rtl_defines(profile)+course.clock_defines(10000,0)+['USE_MACRO'],plus)
        code=execute(command,folder,folder/'vcs.log')
        result=validate_case(folder,case,code,meta,course); results.append(result)
        save(run/'functional_summary.json',dict(cases=results,complete_case_set=len(results)==12,
             passed=len(results)==12 and all(r['status']=='PASS' for r in results)))
        if result['status']!='PASS': return False
    return True

def read_sta(synth):
    """Never treat missing, rounded negative, or unconstrained reports as closure."""
    result={}
    for scenario in SCENARIOS:
        item={}
        for kind in ('setup','hold'):
            report=synth/'reports'/(scenario+'_'+kind+'.rpt')
            content=report.read_text(errors='replace') if report.is_file() else ''
            found=re.findall(r'^\s*slack\s+\((MET|VIOLATED)\)\s+(-?\d+(?:\.\d+)?)',content,re.M)
            item[kind+'_wns_ns']=min(float(v) for _,v in found) if found else None
            item[kind+'_pass']=bool(found) and all(s=='MET' and float(v)>=0 for s,v in found) and not re.search(r'^Error:',content,re.M)
        checks=synth/'reports'/(scenario+'_check_timing.rpt')
        text=checks.read_text(errors='replace') if checks.is_file() else ''
        # check_timing warning formats differ by installed version. Retain and
        # require review of every warning rather than silently assuming harmless.
        findings=[line for line in text.splitlines() if re.search(r'\b(?:Warning|Error):',line)]
        item['check_timing_findings']=findings
        item['check_timing_clear']=checks.is_file() and bool(text.strip()) and not findings
        item['passed']=item['setup_pass'] and item['hold_pass'] and item['check_timing_clear']
        result[scenario]=item
    return dict(scenarios=result,sta_pass=all(s['passed'] for s in result.values()),
                full_constraint_review_required=True)

def gate(course,source,run):
    synth=source/'synth'; results={}
    clock=dict(line.split('=',1) for line in (synth/'outputs/timing_run.txt').read_text().splitlines())
    if clock.get('clock_model')!='ideal' or (int(clock['clock_period_ps']),int(clock['clock_latency_ps']))!=(10000,0):
        raise ValueError('Gate common comparison requires the mapped 10 ns ideal / zero latency clock')
    site=json.loads((source/'config/site_manifest.json').read_text())
    macro=Path(site['sram_model']); cell=macro.parents[2]/'stdcell_rvt/verilog/saed32nm.v'
    mapped=synth/'outputs/project_mapped.v'
    for name in SCENARIOS:
        folder=run/'gate'/name; folder.mkdir(parents=True)
        profile,meta,plus=case_inputs(course,source,folder,'F12',True)
        sdf=synth/'outputs'/(name+'.sdf')
        lines=[s for s in sdf.read_text().splitlines() if re.match(r'^\s*\(INTERCONNECT clk\s+',s)]
        if not lines or any(float(n)!=0 for line in lines for n in re.findall(r'[+-]?\d+(?:\.\d+)?',line.strip().split(None,3)[3])):
            raise ValueError('Missing/nonideal SDF clock arcs: '+name)
        sources=[cell,macro,mapped,source/'tb/adapter/dut_adapter.v',source/'tb/common/tb_project.v']
        command=vcs_command(source,folder,sources,course.rtl_defines(profile)+course.clock_defines(10000,0)+['EE470_GATE_LEVEL'],plus+['+sdfverbose'],sdf)
        code=execute(command,folder,folder/'vcs.log')
        result=validate_case(folder,'F12',code,meta,course)
        log=(folder/'vcs.log').read_text(errors='replace')
        annotated=bool(re.search(r'Doing SDF annotation.*Done',log,re.I))
        warnings=sorted(set(re.findall(r'\bSDFCOM_[A-Z0-9]+\b',log)))
        timing=bool(re.search(r'Timing violation|\bTimingViolated\b',log,re.I))
        complete=annotated and not warnings and not re.search(r'^Error-\[SDF',log,re.M)
        if not complete or timing: result['status']='FAIL'
        result.update(sdf_annotation_done=annotated,sdf_complete=bool(complete),sdf_warnings=warnings,
                      timing_violation=timing,sdf_sha256=hashlib.sha256(sdf.read_bytes()).hexdigest())
        results[name]=result; save(run/'gate_summary.json',dict(scenarios=results,all_scenarios_qualified=False))
        if result['status']!='PASS': return False
    save(run/'gate_summary.json',dict(scenarios=results,all_scenarios_qualified=True,
         qualified_worst_busy_to_done_ps=max(r['npu_timing']['busy_to_done_ps'] for r in results.values()),
         clock_period_ps=10000,clock_latency_ps=0))
    return True

def power(source,run):
    sys.path.insert(0,str(Path(__file__).resolve().parent))
    from activity import clip_vcd
    if not shutil.which('pt_shell_queue'):
        raise ValueError('Missing pt_shell_queue; power was not measured')
    # Obtain the installed LC location from the same site config as *_sub.
    # Only tool-location output is collected; license variables are not changed.
    lc=subprocess.check_output(['bash','-c',
        'source /opt/eda/env/eda-config.sh; printf "%s" "$LC_HOME"'],universal_newlines=True).strip()
    if not lc or not os.access(str(Path(lc)/'bin/lc_shell'),os.X_OK):
        raise ValueError('Configured LC_HOME/bin/lc_shell unavailable; cannot resolve PT-063')
    gate_results=json.loads((run/'gate_summary.json').read_text())['scenarios']
    results={}
    for name in SCENARIOS:
        folder=run/'power'/name; folder.mkdir(parents=True)
        timing=gate_results[name]['npu_timing']
        clip=folder/'busy_done.vcd'
        window=clip_vcd(run/'gate'/name/'activity.vcd',clip,timing['busy_ps'],timing['done_ps'])
        save(folder/'activity_window.json',window)
        script=folder/'power.tcl'; shutil.copy2(str(run/'automation_snapshot/power.tcl'),str(script))
        env=dict(os.environ,SYNOPSYS_LC_ROOT=lc,EE470_SOURCE=str(source),EE470_SCENARIO=name,EE470_ACTIVITY=str(clip))
        code=execute(['pt_shell_queue','-f',script],folder,folder/'power.log',env=env)
        log=(folder/'power.log').read_text(errors='replace')
        required=('power_total.rpt','power_sram.rpt','activity_coverage.rpt','activity_missing.rpt',
                  'parasitics.rpt','delay_annotation.rpt','check_timing.rpt','units.rpt')
        complete=(code==0 and 'EE470_TEAM_POWER_REPORTS_COMPLETE' in log
                  and not re.search(r'^Error(?:-|:)',log,re.M)
                  and all((folder/p).is_file() and (folder/p).stat().st_size for p in required))
        results[name]=dict(status='REPORTS_NEED_REVIEW' if complete else 'FAIL',exit_code=code,
                           activity_window=window,qualified_power_W=None,
                           reason='Review macro power models, activity/parasitic coverage, warnings and units before qualification')
        save(run/'power_summary.json',dict(scenarios=results,qualified=False))
        if not complete: return False
    return True

def export(run):
    destination=run.parent/(run.name+'_evidence.tar.gz')
    with tarfile.open(str(destination),'w:gz') as tar:
        for p in sorted(run.rglob('*')):
            if not p.is_file() or any(n in ('work','csrc','__pycache__') or n.endswith('.daidir') for n in p.relative_to(run).parts): continue
            if p.name=='simv' or p.suffix in ('.o','.so','.a','.ddc'): continue
            tar.add(str(p),arcname=run.name+'/'+p.relative_to(run).as_posix(),recursive=False)
    print('EVIDENCE_ARCHIVE='+str(destination),flush=True)

def run_pipeline(args):
    global ACTIVE_RUN
    if os.name!='posix': raise ValueError('Server run requires Linux dice; use plan on this PC')
    if not sys.stdin.isatty(): raise ValueError('Run in the connected MobaXterm terminal, not detached/background')
    if os.environ.get('TMUX') or os.environ.get('STY'):
        raise ValueError('Detached tmux/screen license jobs are excluded by the course guidance')
    # Explicitly handle terminal disconnect: stop our child process group before
    # exporting logs. Do not leave the EDA job running after its parent disappears.
    signal.signal(signal.SIGHUP,terminal_interrupt)
    signal.signal(signal.SIGTERM,terminal_interrupt)
    import fcntl
    with (Path.home()/'.ee470_automation.lock').open('a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        for name in ('vcs_queue','dcnxt_topo_queue'):
            if not shutil.which(name): raise ValueError('Missing course launcher: '+name)
        stamp=datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')+'_'+uuid.uuid4().hex[:8]
        run=args.results_root.resolve()/stamp; run.mkdir(parents=True)
        ACTIVE_RUN=run
        source=prepare_source(args.release_root.resolve(),args.rtl_root.resolve(),run,args.hold_trial)
        snapshot=hashes(source); save(run/'source_manifest.json',snapshot)
        shutil.copytree(str(PACKAGE/'automation'),str(run/'automation_snapshot'))
        state=dict(status='RUNNING',functional='NOT_RUN',synthesis='NOT_RUN',sta='NOT_RUN',
                   gate='NOT_RUN',power='NOT_RUN',power_w=None,area=None,official_grade=None,
                   qualified_worst_busy_to_done_ps=None,team_id=args.team_id,requested_through=args.through,
                   hold_trial=args.hold_trial,
                   source_sha256=hashlib.sha256(json.dumps(snapshot,sort_keys=True).encode()).hexdigest())
        save(run/'pipeline_summary.json',state); print('RUN_DIR='+str(run),flush=True)
        try:
            course=load_course(source)
            if not functional(course,source,run):
                state.update(status='FAIL',functional='FAIL'); return 1
            state['functional']='PASS'; save(run/'pipeline_summary.json',state)
            if args.through=='functional': state['status']='FUNCTIONAL_PASS'; return 0
            env=dict(os.environ,EE470_CLK_PERIOD_PS='10000',EE470_CLK_LATENCY_PS='0')
            code=execute(['bash','run.sh'],source/'synth',run/'synthesis.log',env=env)
            log=(run/'synthesis.log').read_text(errors='replace')
            if code or not re.search(r'^PROJECT1_BASELINE_TOPO_COMPLETE$',log,re.M) or not re.search(r'^EE470_FIXED_PORTS_VERIFIED$',log,re.M):
                state.update(status='FAIL',synthesis='FAIL',synthesis_exit_code=code); return 1
            state['synthesis']='PASS'
            sta=read_sta(source/'synth'); save(run/'sta_summary.json',sta)
            if not sta['sta_pass']:
                state.update(status='NEEDS_TIMING_FIX',sta='FAIL'); return 1
            state['sta']='REPORTS_CLEAR'; save(run/'pipeline_summary.json',state)
            if args.through=='synth': state['status']='SYNTH_REPORTS_NEED_REVIEW'; return 0
            if not gate(course,source,run):
                state.update(status='FAIL',gate='FAIL'); return 1
            state['gate']='PASS'
            state['qualified_worst_busy_to_done_ps']=json.loads((run/'gate_summary.json').read_text())['qualified_worst_busy_to_done_ps']
            save(run/'pipeline_summary.json',state)
            if args.through=='gate': state['status']='GATE_PASS_CONSTRAINT_REVIEW_REQUIRED'; return 0
            if not power(source,run):
                state.update(status='FAIL',power='FAIL'); return 1
            state.update(status='REPORTS_NEED_REVIEW',power='REPORTS_NEED_REVIEW')
            return 0
        except BaseException as error:
            state.update(status='INTERRUPTED' if isinstance(error,KeyboardInterrupt) else 'ERROR',reason=str(error)); raise
        finally:
            save(run/'pipeline_summary.json',state); export(run)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=['plan','run'],default='plan',nargs='?')
    parser.add_argument('--release-root',type=Path,default=PACKAGE/'baseline_release',help='Clean instructor V8 baseline_release')
    parser.add_argument('--rtl-root',type=Path,help='Any V8-compatible RTL tree; defaults to release RTL')
    parser.add_argument('--results-root',type=Path,default=PACKAGE/'runs')
    parser.add_argument('--team-id',default='UNSPECIFIED')
    parser.add_argument('--through',choices=['functional','synth','gate','power'],default='synth')
    parser.set_defaults(hold_trial=False)
    if (PACKAGE/'automation/hold_try02.tcl').is_file():
        parser.add_argument('--hold-trial',action='store_true',help='Enable the included mapped data-path buffer experiment')
    args=parser.parse_args()
    if args.rtl_root is None: args.rtl_root=args.release_root/'rtl'
    if args.action=='plan':
        print(json.dumps(dict(stages=['12 sequential vcs_queue -R macro cases','fresh V8 synth/bash run.sh',
             'six-scenario setup/hold/check_timing inspection','six sequential vcs_queue -R SDF F12 cases',
             'six PrimeTime power reports with estimated SPEF and BUSY..DONE VCD',
             'review activity/parasitics/macros and full constraints before PPA qualification'],
             release_root=str(args.release_root.resolve()),rtl_root=str(args.rtl_root.resolve()),
             results_root=str(args.results_root.resolve()),through=args.through,team_id=args.team_id,
             jobs_at_once=1,hold_trial=args.hold_trial,server_execution=False),indent=2))
        return 0
    return run_pipeline(args)

if __name__=='__main__':
    try: sys.exit(main())
    except (OSError,ValueError) as error:
        print('PIPELINE_ERROR: '+str(error),file=sys.stderr); sys.exit(2)
