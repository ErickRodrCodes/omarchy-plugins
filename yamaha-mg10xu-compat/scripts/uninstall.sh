#!/usr/bin/env bash

set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

dry_run=false
if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=true
elif [[ $# -gt 0 ]]; then
  printf 'Usage: %s [--dry-run]\n' "$0" >&2
  exit 2
fi

require_command systemctl
require_command grep

if [[ -e "$UNIT_PATH" ]] && ! unit_is_managed; then
  printf 'Refusing to remove unmanaged user unit: %s\n' "$UNIT_PATH" >&2
  exit 1
fi

if $dry_run; then
  printf 'Would stop and remove: %s\n' "$UNIT_PATH"
  printf 'No changes made.\n'
  exit 0
fi

if [[ ! -e "$UNIT_PATH" ]]; then
  printf '%s is not installed.\n' "$UNIT_NAME"
  exit 0
fi

systemctl --user disable --now "$UNIT_NAME" >/dev/null 2>&1 || true
rm -f -- "$UNIT_PATH"
systemctl --user daemon-reload
systemctl --user reset-failed "$UNIT_NAME" >/dev/null 2>&1 || true
printf 'Removed %s\n' "$UNIT_NAME"
