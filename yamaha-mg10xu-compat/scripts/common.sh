#!/usr/bin/env bash

set -euo pipefail

readonly DEFAULT_UNIT_NAME="yamaha-mg10xu-audio-keepalive.service"
readonly MANAGED_UNIT_MARKER="# Managed by io.github.tbogard.yamaha-mg-xu"
readonly YAMAHA_USB_VENDOR_ID="0499"

UNIT_NAME="${UNIT_NAME:-$DEFAULT_UNIT_NAME}"
YAMAHA_SOURCE="${YAMAHA_SOURCE:-}"
USER_UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
UNIT_PATH="$USER_UNIT_DIR/$UNIT_NAME"

validate_configuration() {
  if [[ ! "$UNIT_NAME" =~ ^[A-Za-z0-9_.@-]+\.service$ ]]; then
    printf 'Invalid UNIT_NAME: expected a systemd service basename.\n' >&2
    exit 2
  fi
  if [[ -n "$YAMAHA_SOURCE" && ! "$YAMAHA_SOURCE" =~ ^[A-Za-z0-9_.:@-]+$ ]]; then
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

discover_yamaha_sources() {
  pw-dump 2>/dev/null | jq -r --arg vendor "USB${YAMAHA_USB_VENDOR_ID}:" '
    .[]
    | select(.type == "PipeWire:Interface:Node")
    | (.info.props // {})
    | select(.["media.class"] == "Audio/Source")
    | select((.["alsa.components"] // "") | ascii_upcase | startswith($vendor))
    | select(
        [.["alsa.card_name"], .["alsa.long_card_name"], .["node.description"], .["node.nick"]]
        | map(. // "")
        | join(" ")
        | test("MG[ _-]*([0-9]+[ _-]*)?XU"; "i")
      )
    | .["node.name"] // empty
  '
}

resolve_yamaha_source() {
  if [[ -n "$YAMAHA_SOURCE" ]]; then
    printf '%s\n' "$YAMAHA_SOURCE"
    return 0
  fi

  local -a sources=()
  mapfile -t sources < <(discover_yamaha_sources)
  case "${#sources[@]}" in
    0)
      return 1
      ;;
    1)
      printf '%s\n' "${sources[0]}"
      ;;
    *)
      printf 'Multiple Yamaha MG-XU capture sources were found; set YAMAHA_SOURCE explicitly.\n' >&2
      return 2
      ;;
  esac
}

yamaha_present() {
  resolve_yamaha_source >/dev/null
}

validate_configuration
