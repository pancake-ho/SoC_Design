"""Bridge DC SDF to the timing declarations in the course SAED32 models."""
import hashlib
import json
import re
from decimal import Decimal, ROUND_CEILING


CELL = re.compile(
    r'^\(CELL\n[ \t]+\(CELLTYPE "(SRAM1RW\d+x\d+)"\)\n'
    r'[ \t]+\(INSTANCE(?: ([^)\n]+))?\)\n.*?^\)', re.M | re.S)
MODEL = re.compile(r'^module (SRAM1RW\d+x\d+)\s*\([^;]+\);.*?^endmodule\b',
                   re.M | re.S)
RESET_CELL = re.compile(
    r'^\(CELL\n[ \t]+\(CELLTYPE "(DFFARX[12]_RVT)"\)\n'
    r'[ \t]+\(INSTANCE(?: ([^)\n]+))?\)\n.*?^\)', re.M | re.S)
RESET_LIMIT = re.compile(
    r'^(?P<indent>[ \t]+)\((?P<kind>RECOVERY|HOLD) '
    r'\(posedge RSTB\) \(posedge CLK\) '
    r'(?P<limit>\(-?\d+(?:\.\d+)?(?::-?\d+(?:\.\d+)?){2}\))\)[ \t]*$', re.M)
PATH = re.compile(r'^\s*\(IOPATH (\(posedge CE\)|OEB) O\[(\d+)\] .+\)$')
CHECK = re.compile(
    r'^(?P<indent>[ \t]+)\((?P<kind>SETUP|HOLD) '
    r'\((?P<event>(?:posedge|negedge) (?:CSB|WEB|[AI]\[\d+\]))\) '
    r'\(posedge CE\) \((?P<limits>-?\d+(?:\.\d+)?(?::-?\d+(?:\.\d+)?){2})\)\)$')
CHECK_START = re.compile(r'^[ \t]+\(TIMINGCHECK[ \t]*$', re.M)


