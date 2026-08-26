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
require_command pw-dump
require_command jq
require_command systemctl
require_command sed
require_command install
require_command grep
require_command cp

root="$(plugin_root)"
template="$root/assets/yamaha-mg10xu-audio-keepalive.service.in"

if [[ -e "$UNIT_PATH" ]] && ! unit_is_managed; then
  printf 'Refusing to overwrite unmanaged user unit: %s\n' "$UNIT_PATH" >&2
  exit 1
fi

if resolved_source="$(resolve_yamaha_source)"; then
  :
else
  resolve_status=$?
  if [[ $resolve_status -eq 1 ]]; then
    printf 'No Yamaha MG-XU device was found in the current PipeWire graph.\n' >&2
  fi
  exit "$resolve_status"
fi

if $dry_run; then
  printf 'Would install: %s\n' "$UNIT_PATH"
  printf 'Capture source: %s\n' "$resolved_source"
  printf 'No changes made.\n'
  exit 0
fi

mkdir -p -- "$USER_UNIT_DIR"
temporary_unit="$(mktemp "${TMPDIR:-/tmp}/yamaha-mg10xu-unit.XXXXXX")"
previous_unit="$(mktemp "${TMPDIR:-/tmp}/yamaha-mg10xu-previous.XXXXXX")"
had_previous=false
if unit_is_managed; then
  cp -- "$UNIT_PATH" "$previous_unit"
  had_previous=true
fi
trap 'rm -f -- "$temporary_unit" "$previous_unit"' EXIT
sed "s|@YAMAHA_SOURCE@|${resolved_source}|g" "$template" >"$temporary_unit"

install -m 0644 -- "$temporary_unit" "$UNIT_PATH"
if ! systemctl --user daemon-reload || ! systemctl --user enable --now "$UNIT_NAME"; then
  printf 'Failed to activate %s; restoring the previous state.\n' "$UNIT_NAME" >&2
  if $had_previous; then
    install -m 0644 -- "$previous_unit" "$UNIT_PATH"
  else
    rm -f -- "$UNIT_PATH"
  fi
  systemctl --user daemon-reload >/dev/null 2>&1 || true
  exit 1
fi

printf 'Installed and started %s\n' "$UNIT_NAME"
printf 'Microphone samples are discarded to /dev/null and are not saved.\n'
