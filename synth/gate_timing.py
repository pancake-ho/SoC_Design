"""Measure F12 reset release to valid NPU result using the mapped SoC and DC SDF."""
import argparse
import datetime
import hashlib
import json
import re
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from runner import (clock_defines, execute, f12_commit_args, f12_readback_summary,
                    generate, npu_timing, rtl_defines, save, validate_profile)
from saed_sram_sdf import prepare_sram_timing
from saed_icg_sdf import prepare_icg_sdf

SCENARIOS = tuple(pvt + '_' + rc
                  for pvt in ('SS0P95V125C', 'TT1P05V25C', 'FF1P16VN40C')
                  for rc in ('CMAX', 'CMIN'))
PDK = Path('/opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib')


def sta_slack(report):
    text = report.read_text()
    found = re.findall(r'^\s*slack\s+\((MET|VIOLATED)\)\s+(-?\d+(?:\.\d+)?)', text, re.M)
    if not found or re.search(r'^Error:', text, re.M):
        raise ValueError('Missing valid STA paths: ' + str(report))
    slack = min(float(value) for _, value in found)
    return slack, slack >= 0 and all(status == 'MET' for status, _ in found)


def run_scenario(tool, case_dir, mapped, sdf, period, latency, vectors, waves=False, power=False):
    includes = ['+incdir+' + str(ROOT/'tb'/name) for name in ('common', 'cases', 'student')]
    profile = validate_profile(ROOT/'config/public_profile.json')
    defines = ['+define+' + v for v in rtl_defines(profile) + clock_defines(period,latency) + ['EE470_GATE_LEVEL']]
    sram_source = PDK/'sram/verilog/saed32sram.v'
    stdcell_source = PDK/'stdcell_rvt/verilog/saed32nm.v'
    sram_model, stdcell_model, simulation_sdf, sram_instances, reset_count = prepare_sram_timing(
        sram_source, stdcell_source, sdf, case_dir)
    simulation_sdf, icg_audit = prepare_icg_sdf(simulation_sdf, case_dir)
    models = [stdcell_model, sram_model]
    sram_info = dict(instances=sram_instances,
                     model_source_sha256=hashlib.sha256(sram_source.read_bytes()).hexdigest(),
                     signed_stdcell_reset_checks=reset_count,
                     simulation_sdf_sha256=hashlib.sha256(simulation_sdf.read_bytes()).hexdigest())
    sram_info['model_timing_audit'] = json.loads((case_dir/'model_timing_audit.json').read_text())
    sram_info['icg_timing_audit'] = icg_audit
    save(case_dir/'sram_annotation.json', sram_info)
    simv = case_dir/'simv'
    compile_args = [tool, '-full64', '-sverilog', '-timescale=1ns/1ps',
                    '+neg_tchk', '+overlap+new_solver', '-top', 'tb_project', '-o', str(simv),
                    '-sdf', 'max:tb_project.adapter.dut:' + str(simulation_sdf)]
    compile_args += includes + defines + list(map(str, models)) + [
        str(mapped), str(ROOT/'tb/adapter/dut_adapter.v'), str(ROOT/'tb/common/tb_project.v')]
    save(case_dir/'compile_command.json', compile_args)
    compile_log = case_dir/'compile.log'
    if execute(compile_args, case_dir, compile_log, 360):
        return dict(gate_status='COMPILE_FAILED', functional_status='NOT_RUN', sram_annotation=sram_info)
    meta = json.loads((vectors/'metadata.json').read_text())
    args = [str(simv), '+sdfverbose', '+CASE=F12', '+VECTORS='+str(vectors/'vectors.hex'),
            '+PROGRAM='+str(vectors/'integration.hex'), '+PROGRAM_WORDS='+str(meta['integration_words']),
            '+START_PC='+str(meta['cpu_start_pc']), '+WAVES='+str(int(waves)),
            '+POWER='+str(int(power))] + f12_commit_args(meta)
    save(case_dir/'simulation_command.json', args)
    sim_log = case_dir/'simulation.log'
    exit_code = execute(args, case_dir, sim_log, 600)
    combined = compile_log.read_text(errors='replace') + '\n' + sim_log.read_text(errors='replace')
    annotated = bool(re.search(r'Doing SDF annotation.*Done', combined, re.I))
    sdf_warnings = sorted(set(re.findall(r'\bSDFCOM_[A-Z0-9]+\b', combined)))
    sdf_complete = annotated and not sdf_warnings and not re.search(r'^Error-\[SDF', combined, re.M)
    model_warnings = sorted(set(re.findall(r'Warning-\[(NTCDNC|WSUM)\]', combined)))
    timing_violation = bool(re.search(r'Timing violation|\bTimingViolated\b', combined, re.I))
    result = dict(gate_status='FAIL', functional_status='FAIL', simulator_exit_code=exit_code,
                  timing_violation=timing_violation, sdf_annotation_done=annotated,
                  sdf_warnings=sdf_warnings, sdf_complete=sdf_complete,
                  sram_annotation=sram_info, timing_model_warnings=model_warnings,
                  timing_model_checks_complete=not model_warnings)
    raw_file = case_dir/'raw_result.json'
    if raw_file.is_file():
        raw = json.loads(raw_file.read_text())
        result['first_failure'] = raw.get('first_failure') or None
        result.update(checks=raw.get('checks'), errors=raw.get('errors'),
                      protocol_errors=raw.get('protocol_errors'), commit_readback=f12_readback_summary(raw))
        if raw.get('npu_busy_ps', -1) >= 0 and raw.get('npu_done_ps', -1) > raw['npu_busy_ps']:
            result['npu_timing'] = npu_timing(raw)
        if (exit_code == 0 and raw['case_id'] == 'F12' and raw['normal_completion']
                and raw['checks'] > 0 and raw['errors'] == 0 and raw['protocol_errors'] == 0
                and result['commit_readback']['passed']
                and 'npu_timing' in result
                and raw.get('clock_period_ps')==period and raw.get('clock_latency_ps')==latency):
            result['functional_status'] = 'PASS'
            result['gate_status'] = ('TIMING_VIOLATION' if timing_violation else
                                     'PARTIAL_ANNOTATION' if not sdf_complete else
                                     'MODEL_CHECK_WARNING' if model_warnings else 'PASS')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--synth-dir', type=Path, default=ROOT/'synth')
    parser.add_argument('--scenario', choices=SCENARIOS, help='Run just one scenario for diagnosis')
    parser.add_argument('--waves', action='store_true', help='Save VCD for the selected run; large gate waveforms cost disk/time')
    parser.add_argument('--saif', action='store_true', help='Save DUT activity for the official F12 power flow')
    vectors_input = parser.add_mutually_exclusive_group()
    vectors_input.add_argument('--seed', type=int, help='repeat a practice input generation')
    vectors_input.add_argument('--replay-f12', type=Path, help='reuse an F12 vectors.json snapshot')
    parser.add_argument('--evaluation-sha256', help='instructor-pinned SHA-256 for the evaluation snapshot')
    args = parser.parse_args()
    if args.evaluation_sha256 and (not args.replay_f12 or
                                   not re.fullmatch(r'[a-f0-9]{64}', args.evaluation_sha256)):
        parser.error('--evaluation-sha256 requires --replay-f12 and a lowercase SHA-256')
    tool = shutil.which('vcs_queue')
    if not tool:
        parser.error('Run on dice using the course VCS launcher')
    synth = args.synth_dir.resolve()
    outputs = synth/'outputs'
    clock = dict(line.split('=', 1) for line in (outputs/'timing_run.txt').read_text().splitlines())
    if clock['clock_model'] != 'ideal':
        raise ValueError('Expected the DC ideal clock contract')
    period, latency = int(clock['clock_period_ps']), int(clock['clock_latency_ps'])
    if not 20 <= period <= 1000000 or period % 2 or latency != 0:
        raise ValueError('Invalid public CORE_CLK period or fixed source latency')
    mapped = outputs/'project_mapped.v'
    if not mapped.is_file() or not mapped.stat().st_size:
        raise ValueError('Missing mapped project_top netlist')
    dc_log = (synth/'logs/dc_topo.log').read_text()
    fixed_ports = bool(re.search(r'^EE470_FIXED_PORTS_VERIFIED$', dc_log, re.M))
    dc_completed = bool(re.search(r'^PROJECT1_BASELINE_TOPO_COMPLETE$', dc_log, re.M))
    if not fixed_ports or not dc_completed:
        raise ValueError('The common DC flow and fixed project_top port checks must complete first')
    run = Path(tempfile.mkdtemp(prefix='gate_timing_', dir=str(synth)))
    print('GATE_RUN_DIR='+str(run), flush=True)
    vectors = run/'vectors'
    profile = validate_profile(ROOT/'config/public_profile.json')
    meta = generate(vectors, 'F12', profile, args.seed, replay=args.replay_f12)
    evaluation_vector_verified = bool(args.evaluation_sha256)
    if evaluation_vector_verified and args.evaluation_sha256 != meta['vector_sha256']:
        raise ValueError('F12 evaluation vector does not match the instructor-pinned hash')
    save(vectors/'metadata.json', meta)
    selected = (args.scenario,) if args.scenario else SCENARIOS
    comparison = 'EVALUATION_TEAM_CLOCK' if evaluation_vector_verified else 'PRACTICE'
    summary = dict(clock_model='ideal', clock_period_ps=period, clock_latency_ps=latency,
                   comparison=comparison, seed=meta['seed'], evaluation_vector_verified=evaluation_vector_verified,
                   extra_sdc_sha256=clock.get('extra_sdc_sha256'),
                   mapped_sha256=hashlib.sha256(mapped.read_bytes()).hexdigest(),
                   vector_sha256=meta['vector_sha256'], power_capture=args.saif, scenarios={})
    for name in selected:
        case = run/name
        case.mkdir()
        sdf = outputs/(name+'.sdf')
        if not sdf.is_file() or not sdf.stat().st_size:
            raise ValueError('Missing SDF: '+str(sdf))
        clock_arcs = [line for line in sdf.read_text().splitlines()
                      if re.match(r'^\s*\(INTERCONNECT clk\s+', line)]
        if not clock_arcs or any(float(number) != 0 for line in clock_arcs
                                for number in re.findall(r'[+-]?\d+(?:\.\d+)?', line.strip().split(None,3)[3])):
            raise ValueError('Expected ideal clock arcs in: '+str(sdf))
        setup, setup_pass = sta_slack(synth/'reports'/(name+'_setup.rpt'))
        hold, hold_pass = sta_slack(synth/'reports'/(name+'_hold.rpt'))
        result = dict(setup_wns_ns=setup, hold_wns_ns=hold, sta_pass=setup_pass and hold_pass,
                      sdf_sha256=hashlib.sha256(sdf.read_bytes()).hexdigest(), sdf_column='MAXIMUM')
        result.update(run_scenario(tool, case, mapped, sdf, period, latency, vectors, args.waves, args.saif))
        summary['scenarios'][name] = result
        save(run/'gate_timing_summary.json', summary)
        measurement = result.get('npu_timing', {})
        print('{} {} F12_FUNCTION={} setup={}ns hold={}ns core_clock_intervals={} period_ps={} done_offset_from_core_edge_ps={} EXECUTION_TIME_ps={}'.format(
            name, result['gate_status'], result['functional_status'], setup, hold, measurement.get('execution_clock_intervals'), period,
            measurement.get('done_delay_ps'), measurement.get('execution_time_ps')), flush=True)
    all_pass = len(selected) == len(SCENARIOS) and all(
        s['sta_pass'] and s['gate_status']=='PASS' for s in summary['scenarios'].values())
    summary['all_scenarios_qualified'] = all_pass
    summary['common_performance_eligible'] = all_pass and evaluation_vector_verified
    measured = [s['npu_timing']['execution_time_ps'] for s in summary['scenarios'].values()
                if s['gate_status'] == 'PASS']
    summary['diagnostic_worst_execution_time_ps'] = max(measured) if measured else None
    summary['qualified_worst_execution_time_ps'] = (summary['diagnostic_worst_execution_time_ps']
                                                    if summary['common_performance_eligible'] else None)
    save(run/'gate_timing_summary.json', summary)
    if not args.scenario:
        print('ALL_SCENARIOS_QUALIFIED={} QUALIFIED_WORST_EXECUTION_TIME_PS={}'.format(
            all_pass, summary['qualified_worst_execution_time_ps']), flush=True)
    if args.scenario:
        return 0 if summary['scenarios'][args.scenario]['gate_status']=='PASS' else 1
    return 0 if all_pass else 1


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, KeyError, ValueError) as error:
        print('GATE_TIMING_ERROR: '+str(error), file=sys.stderr)
        sys.exit(2)
