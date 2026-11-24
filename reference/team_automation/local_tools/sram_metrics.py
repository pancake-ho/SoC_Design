"""Measure CNN-owned DMEM handshakes from the unchanged V8 F12 RTL waveform."""
from fractions import Fraction
import re


SIGNALS = ('clk', 'rst_n', 'observe_npu_owner', 'observe_valid',
           'observe_ready', 'observe_accept', 'observe_write', 'observe_response')
PS_PER_UNIT = {'s': 10**12, 'ms': 10**9, 'us': 10**6, 'ns': 1000,
               'ps': 1, 'fs': Fraction(1, 1000)}


def rising_edges(stream):
    header = []
    for line in stream:
        header.append(line)
        if '$enddefinitions' in line:
            break
    scope = []
    codes = {}
    tick_ps = None
    for command, body in re.findall(r'\$(\w+)\s+(.*?)\$end', ''.join(header), re.S):
        fields = body.split()
        if command == 'scope':
            scope.append(fields[1])
        elif command == 'upscope':
            scope.pop()
        elif command == 'timescale':
            value = re.fullmatch(r'(\d+)(s|ms|us|ns|ps|fs)', ''.join(fields))
            if value:
                tick_ps = int(value[1]) * PS_PER_UNIT[value[2]]
        elif command == 'var' and scope == ['tb_project'] and fields[3] in SIGNALS:
            if fields[1] == '1':
                codes[fields[3]] = fields[2]
    if not tick_ps or set(codes) != set(SIGNALS):
        raise ValueError('F12 VCD is missing its timescale or public DMEM probes')

    values = {}
    updates = {}
    watched = set(codes.values())
    clock = codes['clk']
    time = None
    skip_directive = False

    for line in stream:
        tokens = iter(line.split())
        for token in tokens:
            if token == '$end':
                skip_directive = False
                continue
            if skip_directive:
                continue
            if token.startswith('$'):
                skip_directive = token not in ('$dumpvars', '$dumpall', '$dumpon', '$dumpoff')
            elif token.startswith('#'):
                if time is not None and values.get(clock) == '0' and updates.get(clock) == '1':
                    yield time * tick_ps, {name: values.get(code) for name, code in codes.items()}
                values.update(updates)
                updates.clear()
                time = int(token[1:])
            elif token[0] in 'bBrRsS':
                next(tokens, None)
            elif token[0] in '01xXzZ' and token[1:] in watched:
                updates[token[1:]] = token[0].lower()
    if time is not None and values.get(clock) == '0' and updates.get(clock) == '1':
        yield time * tick_ps, {name: values.get(code) for name, code in codes.items()}


def measure(vcd, raw):
    start = raw['npu_busy_edge_ps']
    end = raw['npu_done_edge_ps']
    period = raw['clock_period_ps']
    if period <= 0 or end <= start or (end - start) % period:
        raise ValueError('Invalid F12 clock window')

    reads = writes = responses = 0
    waits, latencies = [], []
    waiting_since = None
    outstanding_at = None
    covered_edges = 0
    with vcd.open(encoding='ascii') as stream:
        for time_ps, signals in rising_edges(stream):
            # BUSY goes high after its edge. DONE may rise on the final response edge.
            if not start < time_ps <= end:
                continue
            cycle = covered_edges + 1
            if time_ps != start + cycle * period:
                raise ValueError('Missing F12 clock edge in BUSY–DONE')
            covered_edges = cycle
            if signals['rst_n'] != '1' or any(
                signals[name] not in ('0', '1') for name in SIGNALS[2:]
            ):
                raise ValueError('Unknown or reset DMEM probes during F12')

            owner = signals['observe_npu_owner'] == '1'
            valid = signals['observe_valid'] == '1'
            ready = signals['observe_ready'] == '1'
            accepted = signals['observe_accept'] == '1'
            if accepted != (valid and ready):
                raise ValueError('DMEM acceptance disagrees with valid/ready')
            if outstanding_at is not None and signals['observe_response'] == '1':
                latencies.append(cycle - outstanding_at)
                responses += 1
                outstanding_at = None
            if waiting_since is not None and not (owner and valid):
                raise ValueError('CNN withdrew a stalled DMEM request')
            if owner and valid and waiting_since is None:
                waiting_since = cycle
            if owner and accepted:
                if outstanding_at is not None:
                    raise ValueError('Overlapping outstanding CNN DMEM requests')
                waits.append(cycle - waiting_since)
                waiting_since = None
                outstanding_at = cycle
                if signals['observe_write'] == '1':
                    writes += 1
                else:
                    reads += 1

    if covered_edges != (end - start) // period:
        raise ValueError('F12 waveform did not cover BUSY–DONE')
    if waiting_since is not None or outstanding_at is not None or responses != reads + writes:
        raise ValueError('Incomplete CNN DMEM transaction at DONE')
    if reads != raw['cnn_reads']:
        raise ValueError('Waveform read count disagrees with the V8 F12 monitor')
    return {
        'reads': reads, 'writes': writes, 'responses': responses,
        'request_wait_cycles_total': sum(waits),
        'request_wait_cycles_max': max(waits, default=None),
        'response_cycles_total': sum(latencies),
        'response_cycles_min': min(latencies, default=None),
        'response_cycles_max': max(latencies, default=None),
    }
