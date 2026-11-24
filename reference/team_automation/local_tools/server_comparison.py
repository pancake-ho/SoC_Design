"""Build compact AI evidence and a human-readable view from imported V8 runs."""
import hashlib
import html
import json
import re

from sram_metrics import measure


CASES = tuple('F%02d' % i for i in range(1, 13))
SCENARIOS = tuple(p + '_' + rc for p in ('SS0P95V125C', 'TT1P05V25C', 'FF1P16VN40C')
                  for rc in ('CMAX', 'CMIN'))
METRICS = {
    'f01_cpu_cycles': 'F01 CPU 프로그램 사이클',
    'cnn_cycles': 'CNN 사이클',
    'cpu_cycles': 'CPU 전체 사이클',
    'reads': 'CNN DMEM 읽기',
    'writes': 'CNN DMEM 쓰기',
    'request_wait_cycles_total': '수락 대기 합계 (cycles)',
    'request_wait_cycles_max': '수락 대기 최대 (cycles)',
    'response_cycles_total': '응답 지연 합계 (cycles)',
    'response_cycles_min': '응답 지연 최소 (cycles)',
    'response_cycles_max': '응답 지연 최대 (cycles)',
    'worst_setup_ns': '최악 setup slack (ns)',
    'worst_hold_ns': '최악 hold slack (ns)',
    'base_mhz': 'BASE 최고 검증 주파수 (MHz)',
    'integrated_ns': 'INTEGRATED 최악 BUSY→DONE (ns)',
    'total_cell_area': '전체 셀 면적 (보고서 단위)',
    'power_w': '전체 전력 (W)',
}
COMPARISON = ('f01_cpu_cycles', 'cnn_cycles', 'cpu_cycles', 'reads', 'writes', 'request_wait_cycles_total',
              'response_cycles_max', 'worst_setup_ns', 'worst_hold_ns', 'base_mhz',
              'integrated_ns', 'total_cell_area', 'power_w')
HIGHER_IS_BETTER = ('worst_setup_ns', 'worst_hold_ns', 'base_mhz')


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8')) if path.is_file() else {}


def collect(folder):
    state = read_json(folder / 'pipeline_summary.json')
    meta = read_json(folder / 'local_import_check.json')
    manifest = read_json(folder / 'source_manifest.json')
    functional = read_json(folder / 'functional_summary.json')
    cases = {case['case']: case for case in functional.get('cases', [])}
    f12 = cases.get('F12', {})
    raw = f12.get('raw', {}) if f12.get('status') == 'PASS' else {}
    sta = read_json(folder / 'sta_summary.json')
    gate = read_json(folder / 'gate_summary.json')
    timing = f12.get('npu_timing', {})
    values = dict.fromkeys(METRICS)
    f01 = cases.get('F01', {})
    if f01.get('status') == 'PASS':
        values['f01_cpu_cycles'] = f01.get('raw', {}).get('cpu_cycles')
    for key, source in [('cnn_cycles', 'cnn_cycles'), ('cpu_cycles', 'cpu_cycles'), ('reads', 'cnn_reads')]:
        values[key] = raw.get(source)
    sram = read_json(folder / 'local_sram_metrics.json')
    if not sram and raw:
        try:
            sram = {'status': 'measured', 'values': measure(folder / 'functional/F12/activity.vcd', raw)}
        except (OSError, ValueError, KeyError) as error:
            sram = {'status': 'unavailable', 'reason': str(error)}
        (folder / 'local_sram_metrics.json').write_text(json.dumps(sram, indent=2) + '\n', encoding='utf-8')
    values.update({name: value for name, value in sram.get('values', {}).items() if name in METRICS})

    synth = folder / 'source/synth'
    mapped = synth / 'outputs/project_mapped.v'
    area_file = synth / 'reports/area.rpt'
    if state.get('synthesis') == 'PASS' and area_file.is_file():
        matches = re.findall(r'^\s*Total cell area:\s*(\d+(?:\.\d+)?)\s*$',
                             area_file.read_text(errors='replace'), re.M)
        if len(matches) == 1:
            values['total_cell_area'] = float(matches[0])
    gate_time = gate.get('qualified_worst_busy_to_done_ps')
    if (gate.get('all_scenarios_qualified') is True and state.get('gate') == 'PASS'
            and gate.get('clock_period_ps') == 10000 and gate.get('clock_latency_ps') == 0
            and set(gate.get('scenarios', {})) == set(SCENARIOS)
            and isinstance(gate_time, (int, float)) and gate_time > 0):
        values['integrated_ns'] = gate_time / 1000
    rtl_manifest = {name: digest for name, digest in manifest.items() if name.startswith('rtl/')}
    rtl_hash = hashlib.sha256(json.dumps(rtl_manifest, sort_keys=True).encode()).hexdigest() if rtl_manifest else None
    sta_pass = sta.get('sta_pass') is True and set(sta.get('scenarios', {})) == set(SCENARIOS)
    corners = sta.get('scenarios', {})
    worst_corners = {}
    for kind in ('setup', 'hold'):
        slacks = [(entry[kind + '_wns_ns'], name) for name, entry in corners.items()
                  if entry.get(kind + '_wns_ns') is not None]
        if len(slacks) == len(SCENARIOS) and set(corners) == set(SCENARIOS):
            values['worst_' + kind + '_ns'], worst_corners[kind] = min(slacks)
    cohort = None
    vector_hashes = [cases.get(name, {}).get('vector_sha256') for name in CASES]
    harness = {name: digest for name, digest in manifest.items()
               if name.startswith(('config/', 'tb/', 'model/', 'sw/', 'scripts/', 'synth/'))}
    synthesis_extension = read_json(folder / 'synthesis_extension.json')
    if synthesis_extension.get('all_original_commands_preserved') is True:
        original_tcl = synthesis_extension.get('original_sha256')
        if original_tcl:
            harness['synth/topo_ndm.tcl'] = original_tcl
            if synthesis_extension.get('hold_trial') is True:
                harness.pop('synth/hold_try02.tcl', None)
    if (meta.get('source_manifest_matches') is True and functional.get('passed') is True
            and all(cases.get(name, {}).get('status') == 'PASS' for name in CASES)
            and all(vector_hashes) and harness and values['cnn_cycles'] == timing.get('cycles')
            and timing.get('period_ps') == 10000 and timing.get('clock_latency_ps') == 0
            and timing.get('injected_abs_delay_ps') == 0):
        cohort = hashlib.sha256(json.dumps([vector_hashes, harness], sort_keys=True).encode()).hexdigest()[:12]
    return {
        'try': meta.get('try_name') or folder.name, 'run': folder.name, 'change': meta.get('change'),
        'status': state.get('status'), 'source_verified': meta.get('source_manifest_matches'),
        'rtl_sha256': rtl_hash, 'netlist_sha256': hashlib.sha256(mapped.read_bytes()).hexdigest() if mapped.is_file() else None,
        'values': values, 'cohort': cohort, 'sta_pass': sta_pass, 'worst_corners': worst_corners,
        'cases': {name: {key: case.get('raw', {}).get(key) for key in ('checks', 'cycles', 'first_failure')}
                  | {'status': case.get('status')} for name, case in cases.items()},
        'sta': {name: [entry.get('setup_wns_ns'), entry.get('hold_wns_ns'), entry.get('check_timing_clear')]
                for name, entry in sta.get('scenarios', {}).items()},
        'sram_status': sram.get('status'), 'sram_reason': sram.get('reason'),
        'sram_response_count': sram.get('values', {}).get('responses'),
    }