def prepare_sram_timing(source_model, stdcell_model, sdf, run_dir):
    """Give SDF records matching specify paths and checks in a scratch model.

    DC can emit two unconditional CSB setup records for the same pin and edge.
    VCS annotations overwrite a timing site, so keep the stricter setup limit
    in each column. All path delays and all other timing records stay intact.
    """
    cells = {}
    instances = []
    original = sdf.read_text(encoding='ascii')
    if '(TIMESCALE 1ns)' not in original:
        raise ValueError('Expected DC SDF time unit 1ns; do not guess timing-check units')
    audit = dict(sdf_sha256=hashlib.sha256(sdf.read_bytes()).hexdigest(),
                 simulation_precision_ps=1, sram_limit_rounding='CEILING_TOWARD_STRICTER',
                 rounded_sram_limits=[], removed_unannotated_zero_checks=[])

    def inspect_cell(match):
        name, instance = match.groups()
        width = int(name.rsplit('x', 1)[1])
        paths = set()
        checks = {}
        duplicates = 0
        lines = match[0].splitlines()
        for index, line in enumerate(lines):
            if line.lstrip().startswith('(IOPATH '):
                arc = PATH.fullmatch(line.rstrip())
                if arc is None:
                    raise ValueError(f'Unsupported SRAM output path in {sdf.name}: {line.strip()}')
                edge, bit = arc[1], int(arc[2])
                key = edge, bit
                if bit >= width or key in paths:
                    raise ValueError(f'Invalid or duplicate SRAM path in {name}: {line.strip()}')
                paths.add(key)

        timing = CHECK_START.search(match[0])
        if timing is None:
            raise ValueError(f'Missing SRAM timing checks in {sdf.name}: {instance}')
        start = match[0].count('\n', 0, timing.start()) + 1
        end = lines.index('  )', start)
        for index in range(start, end):
            line = lines[index]
            check = CHECK.fullmatch(line.rstrip())
            if check is None:
                raise ValueError(f'Unsupported SRAM timing check in {sdf.name}: {line.strip()}')
            key = (check['event'], check['kind'])
            previous = checks.get(key)
            if previous is None:
                checks[key] = (index, check['limits'])
                continue
            if key[1] != 'SETUP' or not key[0].endswith(' CSB'):
                raise ValueError(f'Ambiguous SRAM timing check in {sdf.name}: {line.strip()}')
            previous_index, previous_limits = previous
            limits = ':'.join(max(a, b, key=Decimal) for a, b in zip(
                previous_limits.split(':'), check['limits'].split(':')))
            lines[previous_index] = lines[previous_index].replace(
                '(' + previous_limits + ')', '(' + limits + ')')
            lines[index] = None
            checks[key] = (previous_index, limits)
            duplicates += 1
        if not paths or not checks:
            raise ValueError(f'No SRAM paths or checks in {sdf.name}: {instance}')

        # The educational SRAM tables contain setup+hold sums down to -0.3ps.
        # Round each limit UP to the actual 1ps simulator grid, never toward a
        # weaker constraint. Raw DC SDF and STA are not edited. Reject a larger
        # inconsistency instead of hiding it with a timing-check disable.
        for event, kind in checks:
            if kind != 'SETUP' or (event, 'HOLD') not in checks:
                continue
            setup = checks[(event, 'SETUP')][1].split(':')
            hold = checks[(event, 'HOLD')][1].split(':')
            if any(Decimal(s)+Decimal(h) < Decimal('-0.001') for s,h in zip(setup,hold)):
                raise ValueError('SRAM setup+hold inconsistency exceeds 1ps: '+instance+' '+event)
        for (event, kind), (index, limits) in checks.items():
            rounded = []
            for column, value in enumerate(limits.split(':')):
                before = Decimal(value)
                after = before.quantize(Decimal('0.001'), rounding=ROUND_CEILING)
                if after < before or after-before >= Decimal('0.001'):
                    raise ValueError('Timing rounding must tighten by less than 1ps')
                rounded.append(format(after, 'f'))
                if before != after:
                    audit['rounded_sram_limits'].append(dict(instance=instance,event=event,
                        kind=kind,column=column,original_ns=str(before),simulation_ns=str(after)))
            lines[index] = lines[index].replace('('+limits+')', '('+':'.join(rounded)+')')

        cell_paths, cell_checks = cells.setdefault(name, (set(), set()))
        cell_paths.update(paths)
        cell_checks.update(checks)
        instances.append(dict(cell=name, instance=instance or '(root)', output_paths=len(paths),
                              timing_checks=len(checks), duplicate_csb_setup=duplicates))
        monitor = timing_cell(name + '_ee470_checks', instance, 'ee470_sram_check',
                              (line for line in lines[start:end] if line is not None))
        return '\n'.join(lines[:start - 1] + lines[end + 1:]) + '\n' + monitor

    annotated = CELL.sub(inspect_cell, original)
    expected_cells = len(re.findall(r'^[ \t]+\(CELLTYPE "SRAM1RW\d+x\d+"\)', original, re.M))
    if len(instances) != expected_cells:
        raise ValueError(f'Could not parse all SAED32 SRAM cells in {sdf.name}')
    patched = set()

    def add_specify(match):
        name = match[1]
        if name not in cells:
            return match[0]
        if name in patched or re.search(r'\bspecify\b', match[0]):
            raise ValueError(f'Expected the original SAED32 SRAM model for {name}')
        width = int(name.rsplit('x', 1)[1])
        path_hooks, check_hooks = cells[name]
        bit_instance = re.compile(
            rf'(^[ \t]*{name}_1bit\s+sram_IO(\d+)\s*\([^;\n]*,\s*)O\[(\d+)\](\s*\);)',
            re.M)
        existing = sorted((int(bit[2]), int(bit[3])) for bit in bit_instance.finditer(match[0]))
        if existing != [(bit, bit) for bit in range(width)]:
            raise ValueError(f'Unexpected SAED32 SRAM bit wiring for {name}')
        # Keep the original bit slices. Place annotation on the macro boundary.
        body = bit_instance.sub(r'\g<1>ee470_raw_q[\g<3>]\g<4>', match[0])
        first = bit_instance.search(match[0]).start()
        body = (body[:first] + f'wire [{width - 1}:0] ee470_raw_q;\n'
                + 'assign O = ee470_raw_q;\n' + body[first:])

        specify = ['specify']
        for edge, bit in sorted(path_hooks, key=lambda arc: (arc[1], arc[0])):
            if edge == '(posedge CE)':
                specify.append(f'  (posedge CE => (O[{bit}] : ee470_raw_q[{bit}])) = (0,0);')
            else:
                specify.append(f'  (OEB => O[{bit}]) = (0,0,0,0,0,0);')
        specify.append('endspecify')
        body = (body[:-len('endmodule')] + '\n'.join(specify)
                + f'\n{name}_ee470_checks ee470_sram_check(A, CE, WEB, CSB, I);\nendmodule')
        # A separate check instance keeps VCS's negative timing-check offsets
        # independent of the CE->O path delay on the functional macro.
        monitor = [f'module {name}_ee470_checks(A, CE, WEB, CSB, I);',
                   'input CE, WEB, CSB;',
                   'input [\x60numAddr-1:0] A;',
                   'input [\x60wordLength-1:0] I;',
                   'reg ee470_timing_notifier;',
                   'specify']
        for event in sorted({event for event, _ in check_hooks}):
            monitor.append(f'  $setuphold(posedge CE, {event}, 0, 0, ee470_timing_notifier);')
        monitor += ['endspecify', 'endmodule']
        patched.add(name)
        return body + '\n\n' + '\n'.join(monitor)

    model_file = source_model
    if instances:
        model = MODEL.sub(add_specify, source_model.read_text(encoding='ascii'))
        if patched != cells.keys():
            raise ValueError('Missing SAED32 SRAM model: ' + ', '.join(sorted(cells.keys() - patched)))
        model_file = run_dir/'saed32sram_timing.v'
        model_file.write_text(model, encoding='ascii')
    annotated, stdcell_file, reset_count = prepare_reset_checks(annotated, stdcell_model, run_dir)
    stdcell_file = remove_unannotated_zero_checks(annotated, stdcell_file, run_dir, audit)
    (run_dir/'model_timing_audit.json').write_text(json.dumps(audit,indent=2)+'\n')
    if annotated != original:
        sdf = run_dir/'annotate.sdf'
        sdf.write_text(annotated, encoding='ascii')
    return model_file, stdcell_file, sdf, instances, reset_count


