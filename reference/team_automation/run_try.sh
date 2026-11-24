#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

if [[ $# -ne 1 || ! $1 =~ ^[0-9]{2,8}$ ]]; then
    printf 'Usage: bash packages/run_try.sh 02\n' >&2
    exit 2
fi

number=$((10#$1))
printf -v current '%02d' "$number"
printf -v next '%02d' "$((number + 1))"
if [[ $number -lt 1 || $1 != "$current" ]]; then
    printf 'Use 01, 02, ... 99, 100, ... as the attempt number.\n' >&2
    exit 2
fi

packages=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
results="$(dirname -- "$packages")/results"
archive="$packages/$current.tar.gz"
if [[ ! -f $archive ]]; then
    printf 'Package missing: %s\n' "$archive" >&2
    exit 2
fi

result="$results/$current"
work="$result/work"
published="$result/${current}_evidence.tar.gz"
mkdir -p -- "$result"
if [[ -e $published || -L $published ]] || ! mkdir -- "$work"; then
    printf 'Attempt %s already has work or evidence at %s\n' "$current" "$result" >&2
    exit 2
fi
mkdir -p -- "$results/$next" "$work/package"
printf 'TRY_DIR=%s\nNEXT_TRY_DIR=%s\n' "$result" "$results/$next"
tar -xzf "$archive" -C "$work/package"

launchers=("$work/package"/*/run.sh)
if [[ ${#launchers[@]} -ne 1 || ! -f ${launchers[0]} ]]; then
    printf 'Expected one top-level package folder containing run.sh.\n' >&2
    exit 2
fi

status=0
bash "${launchers[0]}" --results-root "$work/runs" || status=$?
archives=("$work/runs"/*_evidence.tar.gz)
if [[ ${#archives[@]} -eq 1 && -s ${archives[0]} ]]; then
    mv -- "${archives[0]}" "$published"
    printf 'RESULT_ARCHIVE=%s\n' "$published"
else
    printf 'Evidence archive was not produced. See %s\n' "$work" >&2
    if [[ $status -eq 0 ]]; then status=1; fi
fi
exit "$status"
