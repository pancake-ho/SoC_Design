"""Import a MobaXterm-downloaded evidence archive into a new local directory."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import tarfile
import uuid

from pc_paths import display_path, filesystem_path

ROOT=Path(__file__).resolve().parents[1]

def main(on_import=None):
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument('archive',type=Path)
    parser.add_argument('--try-name', help='Candidate label such as try02')
    parser.add_argument('--change', help='One-line description of this RTL change')
    args=parser.parse_args()
    source_archive=filesystem_path(args.archive)
    attempt=re.fullmatch(r'(\d+)차',source_archive.parent.name)
    if not args.try_name and attempt:
        args.try_name=f'try{int(attempt[1]):02d}'
    dest=filesystem_path(ROOT/'server_results')/(datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')+'_'+uuid.uuid4().hex[:8])
    # Prevalidate every member before creating files. No links/devices or existing
    # destinations; reject both POSIX and Windows traversal spellings.
    with tarfile.open(str(source_archive),'r:gz') as archive:
        members=archive.getmembers(); seen=set(); total=0
        if len(members)>20000: raise ValueError('Unexpected archive size')
        for member in members:
            p=PurePosixPath(member.name)
            if not member.isfile() or p.is_absolute() or '..' in p.parts or '\\' in member.name or ':' in member.name:
                raise ValueError('Unsafe archive member: '+member.name)
            if member.name in seen: raise ValueError('Duplicate archive member')
            seen.add(member.name); total+=member.size
        if total>4*1024**3: raise ValueError('Evidence exceeds the local 4 GiB import limit')
        dest.mkdir(parents=True)
        for member in members:
            out=dest.joinpath(*PurePosixPath(member.name).parts)
            out.parent.mkdir(parents=True,exist_ok=True)
            with archive.extractfile(member) as inp, out.open('xb') as stream:
                while True:
                    chunk=inp.read(1024*1024)
                    if not chunk: break
                    stream.write(chunk)
    summaries=list(dest.glob('*/pipeline_summary.json'))
    if len(summaries)!=1: raise ValueError('Expected exactly one run summary; imported files retained for inspection')
    run=summaries[0].parent
    manifest=json.loads((run/'source_manifest.json').read_text(encoding='utf-8'))
    mismatches=[]
    for name,digest in manifest.items():
        path=PurePosixPath(name)
        if path.is_absolute() or '..' in path.parts or '\\' in name or ':' in name:
            raise ValueError('Unsafe source-manifest entry')
        source=run/'source'/name
        if not source.is_file() or hashlib.sha256(source.read_bytes()).hexdigest()!=digest:
            mismatches.append(name)
    check=dict(archive_sha256=hashlib.sha256(source_archive.read_bytes()).hexdigest(),
               source_manifest_matches=not mismatches,mismatches=mismatches,
               official_grading=False,physical_results_require_review=True)
    check.update(try_name=args.try_name, change=args.change)
    (run/'local_import_check.json').write_text(json.dumps(check,indent=2)+'\n',encoding='utf-8')
    if on_import is None:
        from workbench import report as on_import
    on_import()
    print('IMPORTED_RUN='+str(display_path(run)))
    print('SOURCE_MANIFEST_MATCHES='+str(not mismatches))
    return 0 if not mismatches else 1

if __name__=='__main__': raise SystemExit(main())
