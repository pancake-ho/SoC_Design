"""Apply the v9.4.2 ICG timing patch without changing team RTL, config or synthesis outputs."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import shutil
import sys

HERE=Path(__file__).resolve().parent


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def safe_target(root,relative):
    path=root/relative
    if path.is_symlink() or any(p.is_symlink() for p in path.parents if p!=root.parent):
        raise ValueError('Linked patch target: '+relative)
    try:path.resolve().relative_to(root)
    except ValueError:raise ValueError('Target outside baseline_release')
    return path


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    mode=parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--check',action='store_true');mode.add_argument('--apply',action='store_true')
    parser.add_argument('--root',type=Path,default=HERE.parents[1])
    args=parser.parse_args();root=args.root.resolve()
    if not (root/'rtl/project_top.v').is_file() or not (root/'config/public_profile.json').is_file():
        raise ValueError('Run inside the existing v9.4 baseline_release')
    if not (root/'synth/saif_audit.py').is_file() or sha(root/'synth/power_saif.py') != 'cd41b3842c43361a6789db454a1fe861c947811d9cb800f1d42d866ac8133983':
        raise ValueError('Apply the v9.4 SAIF patch before v9.4.2; modified harness preserved')
    manifest=json.loads((HERE/'manifest.json').read_text())
    pending=[]
    for name,item in manifest.items():
        source=HERE/'payload'/name;target=safe_target(root,name)
        if sha(source)!=item['new']:raise ValueError('Corrupted payload: '+name)
        old=sha(target) if target.is_file() else None
        if old==item['new']:continue
        if old not in item['old']:
            raise ValueError('Modified harness/file preserved: '+name+'. Review and merge this file manually.')
        pending.append((name,source,target))
    print('ICG_PATCH_CHECK_PASS files='+str(len(pending)))
    if args.check:return
    if not pending:print('ALREADY_PATCHED');return
    backup=root/'patch_backups'/('v9_4_2_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S_%f'))
    backup.mkdir(parents=True)
    for name,source,target in pending:
        if target.is_file():
            old=backup/name;old.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,old)
    changed=[]
    try:
        for name,source,target in pending:
            target.parent.mkdir(parents=True,exist_ok=True)
            scratch=target.with_name(target.name+'.v9_4_2_new')
            if scratch.exists():raise ValueError('Temporary path already exists: '+str(scratch))
            with scratch.open('xb') as stream:stream.write(source.read_bytes())
            scratch.replace(target);changed.append((name,target))
    except Exception:
        for name,target in reversed(changed):
            old=backup/name
            if old.exists():shutil.copy2(old,target)
            else:target.unlink()
        raise
    print('ICG_PATCH_APPLIED backup='+str(backup))
    print('RTL_CONFIG_SDC_NETLIST_DDC_SDF_UNCHANGED')


if __name__=='__main__':
    try:main()
    except (OSError,ValueError) as error:sys.exit('ICG_PATCH_ERROR: '+str(error))