def remove_unannotated_zero_checks(sdf_text, source_model, run_dir, audit):
    """Remove ONLY unused zero-width library placeholders, not SDF checks.

    SAED32 DFFSSR contains zero-width SETB/RSTB and falling-clock D hooks.
    DC's actual synchronous-cell checks use rising CLK. The unused hooks
    create incompatible delayed-signal equations in VCS's NTC solver.
    Refuse to remove them if the supplied SDF could annotate one of them.
    """
    cells = re.compile(r'^\(CELL\n\s+\(CELLTYPE "(DFFSSRX[12]_RVT)"\)\n.*?^\)',re.M|re.S)
    used = set()
    for m in cells.finditer(sdf_text):
        used.add(m[1])
        if '(TIMINGCHECK' not in m[0]:continue
        section=m[0].split('(TIMINGCHECK',1)[1]
        for line in section.splitlines():
            if line.strip() in (')',''):continue
            # These rising-clock declarations are distinct from all nine
            # zero-width placeholders removed below. Width checks stay.
            if re.fullmatch(r'\s*\((SETUP|HOLD) \((posedge|negedge) (D|RSTB|SETB)\) '
                            r'\(posedge CLK\) \([^)]+\)\)\s*',line):continue
            if line.lstrip().startswith('(WIDTH '):continue
            raise ValueError('DFFSSR SDF may use a placeholder; review instead of removing: '+line)
    model=source_model.read_text(encoding='ascii')
    for name in sorted(used):
        module=re.compile(r'^module '+name+r'\b.*?^endmodule',re.M|re.S)
        m=module.search(model)
        if m is None:raise ValueError('Missing standard-cell model '+name)
        placeholders=re.compile(r'^\$setuphold\s*\([^\n]*,\s*0,\s*0,\s*notifier\s*\);[ \t]*$',re.M)
        found=placeholders.findall(m[0])
        if len(found)!=9:raise ValueError('Unexpected DFFSSR placeholder layout '+name)
        for line in found:
            if not (line.startswith('$setuphold (posedge SETB') or line.startswith('$setuphold (negedge CLK')):
                raise ValueError('Unexpected zero-width timing check '+line)
            audit['removed_unannotated_zero_checks'].append(dict(cell=name,declaration=line))
        patched=placeholders.sub('// Unannotated zero-width placeholder excluded from NTC equations.',m[0])
        model=model[:m.start()]+patched+model[m.end():]
    if used:
        target=run_dir/'saed32nm_timing.v';target.write_text(model,encoding='ascii')
        return target
    return source_model


