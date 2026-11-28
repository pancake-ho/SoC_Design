#!/usr/bin/env bash
set -euo pipefail
profile=../config/public_profile.json
if [[ $# -gt 0 && $1 != --* ]]; then
    profile=$1
    shift
fi
if [[ $# -gt 0 ]]; then
    if [[ $# != 2 || $1 != --sdc || ! -f $2 || ! -r $2 ]]; then
        echo 'Usage: bash run.sh [profile.json] [--sdc team.sdc]' >&2
        exit 2
    fi
    EE470_EXTRA_SDC=$(realpath -- "$2")
    export EE470_EXTRA_SDC
fi
if [[ -n ${EE470_EXTRA_SDC:-} ]]; then
    EE470_EXTRA_SDC=$(realpath -- "$EE470_EXTRA_SDC")
    test -f "$EE470_EXTRA_SDC" && test -r "$EE470_EXTRA_SDC" || exit 2
    export EE470_EXTRA_SDC_SHA256
    EE470_EXTRA_SDC_SHA256=$(sha256sum < "$EE470_EXTRA_SDC")
    EE470_EXTRA_SDC_SHA256=${EE470_EXTRA_SDC_SHA256%% *}
fi
export EE470_RTL_DEFINES
EE470_RTL_DEFINES=$(python3 ../model/vectors.py --rtl-defines --profile "$profile")
test ! -e work
test ! -e outputs
mkdir logs
timeout 600s dcnxt_topo_queue -f topo_ndm.tcl | tee logs/dc_topo.log
grep -F -x PROJECT1_BASELINE_TOPO_COMPLETE logs/dc_topo.log
test -s outputs/project_mapped.v
