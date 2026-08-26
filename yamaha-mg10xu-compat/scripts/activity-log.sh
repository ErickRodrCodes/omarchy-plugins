#!/usr/bin/env bash

set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

require_command journalctl

readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/yamaha-mg-xu-compat"
readonly CLEAR_MARKER="$STATE_DIR/activity-cleared-at"

limit="60"
clear=false
case "${1:-}" in
  "") ;;
  --clear) clear=true ;;
  *) limit="$1" ;;
esac

if [[ ! "$limit" =~ ^[1-9][0-9]*$ ]] || (( limit > 200 )); then
  printf 'Usage: %s [lines: 1-200|--clear]\n' "$0" >&2
  exit 2
fi

if $clear; then
  mkdir -p -- "$STATE_DIR"
  date +%s >"$CLEAR_MARKER"
  chmod 0600 "$CLEAR_MARKER"
  printf 'Activity log cleared. New service activity will appear here.\n'
  exit 0
fi

journal_args=(--user --unit "$UNIT_NAME" --no-pager --quiet --output short-iso --lines "$limit")
if [[ -r "$CLEAR_MARKER" ]]; then
  cleared_at="$(<"$CLEAR_MARKER")"
  if [[ "$cleared_at" =~ ^[0-9]+$ ]]; then
    journal_args+=(--since "@${cleared_at}")
  fi
fi

output="$(journalctl "${journal_args[@]}" 2>&1)" || {
  printf 'Unable to read the compatibility-layer journal:\n%s\n' "$output"
  exit 1
}

if [[ -n "$output" ]]; then
  printf '%s\n' "$output"
else
  printf 'No compatibility-layer activity since the log was cleared.\n'
fi
