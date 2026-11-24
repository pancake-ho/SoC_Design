"""Internal implementation of the run.sh command contract; Python 3.6+."""
import argparse
import datetime
import hashlib
import hmac
import json
import os
import platform
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import uuid

RELEASE=Path(__file__).resolve().parents[1]
PRIVATE=RELEASE.parent/'instructor_private'
PUBLIC=['F{:02d}'.format(i) for i in range(1,13)]
sys.path.insert(0,str(RELEASE/'model'))
from vectors import F07_OVERFLOW_RATE,generate,rtl_defines,validate_profile


def save(path,value):
    path.write_text(json.dumps(value,indent=2,sort_keys=True,allow_nan=False)+'\n')


def execute(command,cwd,log,seconds):
    with Path(log).open('x') as stream:
        process=subprocess.Popen([str(v) for v in command],cwd=str(cwd),stdout=stream,
            stderr=subprocess.STDOUT,start_new_session=os.name=='posix')
        try:
            return process.wait(timeout=seconds)
        except subprocess.TimeoutExpired:
            if os.name=='posix': os.killpg(process.pid,signal.SIGKILL)
            else: process.kill()
            process.wait()
            stream.write('\nRUNNER_TIMEOUT\n')
            return 124


def inventory():
    versions={}
    for name,command in (('iverilog',['iverilog','-V']),('vcs',['vcs_sub','-ID'])):
        if shutil.which(command[0]):
            try:
                probe=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
                                     universal_newlines=True,timeout=10)
                versions[name]=[line for line in probe.stdout.splitlines() if 'version' in line.lower()][:3]
            except subprocess.SubprocessError:
                versions[name]=['UNAVAILABLE']
    return dict(functional_tools={name:shutil.which(name) for name in
        ('vcs_queue','vcs_sub','iverilog','vvp','verdi_sub','xvfb-run')},
        ppa_tools={name:shutil.which(name) for name in
        ('dc_topo_queue','dcnxt_topo_queue','dc_shell_sub','dcnxt_shell_sub','icc2_shell_sub','pt_shell_sub')},
        os=platform.system()+' '+platform.release(),
        python=sys.version.split()[0],versions=versions,license_environment='not_disclosed',
        default_backend='vcs',sram_macro_required=True,
        libraries=json.loads((RELEASE/'libraries/inventory.json').read_text()))


def source_files(directory):
    directory=Path(directory)
    if not directory.is_dir() or directory.is_symlink(): raise ValueError('RTL directory required')
    result=[]
    for path in sorted(directory.rglob('*')):
        if path.is_symlink() or not(path.is_dir() or path.is_file()): raise ValueError('RTL link/special file rejected')
        if path.is_file() and path.suffix in ('.v','.sv'):
            # Source includes must remain inside the RTL tree. No submitted file list/script is run.
            text=path.read_text()
            for include in re.findall(r'`include\s+"([^"]+)"',text):
                target=path.parent/include
                if Path(include).is_absolute() or '..' in Path(include).parts or not target.is_file():
                    raise ValueError('include outside submitted RTL tree')
            result.append(path)
    if not result: raise ValueError('no RTL sources')
    return result


