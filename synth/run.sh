#!/usr/bin/env bash
set -euo pipefail
export EE470_RTL_DEFINES
EE470_RTL_DEFINES=$(python3 ../model/vectors.py --rtl-defines --profile "${1:-../config/public_profile.json}")
test ! -e work
test ! -e outputs
mkdir logs
timeout 600s dcnxt_topo_queue -f topo_ndm.tcl | tee logs/dc_topo.log
grep -F -x PROJECT1_BASELINE_TOPO_COMPLETE logs/dc_topo.log
test -s outputs/project_mapped.v
