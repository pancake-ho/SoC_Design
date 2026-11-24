"""Update only the supplied gate timing bridge; preserve RTL, SDC and results."""
from pathlib import Path
import argparse,datetime,shutil

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path('.'))
    action=parser.add_mutually_exclusive_group(required=True)
    action.add_argument('--check',action='store_true');action.add_argument('--apply',action='store_true')
    args=parser.parse_args();root=args.root.resolve();payload=Path(__file__).resolve().parent
    tcl=root/'synth/topo_ndm.tcl'
    if not tcl.is_file() or 'set_app_var compile_seqmap_honor_sync_set_reset true' not in tcl.read_text():
        raise ValueError('Apply the v9.1 synchronous-reset fix and resynthesize first; this model patch does not change RTL')
    updates={}
    for source,target in [('gate_timing.py','synth/gate_timing.py'),('saed_sram_sdf.py','synth/saed_sram_sdf.py'),
                          ('MODEL_TIMING_FIX_KO.md','docs/MODEL_TIMING_FIX_KO.md')]:
        src=payload/source;dst=root/target
        if not src.is_file() or dst.is_symlink() or root not in dst.resolve().parents:
            raise ValueError('Unexpected source/target path: '+target)
        if not dst.exists() or dst.read_bytes()!=src.read_bytes():updates[dst]=src
    for dst in updates:print('UPDATE '+str(dst.relative_to(root)))
    if not updates:print('ALREADY_PATCHED');return
    if args.check:print('CHECK_ONLY_NO_CHANGE');return
    backup=root/'patch_backups'/('v9_2_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S_%f'))
    for dst,src in updates.items():
        if dst.exists():
            old=backup/dst.relative_to(root);old.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,old)
        dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
    print('PATCH_APPLIED backup='+str(backup))
    print('Rerun python3 synth/gate_timing.py against your v9.1 synthesized outputs. RTL/SDC/netlist/SDF are unchanged.')

if __name__=='__main__':main()
