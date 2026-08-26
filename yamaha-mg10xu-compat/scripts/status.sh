#!/usr/bin/env bash

set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

require_command wpctl
require_command systemctl

machine=false
if [[ "${1:-}" == "--machine" ]]; then
  machine=true
elif [[ $# -gt 0 ]]; then
  printf 'Usage: %s [--machine]\n' "$0" >&2
  exit 2
fi

detected=no
enabled=no
active=no
yamaha_present && detected=yes
systemctl --user is-enabled "$UNIT_NAME" >/dev/null 2>&1 && enabled=yes
systemctl --user is-active "$UNIT_NAME" >/dev/null 2>&1 && active=yes

if $machine; then
  printf 'detected=%s\nenabled=%s\nactive=%s\n' "$detected" "$enabled" "$active"
  if [[ "$detected" == no ]]; then
    printf 'message=Mixer not detected in the current PipeWire graph\n'
  elif [[ "$active" == yes ]]; then
    printf 'message=Compatibility layer is active\n'
  else
    printf 'message=Compatibility layer is off\n'
  fi
  exit 0
fi

if [[ "$detected" == yes ]]; then
  printf 'Yamaha MG-XU: detected\n'
else
  printf 'Yamaha MG-XU: not detected\n'
fi

if [[ "$enabled" == yes ]]; then
  printf 'Keepalive enabled: yes\n'
else
  printf 'Keepalive enabled: no\n'
fi

if [[ "$active" == yes ]]; then
  printf 'Keepalive active: yes\n'
else
  printf 'Keepalive active: no\n'
fi

if wpctl status 2>/dev/null | grep -A6 -F 'pw-record' | grep -Fq 'MG-XU:capture'; then
  printf 'Yamaha capture link: active\n'
else
  printf 'Yamaha capture link: not active\n'
fi
