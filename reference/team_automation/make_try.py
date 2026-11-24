"""Build a numbered DICE package from your own clean V8 release and RTL."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import tarfile


KIT = Path(__file__).resolve().parent
AUTOMATION = KIT / 'automation'
SERVER_FILES = ('pipeline.py', 'activity.py', 'power.tcl', 'v8_reference_hashes.json')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('number', type=int)
    parser.add_argument('--release-root', required=True, type=Path)
    parser.add_argument('--rtl-root', required=True, type=Path)
    parser.add_argument('--team-id', required=True)
    parser.add_argument('--output-dir', default=Path.cwd(), type=Path)
    parser.add_argument('--through', choices=('functional', 'synth', 'gate', 'power'), default='synth')
    args = parser.parse_args()
    if not 1 <= args.number <= 99_999_999:
        parser.error('Use a positive attempt number up to 99999999')
    if not re.fullmatch(r'[A-Za-z0-9_-]{1,32}', args.team_id):
        parser.error('Use letters, digits, underscores or hyphens for --team-id')
    number = f'{args.number:02d}'
    root = 'ee470_v8_try' + number
    output = args.output_dir.resolve() / (number + '.tar.gz')
    if output.exists():
        parser.error(f'Archive already exists: {output}')

    release = args.release_root.resolve()
    rtl = args.rtl_root.resolve()
    if rtl in output.parents or release in output.parents:
        parser.error('Put the output outside the source directories')
    if not rtl.is_dir():
        parser.error(f'RTL directory not found: {rtl}')
    files = {f'automation/{name}': AUTOMATION / name for name in SERVER_FILES}
    expected = json.loads((AUTOMATION / 'v8_reference_hashes.json').read_text(encoding='utf-8'))
    for name, digest in expected.items():
        if name.startswith('rtl/'):
            continue
        path = release / name
        if not path.is_file() or path.is_symlink() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            parser.error(f'Use the exact clean V8 baseline_release. Changed or missing: {name}')
        files[f'baseline_release/{name}'] = path
    rtl_files = []
    for path in sorted(rtl.rglob('*')):
        if path.is_symlink() or not (path.is_file() or path.is_dir()):
            parser.error(f'RTL tree contains a link or special file: {path}')
        if path.is_file():
            rtl_files.append(path)
    if not any(path.suffix in ('.v', '.sv') for path in rtl_files):
        parser.error('No .v or .sv source found in --rtl-root')
    files.update({f'team_rtl/{path.relative_to(rtl).as_posix()}': path for path in rtl_files})
    launcher = (
        '#!/usr/bin/env bash\nset -euo pipefail\n'
        'cd -- "$(dirname -- "$0")"\n'
        'exec python3 automation/pipeline.py run --release-root baseline_release '
        f'--rtl-root team_rtl --results-root runs --team-id {args.team_id} --through {args.through} "$@"\n'
    )
    digest = {name: hashlib.sha256(path.read_bytes()).hexdigest() for name, path in files.items()}
    digest['run.sh'] = hashlib.sha256(launcher.encode()).hexdigest()
    extra = {'run.sh': launcher, 'package_manifest.json': json.dumps(digest, indent=2) + '\n'}
    output.parent.mkdir(parents=True, exist_ok=True)
    with tarfile.open(output, 'x:gz') as archive:
        for name, path in sorted(files.items()):
            archive.add(path, arcname=f'{root}/{name}', recursive=False)
        for name, content in extra.items():
            data = content.encode()
            entry = tarfile.TarInfo(f'{root}/{name}')
            entry.size = len(data)
            archive.addfile(entry, io.BytesIO(data))
    print(output)


if __name__ == '__main__':
    main()