def compare(records):
    current = records[0] if records else None
    previous = next((row for row in records[1:] if row['try'] != current['try']), None) if current else None
    columns = ['try', 'run', 'status', 'cohort', 'sta_pass', *COMPARISON]
    rows = [[*(row[key] for key in columns[:5]), *(row['values'][key] for key in COMPARISON)]
            for row in records]
    leaders = {}
    deltas = {}
    groups = sorted({row['cohort'] for row in records if row['cohort']})
    for group in groups:
        peers = [row for row in records if row['cohort'] == group]
        group_leaders = leaders[group] = {}
        for metric in COMPARISON:
            available = [row for row in peers if row['values'][metric] is not None
                         and (metric not in ('base_mhz', 'integrated_ns', 'total_cell_area', 'power_w')
                              or row['sta_pass'])]
            if not available:
                continue
            ranks = {}
            last_value = None
            rank = 0
            for index, row in enumerate(sorted(available, key=lambda row: row['values'][metric],
                                               reverse=metric in HIGHER_IS_BETTER), 1):
                value = row['values'][metric]
                if value != last_value:
                    rank = index
                    last_value = value
                ranks[row['run']] = rank
            best = next(iter(ranks))
            best_row = next(row for row in available if row['run'] == best)
            group_leaders[metric] = {'of': len(available), 'best_try': best_row['try'],
                                     'best_run': best, 'best': best_row['values'][metric],
                                     'ranks': ranks}
    if current and previous and current['cohort'] and current['cohort'] == previous['cohort']:
        for metric in COMPARISON:
            value, old = current['values'][metric], previous['values'][metric]
            if value is not None and old is not None:
                deltas[metric] = round(value - old, 9)
    rankings = leaders.get(current['cohort'], {}) if current else {}
    per_corner_delta = {}
    if current and previous and current['cohort'] and current['cohort'] == previous['cohort']:
        for name in SCENARIOS:
            now = current['sta'].get(name, [None, None])
            old = previous['sta'].get(name, [None, None])
            if all(value is not None for value in [*now[:2], *old[:2]]):
                per_corner_delta[name] = [round(now[i] - old[i], 9) for i in range(2)]
    return {'current': current, 'previous_run': previous['run'] if previous else None,
            'delta_current_minus_previous': deltas, 'ranks_among_comparable_runs': rankings,
            'sta_delta_setup_hold_ns': per_corner_delta, 'leaders_by_group': leaders,
            'columns': columns, 'runs': rows}


