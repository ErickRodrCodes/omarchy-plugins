#!/usr/bin/env bash

set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

readonly DESKTOP_NAME="io.github.tbogard.yamaha-mg-xu.desktop"
readonly DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
readonly DESKTOP_PATH="$DESKTOP_DIR/$DESKTOP_NAME"
readonly DESKTOP_MARKER="X-Yamaha-MGXU-Managed=true"
readonly ICON_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps/io.github.tbogard.yamaha-mg-xu.svg"

require_command grep
require_command cmp

if [[ ! -e "$DESKTOP_PATH" ]]; then
  printf 'Application launcher is not installed.\n'
  exit 0
fi
if ! grep -Fxq "$DESKTOP_MARKER" "$DESKTOP_PATH"; then
  printf 'Refusing to remove unmanaged desktop entry: %s\n' "$DESKTOP_PATH" >&2
  exit 1
fi

rm -f -- "$DESKTOP_PATH"
icon_source="$(plugin_root)/assets/yamaha.svg"
if [[ -e "$ICON_PATH" ]] && cmp -s -- "$icon_source" "$ICON_PATH"; then
  rm -f -- "$ICON_PATH"
fi
printf 'Removed application launcher: %s\n' "$DESKTOP_PATH"
