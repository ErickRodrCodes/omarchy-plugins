#!/usr/bin/env bash

set -euo pipefail

readonly DEFAULT_UNIT_NAME="yamaha-mg10xu-audio-keepalive.service"
readonly DEFAULT_YAMAHA_SOURCE="alsa_input.usb-Yamaha_Corporation_MG-XU-00.analog-stereo"
readonly MANAGED_UNIT_MARKER="# Managed by io.github.tbogard.yamaha-mg-xu"

UNIT_NAME="${UNIT_NAME:-$DEFAULT_UNIT_NAME}"
YAMAHA_SOURCE="${YAMAHA_SOURCE:-$DEFAULT_YAMAHA_SOURCE}"
USER_UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
UNIT_PATH="$USER_UNIT_DIR/$UNIT_NAME"

validate_configuration() {
  if [[ ! "$UNIT_NAME" =~ ^[A-Za-z0-9_.@-]+\.service$ ]]; then
    printf 'Invalid UNIT_NAME: expected a systemd service basename.\n' >&2
    exit 2
  fi
  if [[ ! "$YAMAHA_SOURCE" =~ ^[A-Za-z0-9_.:@-]+$ ]]; then
    printf 'Invalid YAMAHA_SOURCE: unsupported characters in PipeWire node name.\n' >&2
    exit 2
  fi
  if [[ "$UNIT_PATH" != "$USER_UNIT_DIR/$UNIT_NAME" ]]; then
    printf 'Refusing unsafe unit path.\n' >&2
    exit 2
  fi
}

plugin_root() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$1" >&2
    exit 1
  fi
}

unit_is_managed() {
  [[ -f "$UNIT_PATH" ]] && grep -Fxq "$MANAGED_UNIT_MARKER" "$UNIT_PATH"
}

yamaha_present() {
  wpctl status 2>/dev/null | grep -Fq 'MG-XU'
}

validate_configuration
