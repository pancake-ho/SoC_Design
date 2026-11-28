"""Convert checked F12 gate activity to SAIF and report power for all six corners."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile
from fractions import Fraction

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts'))
from runner import execute, save
from gate_timing import SCENARIOS, PDK
from saif_audit import audit as audit_saif


def sha(path):
    digest=hashlib.sha256()
    with path.open('rb') as stream:
        while True:
            block=stream.read(1024*1024)
            if not block:
                break
            digest.update(block)
    return digest.hexdigest()


def tcl_path(path):
    text = str(path.resolve())
    if any(c in text for c in '{}\\\r\n'):
        raise ValueError('Unsupported path for Tcl: '+text)
    return '{'+text+'}'


def tick_ps(number, unit):
    return Fraction(number)*dict(fs=Fraction(1,1000),ps=Fraction(1),ns=Fraction(1000))[unit]


def power_values(report):
    """Read the final non-hierarchical Total row, converting every column to watts."""
    units = dict(W=1., mW=1e-3, uW=1e-6, nW=1e-9, pW=1e-12)
    number = r'([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)'
    column = number+r'\s*(mW|uW|nW|pW|W)'
    rows = re.findall(r'^\s*Total\s+'+r'\s+'.join([column]*4)+r'\s*$', report, re.M)
    if len(rows) != 1:
        raise ValueError('Expected one fully unit-labelled Total row in report_power')
    row = rows[0]
    values = [float(row[i])*units[row[i+1]] for i in (0,2,4,6)]
    if any(not math.isfinite(v) for v in values) or any(v<0 for v in values[1:]) or values[0]+values[1]<0:
        raise ValueError('Invalid power result')
    return dict(internal_W=values[0], switching_W=values[1], leakage_W=values[2], total_W=values[3],
                dynamic_W=values[0]+values[1])


def annotation_counts(report):
    counts = {}
    for kind in ('ports','nets','pins'):
        match = re.search(r'List of Non-annotated '+kind+r'\s*:\s*\n(.*?)(?=\n\s*List of Non-annotated|\n-{5,})',report,re.S)
        if not match:
            raise ValueError('Missing SAIF coverage details for '+kind)
        names = [line.strip() for line in match[1].splitlines() if line.strip()]
        counts[kind] = 0 if names==['0 '+kind] else len(names)
    return counts


def memory_model_observation(report):
    """Retain the library's memory-group values, including negative internal power."""
    factors = dict(W=1., mW=1e-3, uW=1e-6, nW=1e-9, pW=1e-12)
    number = r'([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)'
    row = re.search(r'^memory\s+'+r'\s+'.join([number]*4),report,re.M)
    dynamic = re.search(r'Dynamic Power Units\s*=\s*'+number+r'\s*(mW|uW|nW|pW|W)',report)
    leakage = re.search(r'Leakage Power Units\s*=\s*'+number+r'\s*(mW|uW|nW|pW|W)',report)
    if not row or not dynamic or not leakage:
        raise ValueError('Missing memory-group power model evidence')
    dyn_unit = float(dynamic[1])*factors[dynamic[2]]
    leak_unit = float(leakage[1])*factors[leakage[2]]
    values = dict(internal_W=float(row[1])*dyn_unit, switching_W=float(row[2])*dyn_unit,
                  leakage_W=float(row[3])*leak_unit, total_W=float(row[4])*dyn_unit)
    if any(not math.isfinite(v) for v in values.values()):
        raise ValueError('Non-finite memory-group power')
    values['negative_internal_model_value'] = values['internal_W']<0
    values['zero_leakage_model_value'] = values['leakage_W']==0
    values['raw_values_preserved'] = True
    return values


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--gate-run', required=True, type=Path,
                        help='GATE_RUN_DIR from gate_timing.py --saif')
    args = parser.parse_args()
    gate = args.gate_run.resolve()
    summary = json.loads((gate/'gate_timing_summary.json').read_text())
    synth = gate.parent
    outputs = synth/'outputs'
    mapped = outputs/'project_mapped.v'
    ddc = outputs/'project_mapped.ddc'
    if sha(mapped) != summary['mapped_sha256'] or not ddc.is_file():
        raise ValueError('Mapped netlist changed or its synthesis DDC is missing')
    if not summary.get('power_capture'):
        raise ValueError('Run gate_timing.py --saif first; ordinary waveforms may include TB activity')
    if set(summary['scenarios']) != set(SCENARIOS):
        raise ValueError('Six matching SDF gate scenarios are required')
    converter = shutil.which('vcd2saif')
    if not converter:
        syn = Path(os.environ.get('SYNOPSYS', '/opt/eda/synopsys/products/syn/V-2023.12-SP5'))
        candidate = syn/'bin/vcd2saif'
        if candidate.is_file():
            converter = str(candidate)
    dc = shutil.which('dcnxt_topo_queue')
    if not converter or not dc:
        raise ValueError('Use the course vcd2saif and dcnxt_topo_queue environment')
    run = Path(tempfile.mkdtemp(prefix='power_saif_', dir=str(synth)))
    print('POWER_RUN_DIR='+str(run), flush=True)
    provenance = dict(mapped_sha256=sha(mapped), ddc_sha256=sha(ddc),
                      vector_sha256=summary['vector_sha256'], case='F12', seed=470,
                      scope='tb_project/adapter/dut', window='first NPU BUSY rise through first DONE rise',
                      clock_period_ps=summary['clock_period_ps'], clock_latency_ps=summary['clock_latency_ps'],
                      model='DC Topographical pre-CTS pre-route estimate; ideal clock',
                      activity_mapping='gate_level_exact_names_without_RTL_name_mapping',
                      library_power_model_limitations=[
                          'SAED32 educational SRAM models can report negative internal power and zero leakage.',
                          'Preserve vendor values and include every SRAM. Do not clamp, invent leakage or remove macros.',
                          'This comparison is a model-based pre-route estimate, not characterized SRAM signoff power.'],
                      scenarios={})
    lines = ['file mkdir work reports', 'source '+tcl_path(ROOT/'synth/library_setup.tcl'),
             'set power_target_library $target_library', 'set power_link_library $link_library',
             'read_ddc '+tcl_path(ddc), 'current_design project_top',
             'set_app_var target_library $power_target_library', 'set_app_var link_library $power_link_library']
    # Restore the same corner bindings using the installed library paths. No SDC is relaxed.
    corner_names = dict(SS0P95V125C='ss0p95v125c',TT1P05V25C='tt1p05v25c',FF1P16VN40C='ff1p16vn40c')
    for name in SCENARIOS:
        pvt,rc=name.rsplit('_',1)
        corner=corner_names[pvt]
        rc_file=PDK.parent/'tech/star_rcxt'/('saed32nm_1p9m_'+('Cmax' if rc=='CMAX' else 'Cmin')+'.tluplus')
        rc_map=PDK.parent/'tech/star_rcxt/saed32nm_tf_itf_tluplus.map'
        lines += ['current_scenario '+name,
                  'set_link_library_subset -top [list '+tcl_path(PDK/'stdcell_rvt/db_nldm'/('saed32rvt_'+corner+'.db'))+' '+tcl_path(PDK/'sram/db_nldm'/('saed32sram_'+corner+'.db'))+']',
                  'set_tlu_plus_files -max_tluplus '+tcl_path(rc_file)+' -min_tluplus '+tcl_path(rc_file)+' -tech2itf_map '+tcl_path(rc_map)]
    lines += ['if {![link]} {error "Power DDC link failed"}',
             'report_reference -hierarchy > reports/references.rpt',
             'report_units > reports/units.rpt',
             'source '+tcl_path(ROOT/'synth/saif_audit.tcl'),
             'ee470_capture_connectivity reports/pin_connectivity.tsv']
    for name in SCENARIOS:
        result = summary['scenarios'][name]
        if result['gate_status'] != 'PASS' or not result.get('sdf_complete'):
            raise ValueError('Gate function/model/timing checks must pass first: '+name)
        if sha(outputs/(name+'.sdf')) != result['sdf_sha256']:
            raise ValueError('SDF changed after gate run: '+name)
        case = gate/name
        raw = json.loads((case/'raw_result.json').read_text())
        begin, end = raw['npu_busy_ps'], raw['npu_done_ps']
        if not 0 <= begin < end or raw['errors'] or raw['protocol_errors']:
            raise ValueError('Invalid checked F12 measurement window: '+name)
        vcd = case/'activity.vcd'
        with vcd.open() as stream:
            header = stream.read(8192)
        scale = re.search(r'\$timescale\s+(\d+)\s*(fs|ps|ns)\s+\$end', header)
        if not scale:
            raise ValueError('Missing supported VCD timescale')
        tick = tick_ps(scale[1],scale[2])
        begin_tick,end_tick = Fraction(begin)/tick,Fraction(end)/tick
        if begin_tick.denominator!=1 or end_tick.denominator!=1:
            raise ValueError('Checkpoint cannot be represented exactly on the VCD grid')
        saif = run/(name+'.saif')
        cmd = [converter, '-input', str(vcd), '-output', str(saif), '-time', str(int(begin_tick)), str(int(end_tick))]
        save(run/(name+'_convert_command.json'),cmd)
        if execute(cmd, run, run/(name+'_convert.log'),300):
            raise ValueError('VCD to SAIF conversion failed: '+name)
        text = saif.read_text()
        duration = re.search(r'\(DURATION\s+(\d+)\)', text)
        saif_scale = re.search(r'\(TIMESCALE\s+(\d+)\s+(fs|ps|ns)\)',text)
        if not duration or not saif_scale or int(duration[1])*tick_ps(saif_scale[1],saif_scale[2]) != end-begin:
            raise ValueError('SAIF duration does not match BUSY to DONE: '+name)
        if not re.search(r'\(TC\s+[1-9]\d*\)',text):
            raise ValueError('SAIF has no transitions: '+name)
        provenance['scenarios'][name] = dict(begin_ps=begin,end_ps=end,duration_ps=end-begin,
            vcd_tick_ps=float(tick),saif_tick_ps=float(tick_ps(saif_scale[1],saif_scale[2])),
            saif_sha256=sha(saif),vcd_sha256=sha(vcd),sdf_sha256=result['sdf_sha256'],
            sta_pass=result['sta_pass'],gate_status=result['gate_status'])
        lines += ['current_scenario '+name, 'reset_switching_activity',
                  'if {![read_saif -input '+tcl_path(saif)+' -instance_name tb_project/adapter/dut]} {error "No gate activity annotated"}',
                  'propagate_switching_activity',
                  'report_saif -hierarchy -missing > reports/'+name+'_annotation.rpt',
                  'ee470_capture_activity reports/'+name,
                  'report_power -analysis_effort high -hierarchy > reports/'+name+'_hierarchy.rpt',
                  'report_power -analysis_effort high > reports/'+name+'_power.rpt',
                  'puts "EE470_SAIF_POWER_READY '+name+'"']
    lines += ['puts "EE470_SAIF_POWER_COMPLETE"']
    (run/'power.tcl').write_text('\n'.join(lines)+'\n')
    # Do not leave the tool interactive after a Tcl failure.
    (run/'entry.tcl').write_text('if {[catch {source power.tcl} message]} {puts stderr $message; exit 1}\nquit\n')
    save(run/'power_summary.json',provenance)
    status = execute([dc,'-f','entry.tcl'],run,run/'dc_power.log',1200)
    log = (run/'dc_power.log').read_text(errors='replace')
    if status or re.search(r'^Error:',log,re.M) or 'EE470_SAIF_POWER_COMPLETE' not in log:
        raise ValueError('DC SAIF power analysis failed; inspect '+str(run/'dc_power.log'))
    units = (run/'reports/units.rpt').read_text()
    unit_match = re.search(r'Time_unit\s*:\s*([0-9.eE+-]+)\s+Second',units)
    if not unit_match or not math.isfinite(float(unit_match[1])) or float(unit_match[1])<=0:
        raise ValueError('Missing positive library time unit')
    time_unit_ns = float(unit_match[1])*1e9
    provenance['library_time_unit_ns'] = time_unit_ns
    for name in SCENARIOS:
        report = (run/'reports'/(name+'_power.rpt')).read_text()
        annotation = (run/'reports'/(name+'_annotation.rpt')).read_text()
        if not annotation.strip() or 'No switching activity' in annotation:
            raise ValueError('Missing SAIF annotation evidence: '+name)
        missing = annotation_counts(annotation)
        provenance['scenarios'][name]['non_annotated'] = missing
        activity = audit_saif(run/(name+'.saif'),run/'reports'/(name+'_net_activity.rpt'),
            run/'reports'/(name+'_pin_activity.rpt'),run/'reports/pin_connectivity.tsv',
            run/'reports'/(name+'_annotation.rpt'),time_unit_ns,
            port_report=run/'reports'/(name+'_port_activity.rpt'))
        save(run/'reports'/(name+'_activity_audit.json'),activity)
        provenance['scenarios'][name]['activity_coverage_complete'] = activity['activity_coverage_complete']
        provenance['scenarios'][name]['activity_audit'] = {
            key:value for key,value in activity.items() if not isinstance(value,list)}
        provenance['scenarios'][name]['disconnected_output_pin_count'] = len(activity['disconnected_output_pins'])
        provenance['scenarios'][name]['unresolved_non_annotated_pin_count'] = len(activity['unresolved_non_annotated_pins'])
        provenance['scenarios'][name].update(power_values(report))
        provenance['scenarios'][name]['memory_model_observation'] = memory_model_observation(report)
        print(name+' total_W='+str(provenance['scenarios'][name]['total_W'])+
              ' bitwise_mismatches='+str(activity['bitwise_mismatch_count'])+
              ' activity_coverage_complete='+str(activity['activity_coverage_complete']),flush=True)
        provenance['scenarios'][name]['energy_J'] = provenance['scenarios'][name]['total_W']*provenance['scenarios'][name]['duration_ps']*1e-12
    provenance['measurement_complete'] = True
    provenance['all_timing_qualified'] = summary['all_scenarios_qualified']
    provenance['activity_coverage_complete'] = all(s['activity_coverage_complete'] for s in provenance['scenarios'].values())
    provenance['common_power_eligible'] = (summary['common_performance_eligible'] and provenance['activity_coverage_complete']
        and summary['clock_period_ps']==10000 and summary['clock_latency_ps']==0)
    provenance['diagnostic_worst_total_W'] = max(s['total_W'] for s in provenance['scenarios'].values())
    provenance['qualified_worst_total_W'] = provenance['diagnostic_worst_total_W'] if provenance['common_power_eligible'] else None
    save(run/'power_summary.json',provenance)
    print('SAIF_POWER_MEASUREMENT_COMPLETE common_power_eligible='+str(provenance['common_power_eligible']),flush=True)
    return 0


if __name__=='__main__':
    try:
        sys.exit(main())
    except (OSError,KeyError,ValueError) as error:
        print('SAIF_POWER_ERROR: '+str(error),file=sys.stderr)
        sys.exit(2)
