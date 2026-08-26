#!/usr/bin/env bash

set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

case "${1:-}" in
  on)
    exec "$(plugin_root)/scripts/install.sh"
    ;;
  off)
    exec "$(plugin_root)/scripts/uninstall.sh"
    ;;
  *)
    printf 'Usage: %s {on|off}\n' "$0" >&2
    exit 2
    ;;
esac
