#!/usr/bin/env bash

set -euo pipefail

readonly DEFAULT_UNIT_NAME="yamaha-mg10xu-audio-keepalive.service"
readonly DEFAULT_YAMAHA_SOURCE="alsa_input.usb-Yamaha_Corporation_MG-XU-00.analog-stereo"

UNIT_NAME="${UNIT_NAME:-$DEFAULT_UNIT_NAME}"
YAMAHA_SOURCE="${YAMAHA_SOURCE:-$DEFAULT_YAMAHA_SOURCE}"
USER_UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
UNIT_PATH="$USER_UNIT_DIR/$UNIT_NAME"

plugin_root() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$1" >&2
    exit 1
  fi
}

yamaha_present() {
  wpctl status 2>/dev/null | grep -Fq 'MG-XU'
}
