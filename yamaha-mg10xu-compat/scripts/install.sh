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

require_command pw-record
require_command wpctl
require_command systemctl
require_command sed
require_command install

if ! yamaha_present; then
  printf 'Yamaha MG-XU was not found in the current PipeWire graph.\n' >&2
  exit 1
fi

root="$(plugin_root)"
template="$root/assets/yamaha-mg10xu-audio-keepalive.service.in"

if $dry_run; then
  printf 'Would install: %s\n' "$UNIT_PATH"
  printf 'Capture source: %s\n' "$YAMAHA_SOURCE"
  printf 'No changes made.\n'
  exit 0
fi

mkdir -p -- "$USER_UNIT_DIR"
temporary_unit="$(mktemp "${TMPDIR:-/tmp}/yamaha-mg10xu-unit.XXXXXX")"
trap 'rm -f -- "$temporary_unit"' EXIT
sed "s|@YAMAHA_SOURCE@|$YAMAHA_SOURCE|g" "$template" >"$temporary_unit"

# Replace a previous linked development unit cleanly.
systemctl --user disable --now "$UNIT_NAME" >/dev/null 2>&1 || true
rm -f -- "$UNIT_PATH"
install -m 0644 -- "$temporary_unit" "$UNIT_PATH"
systemctl --user daemon-reload
systemctl --user enable --now "$UNIT_NAME"

printf 'Installed and started %s\n' "$UNIT_NAME"
printf 'Microphone samples are discarded to /dev/null and are not saved.\n'