def run(args):
    if args.impl=='reference' and not (PRIVATE/'reference/rtl/npu.v').is_file():
        raise ValueError('reference is unavailable in the student release')
    profile=validate_profile(args.profile)
    cases=[args.case] if args.case else PUBLIC if args.suite=='public' else ['S01']
    results=Path(args.results_root).absolute() if args.results_root else (
        PRIVATE/'results' if PRIVATE.is_dir() else RELEASE/'results')
    results.mkdir(parents=True,exist_ok=True)
    name=datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')+'_'+(args.case or args.suite)+'_'+uuid.uuid4().hex[:12]
    run_dir=results/name; run_dir.mkdir()
    print('RUN_DIR='+str(run_dir),flush=True)
    save(run_dir/'tools.json',inventory()); save(run_dir/'profile.json',profile)
    build=run_dir/'compile'; build.mkdir(); frozen=build/'rtl'; frozen.mkdir()
    rtl=Path(args.rtl_root) if args.rtl_root else RELEASE/'rtl'
    for path in source_files(rtl):
        relative=path.relative_to(rtl); target=frozen/relative
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(path.read_bytes())
    if args.impl=='reference':
        (frozen/'npu.v').write_bytes((PRIVATE/'reference/rtl/npu.v').read_bytes())
    shutil.copytree(str(RELEASE/'tb'),str(build/'tb'))
    if args.official or args.suite=='public' and args.case!='S01':
        # Public grading remains independent of optional student cases.
        (build/'tb/student/student_cases.vh').write_text('task run_student_cases; begin end endtask\n')
    manifest={str(p.relative_to(build)):hashlib.sha256(p.read_bytes()).hexdigest()
              for p in sorted(build.rglob('*')) if p.is_file()}
    source_hash=hashlib.sha256(json.dumps(manifest,sort_keys=True).encode()).hexdigest()
    save(run_dir/'source_manifest.json',manifest)
    save(run_dir/'run_manifest.json',dict(schema='ee470.run.v1',team_id=args.team,impl=args.impl,
        official=bool(args.official),cases=cases,source_sha256=source_hash,backend=args.backend,
        macro=bool(args.macro),target='INTEGRATED',status='RUNNING',
        xq_layout=profile['xq_layout'],wq_layout=profile['wq_layout']))
    sources=source_files(frozen)+[build/'tb/adapter/dut_adapter.v',build/'tb/common/tb_project.v']
    includes=[build/'tb'/part for part in ('common','cases','student')]
    define=rtl_defines(profile) + clock_defines(args.clock_period_ps, args.clock_latency_ps,
                                                args.abs_delay_ps)
    if args.macro:
        site=RELEASE/'config/site_manifest.json'
        if not site.is_file(): site=PRIVATE/'site/manifest.json'
        if not site.is_file(): raise ValueError('macro integration needs the supplied site manifest')
        metadata=json.loads(site.read_text()); macro=Path(metadata['sram_model'])
        if hashlib.sha256(macro.read_bytes()).hexdigest()!=metadata['files'][str(macro)]:
            raise ValueError('PDK model changed')
        sources.append(macro); define.append('USE_MACRO')
        save(run_dir/'site_manifest.json',metadata)
    if args.backend=='vcs':
        tool=shutil.which('vcs_queue') or shutil.which('vcs')
        if not tool: raise ValueError('VCS unavailable; choose --backend iverilog for a separately labelled local run')
        command=[tool,'-full64','-sverilog','-timescale=1ns/1ps','-top','tb_project','-o',str(build/'simv')]
        command+=['+incdir+'+str(p) for p in includes]+['+define+'+s for s in define]+[str(p) for p in sources]
    else:
        tool=shutil.which('iverilog')
        if not tool: raise ValueError('Icarus unavailable')
        command=[tool,'-g2012','-s','tb_project','-o',str(build/'simv')]
        command+=['-I'+str(p) for p in includes]+['-D'+s for s in define]+[str(p) for p in sources]
    save(build/'command.json',command)
    compile_code=execute(command,build,build/'compile.log',args.timeout)
    license_denied=bool(compile_code and re.search(
        r'Failed to obtain license|not on INCLUDE list|Design Compiler is not enabled|Unable to checkout',
        (build/'compile.log').read_text(errors='replace'),re.I))
    passed=[]
    for case in cases:
        folder=run_dir/case; folder.mkdir()
        meta=generate(folder/'vectors',case,profile,args.seed,
                      RELEASE/'tb/student/example.json' if case=='S01' else None,
                      overflow_rate=F07_OVERFLOW_RATE if args.overflow_rate is None else args.overflow_rate,
                      replay=args.replay_f07 if case=='F07' else None)
        plus=['+CASE='+case,'+VECTORS='+str(folder/'vectors/vectors.hex'),'+WAVES='+str(int(args.waves or args.verdi))]
        if case in ('F01','F12'):
            kind='isa' if case=='F01' else 'integration'
            plus+=['+PROGRAM='+str(folder/('vectors/'+kind+'.hex')),'+PROGRAM_WORDS='+str(meta[kind+'_words']),
                   '+TRACE='+str(folder/'vectors/isa_trace.hex'),'+START_PC='+str(meta['cpu_start_pc'])]
        simulation=[str(build/'simv')]+plus if args.backend=='vcs' else ['vvp',str(build/'simv')]+plus
        save(folder/'command.json',simulation)
        code=execute(simulation,folder,folder/'simulation.log',args.timeout) if compile_code==0 else compile_code
        raw={}; failure=None; status='FAIL'
        try:
            raw=json.loads((folder/'raw_result.json').read_text())
            summary=re.findall(r'^SUMMARY case=(\S+) checks=(\d+) errors=(\d+) cycles=(\d+)$',
                               (folder/'simulation.log').read_text(),re.M)
            if (code==0 and raw.get('case_id')==case and type(raw.get('checks')) is int and raw['checks']>0
                    and raw.get('errors')==0 and raw.get('protocol_errors')==0 and raw.get('normal_completion') is True
                    and raw.get('overflow_frames_passed')==meta['overflow_expected_frames']
                    and summary==[(case,str(raw['checks']),'0',str(raw['cycles']))]):
                status='PASS'
            else: failure=raw.get('first_failure') or 'checker/summary/exit validation failed'
        except (OSError,ValueError,KeyError):
            failure='compile failure' if compile_code else 'missing or invalid official raw result/SUMMARY'
        if code==124: status='TIMEOUT'; failure='shell or compile timeout'
        elif license_denied: status='UNAVAILABLE'; failure='tool license denied; see compile/compile.log'
        result=dict(schema='ee470.case.v1',team_id=args.team,case_id=case,test_status=status,
            checks=raw.get('checks',0),errors=raw.get('errors',1),seed=meta['seed'],cycles=raw.get('cycles'),
            exit_code=code,source_sha256=source_hash,vector_sha256=meta['vector_sha256'],
            first_failure=failure,backend=args.backend,macro=bool(args.macro),
            cnn_cycles=raw.get('cnn_cycles'),cnn_reads=raw.get('cnn_reads'),cnn_writes=raw.get('cnn_writes'),
            workload=dict(input=[16,16,1],filter=[4,3,3],output=[4,14,14],macs=7056),
            cpu_cycles=raw.get('cpu_cycles'),cpu_npu_starts=raw.get('cpu_npu_starts'),
            overflow_expected_frames=meta['overflow_expected_frames'],
            overflow_frames_passed=raw.get('overflow_frames_passed'),
            xq_layout=profile['xq_layout'],wq_layout=profile['wq_layout'],
            raw_result='raw_result.json',simulation_log='simulation.log')
        if case=='F12' and status=='PASS':
            result['npu_timing']=npu_timing(raw)
        if case=='F07':
            result.update(overflow_rate_percent=meta['overflow_rate_percent'],
                          overflow_frame_indices=meta['overflow_frame_indices'],
                          overflow_by_mode=meta['overflow_by_mode'],replayed=meta['replayed'])
            print('F07 seed={} overflow={}/{} vector_sha256={}'.format(
                meta['seed'],result['overflow_frames_passed'],result['overflow_expected_frames'],
                meta['vector_sha256']),flush=True)
        save(folder/'case_result.json',result); passed.append(status=='PASS')
        print('{} {} checks={} first_failure={}'.format(case,status,result['checks'],failure),flush=True)
    manifest=json.loads((run_dir/'run_manifest.json').read_text())
    manifest.update(status='PASS' if all(passed) else 'UNAVAILABLE' if license_denied else 'FAIL',complete_case_set=set(cases)==set(PUBLIC),
                    functional_reference_status='PASS' if args.impl=='reference' and set(cases)==set(PUBLIC) and all(passed) else 'NOT_RUN',
                    macro_integration_status='PASS' if args.macro and set(cases)==set(PUBLIC) and all(passed) else 'NOT_RUN',
                    ppa_status='NOT_RUN')
    save(run_dir/'run_manifest.json',manifest)
    if args.official:
        key_path=PRIVATE/'site/grading_key.bin'
        try:
            fd=os.open(str(key_path),os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
        except FileExistsError:
            pass
        else:
            with os.fdopen(fd,'wb') as stream: stream.write(os.urandom(32))
        attested={str(p.relative_to(run_dir)):hashlib.sha256(p.read_bytes()).hexdigest()
                  for p in sorted(run_dir.rglob('*')) if p.is_file() and 'compile' not in p.relative_to(run_dir).parts}
        attested['compile/compile.log']=hashlib.sha256((build/'compile.log').read_bytes()).hexdigest()
        message=json.dumps(attested,sort_keys=True,separators=(',',':')).encode()
        save(run_dir/'attestation.json',dict(files=attested,
             hmac_sha256=hmac.new(key_path.read_bytes(),message,hashlib.sha256).hexdigest()))
    if args.verdi and all(passed):
        wave=run_dir/cases[-1]/'activity.vcd'
        if not wave.is_file() or not wave.stat().st_size: raise ValueError('no fresh wave generated')
        tool=shutil.which('verdi_sub') or shutil.which('verdi')
        if not tool: raise ValueError('Verdi unavailable')
        # This site's Verdi help explicitly lists .vcd under -ssf; no FSDB PLI is assumed.
        subprocess.run([tool,'-ssf',str(wave)],cwd=str(wave.parent),check=True)
    return 0 if all(passed) else 1


def clock_defines(period, latency, injected=0):
    return ['EE470_CLK_PERIOD_PS='+str(period), 'EE470_CLK_LATENCY_PS='+str(latency),
            'EE470_ABS_DELAY_PS='+str(injected)]


def npu_timing(raw):
    period = raw['clock_period_ps']
    busy_delay = raw['npu_busy_ps'] - raw['npu_busy_edge_ps']
    done_delay = raw['npu_done_ps'] - raw['npu_done_edge_ps']
    cycles = raw['npu_done_cycle'] - raw['npu_busy_cycle']
    elapsed = raw['npu_done_ps'] - raw['npu_busy_ps']
    if cycles <= 0 or not (0 <= busy_delay < period and 0 <= done_delay < period):
        raise ValueError("invalid NPU pin offsets")
    if elapsed != cycles * period + done_delay - busy_delay:
        raise ValueError('inconsistent NPU checkpoint timing')
    return dict(cycles=cycles, period_ps=period, clock_latency_ps=raw['clock_latency_ps'],
                injected_abs_delay_ps=raw.get('injected_abs_delay_ps',0),
                busy_ps=raw['npu_busy_ps'], done_ps=raw['npu_done_ps'],
                busy_edge_ps=raw['npu_busy_edge_ps'], done_edge_ps=raw['npu_done_edge_ps'],
                busy_delay_ps=busy_delay, done_delay_ps=done_delay,
                absolute_delay_ps=done_delay-busy_delay, cycle_component_ps=cycles*period,
                busy_to_done_ps=elapsed, busy_edge_to_done_ps=cycles*period+done_delay)


def main():
    parser=argparse.ArgumentParser(); parser.add_argument('--preflight',action='store_true')
    parser.add_argument('--suite',choices=['public','student'],default='public')
    parser.add_argument('--case',choices=PUBLIC+['S01']); parser.add_argument('--impl',choices=['student','reference'],default='student')
    parser.add_argument('--backend',choices=['vcs','iverilog'],default='vcs'); parser.add_argument('--macro',action='store_true')
    parser.add_argument('--functional-array',action='store_true',help='local behavioral SRAM smoke test')
    parser.add_argument('--profile',type=Path,default=RELEASE/'config/public_profile.json')
    parser.add_argument('--waves',action='store_true'); parser.add_argument('--verdi',action='store_true')
    parser.add_argument('--clock-period-ps',type=int,default=10000)
    parser.add_argument('--clock-latency-ps',type=int,default=0)
    parser.add_argument('--abs-delay-ps',type=int,default=0,help='F12 RTL-only DONE checkpoint demo delay')
    parser.add_argument('--seed',type=int,default=470); parser.add_argument('--timeout',type=int,default=180)
    f07=parser.add_mutually_exclusive_group()
    f07.add_argument('--overflow-rate',type=int,choices=range(101),metavar='0..100',
                     help='probability percentage for F07 slots beyond four mandatory overflow frames')
    f07.add_argument('--replay-f07',type=Path,help='reuse F07 vectors.json from a previous run')
    parser.add_argument('--rtl-root',type=Path); parser.add_argument('--results-root',type=Path)
    parser.add_argument('--team',default='REFERENCE'); parser.add_argument('--official',action='store_true')
    args=parser.parse_args()
    if not 20 <= args.clock_period_ps <= 1000000 or args.clock_period_ps % 2:
        parser.error('clock period must be an even integer in ps from 20 to 1000000')
    if not 0 <= args.clock_latency_ps <= 1000000:
        parser.error('clock latency must be an integer in ps from 0 to 1000000')
    if not 0 <= args.abs_delay_ps < args.clock_period_ps or args.abs_delay_ps and args.case != 'F12':
        parser.error('synthetic delay requires --case F12 and must be smaller than the period')
    if args.official and (args.abs_delay_ps or args.clock_period_ps != 10000 or args.clock_latency_ps != 0
                          or args.seed != 470 or args.overflow_rate is not None or args.replay_f07
                          or args.profile.resolve() != (RELEASE/'config/public_profile.json').resolve()):
        parser.error('official runs require common 10 ns clock, zero latency, seed 470 and public profile')
    if (args.overflow_rate is not None or args.replay_f07) and not (
            args.case=='F07' or args.case is None and args.suite=='public'):
        parser.error('F07 vector options require --case F07 or the public suite')
    toolchain=json.loads((RELEASE/'config/toolchain.json').read_text())
    if args.functional_array and (args.macro or args.official):
        parser.error('--functional-array is local only and cannot be combined with --macro or --official')
    args.macro=not args.functional_array and (args.macro or toolchain['require_sram_macro'])
    if args.preflight:
        validate_profile(args.profile); print(json.dumps(inventory(),indent=2)); return 0
    if args.official and (not PRIVATE.is_dir() or args.case or args.suite!='public' or args.impl!='student'):
        raise ValueError('official grading requires the instructor public suite and submitted RTL')
    return run(args)


if __name__=='__main__':
    try: sys.exit(main())
    except (OSError,ValueError,subprocess.SubprocessError) as error:
        print('RUNNER_ERROR: '+str(error),file=sys.stderr); sys.exit(2)
