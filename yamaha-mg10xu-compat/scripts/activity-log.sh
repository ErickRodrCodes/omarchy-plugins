#!/usr/bin/env bash

set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

require_command journalctl

limit="${1:-60}"
if [[ ! "$limit" =~ ^[1-9][0-9]*$ ]] || (( limit > 200 )); then
  printf 'Usage: %s [lines: 1-200]\n' "$0" >&2
  exit 2
fi

output="$(journalctl --user --unit "$UNIT_NAME" --no-pager --quiet \
  --output short-iso --lines "$limit" 2>&1)" || {
  printf 'Unable to read the compatibility-layer journal:\n%s\n' "$output"
  exit 1
}

if [[ -n "$output" ]]; then
  printf '%s\n' "$output"
else
  printf 'No compatibility-layer activity has been recorded yet.\n'
fi