def build(root, out, link):
    folders = {}
    for file in sorted(root.glob('*/*/pipeline_summary.json'), reverse=True):
        folders.setdefault(file.parent.name, file.parent)
    records = [collect(folders[name]) for name in sorted(folders, reverse=True)]
    summary = compare(records)
    summary['metric_labels'] = METRICS
    summary['sram_scope'] = 'F12 RTL, CNN-owned DMEM, sampled on rising edges after BUSY through DONE'
    compact = out / 'server_compare.json'
    compact_summary = dict(summary)
    compact_summary['leaders_by_group'] = {
        group: {metric: {key: value for key, value in result.items() if key != 'ranks'}
                for metric, result in metrics.items()}
        for group, metrics in summary['leaders_by_group'].items()
    }
    compact_summary['ranks_among_comparable_runs'] = {
        metric: {'rank': result['ranks'].get(records[0]['run']), 'of': result['of']}
        for metric, result in summary['ranks_among_comparable_runs'].items()
    }
    compact.write_text(json.dumps(compact_summary, ensure_ascii=False, separators=(',', ':')) + '\n',
                       encoding='utf-8')
    if not records:
        return '<p>가져온 dice 결과가 아직 없습니다.</p>' + link(compact, '비교 JSON')

    def escape(value):
        return '—' if value is None else html.escape(str(value))

    def table(columns, rows):
        head = ''.join('<th>' + escape(column) + '</th>' for column in columns)
        return '<table><tr>' + head + '</tr>' + ''.join(
            '<tr>' + ''.join('<td>' + escape(value) + '</td>' for value in row) + '</tr>' for row in rows
        ) + '</table>'

    current = records[0]
    output = '<p>' + link(compact, 'AI 비교용 JSON') + '</p><h3>실행별 상세</h3>'
    for row in records:
        folder = folders[row['run']]
        title = escape(row['try']) + ' · ' + escape(row['run']) + ' · ' + escape(row['status'])
        output += ('<details open>' if row is current else '<details>') + '<summary>' + title + '</summary>'
        output += '<p>' + escape(row['change'] or '변경 설명 미입력') + '</p>'
        output += '<p>RTL SHA-256 <code>' + escape(row['rtl_sha256']) + '</code><br>'
        output += 'Netlist SHA-256 <code>' + escape(row['netlist_sha256']) + '</code></p>'
        output += table(['지표', '값'], [(METRICS[key], value) for key, value in row['values'].items()])
        if row['sram_reason']:
            output += '<p>SRAM 파형 분석 불가 · ' + escape(row['sram_reason']) + '</p>'
        output += table(['시험', '상태', '검사 수', '테스트 전체 사이클', '첫 실패'],
                        [(case, item.get('status', '미실행'), item.get('checks'), item.get('cycles'),
                          item.get('first_failure'))
                         for case in CASES for item in [row['cases'].get(case, {})]])
        output += table(['시나리오', 'setup (ns)', 'hold (ns)', 'check_timing 경고 없음'],
                        [(name, *row['sta'].get(name, [None, None, None])) for name in SCENARIOS])
        evidence = [folder / name for name in ('pipeline_summary.json', 'functional_summary.json',
                    'sta_summary.json', 'gate_summary.json', 'power_summary.json', 'source_manifest.json',
                    'synthesis.log', 'source/synth/reports/area.rpt', 'source/synth/reports/try02_buffers.tsv',
                    'functional/F12/vcs.log')]
        output += '<p>' + ' · '.join(link(path, path.name) for path in evidence if path.is_file()) + '</p></details>'
    output += '<h3>전체 실행 비교</h3>'
    output += '<p>동일한 입력·프로파일·클록의 기록끼리 비교합니다. 면적·SDF 지연 순위에는 6개 STA 보고서를 통과한 기록을 사용합니다. 값 옆 괄호는 해당 그룹의 순위입니다.</p>'
    table_rows = []
    for row in records:
        leaders = summary['leaders_by_group'].get(row['cohort'], {})
        cells = []
        for key in COMPARISON:
            value = row['values'][key]
            rank = leaders.get(key, {}).get('ranks', {}).get(row['run'])
            cells.append(f'{value} ({rank}위)' if rank else value)
        table_rows.append([row['try'], row['run'], row['status'], row['cohort'], row['sta_pass'], *cells])
    output += table(['try', '실행', '상태', '비교 그룹', 'STA', *(METRICS[key] for key in COMPARISON)],
                    table_rows)
    output += '<h3>최신 실행의 차이와 순위</h3>'
    output += table(['지표', '직전 try와 차이', '현재 순위', '비교 수', '최고값', '최고값 try'],
                    [(METRICS[key], summary['delta_current_minus_previous'].get(key),
                      rank['ranks'].get(current['run']), rank['of'], rank['best'], rank['best_try'])
                     for key, rank in summary['ranks_among_comparable_runs'].items()])
    return output