def timing_cell(celltype, parent, instance, checks):
    path = f'{parent}/{instance}' if parent else instance
    return '\n'.join(['(CELL', f'  (CELLTYPE "{celltype}")', f'  (INSTANCE {path})',
                      '  (TIMINGCHECK', *checks, '  )', ')'])


def prepare_reset_checks(sdf_text, source_model, run_dir):
    """Represent signed DFFAR reset windows as combined recovery/removal."""
    patched_cells = set()
    count = 0

    def combine(match):
        nonlocal count
        checks = list(RESET_LIMIT.finditer(match[0]))
        recovery = [check for check in checks if check['kind'] == 'RECOVERY']
        if not any('-' in check['limit'] for check in recovery):
            return match[0]
        hold = [check for check in checks if check['kind'] == 'HOLD']
        if len(recovery) != 1 or len(hold) != 1:
            raise ValueError('Ambiguous DFFAR reset checks in DC SDF: ' + match[0].splitlines()[2])
        rec, rem = recovery[0], hold[0]
        combined = (f"{rec['indent']}(RECREM (posedge RSTB) (posedge CLK) "
                    f"{rec['limit']} {rem['limit']})")
        patched_cells.add(match[1])
        count += 1
        # HOLD on reset release is the removal part of this reset window.
        parent = match[0].replace(rec[0] + '\n', '', 1).replace(rem[0] + '\n', '', 1)
        monitor = timing_cell('ee470_dffar_reset_check', match[2], 'ee470_reset_check', [combined])
        return parent + '\n' + monitor

    annotated = RESET_CELL.sub(combine, sdf_text)
    if not patched_cells:
        return annotated, source_model, count

    model = source_model.read_text(encoding='ascii')
    for name in sorted(patched_cells):
        module = re.compile(rf'^module {name}\s*\([^;]+\);.*?^endmodule\b', re.M | re.S)
        match = module.search(model)
        if match is None or match[0].count('\nendspecify') != 1:
            raise ValueError('Unexpected SAED32 reset model for ' + name)
        body = (match[0][:-len('endmodule')]
                + 'ee470_dffar_reset_check ee470_reset_check(RSTB, CLK);\nendmodule')
        model = model[:match.start()] + body + model[match.end():]
    model += ('\nmodule ee470_dffar_reset_check(RSTB, CLK);\n'
              'input RSTB, CLK;\n'
              'reg notifier;\n'
              'specify\n'
              '  $recrem(posedge RSTB, posedge CLK, 0, 0, notifier);\n'
              'endspecify\nendmodule\n')
    model_file = run_dir/'saed32nm_timing.v'
    model_file.write_text(model, encoding='ascii')
    return annotated, model_file, count
