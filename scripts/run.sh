#!/usr/bin/env bash
# Suite orchestration required by the project contract. Example scripts contain direct commands.
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
exec python3 scripts/runner.py "$@"
