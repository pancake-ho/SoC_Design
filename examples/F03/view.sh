#!/usr/bin/env bash
set -euo pipefail
test -s activity.vcd
verdi_sub -ssf activity.vcd
