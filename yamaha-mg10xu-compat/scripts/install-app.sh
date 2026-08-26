#!/usr/bin/env bash

set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

readonly DESKTOP_NAME="io.github.tbogard.yamaha-mg-xu.desktop"
readonly DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
readonly DESKTOP_PATH="$DESKTOP_DIR/$DESKTOP_NAME"
readonly DESKTOP_MARKER="X-Yamaha-MGXU-Managed=true"
readonly ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps"
readonly ICON_PATH="$ICON_DIR/io.github.tbogard.yamaha-mg-xu.svg"

require_command install
require_command grep
require_command cmp

source_file="$(plugin_root)/assets/$DESKTOP_NAME"
icon_source="$(plugin_root)/assets/yamaha.svg"
if [[ -e "$DESKTOP_PATH" ]] && ! grep -Fxq "$DESKTOP_MARKER" "$DESKTOP_PATH"; then
  printf 'Refusing to overwrite unmanaged desktop entry: %s\n' "$DESKTOP_PATH" >&2
  exit 1
fi
if [[ -e "$ICON_PATH" ]] && ! cmp -s -- "$icon_source" "$ICON_PATH"; then
  printf 'Refusing to overwrite unrelated application icon: %s\n' "$ICON_PATH" >&2
  exit 1
fi

install -D -m 0644 -- "$source_file" "$DESKTOP_PATH"
install -D -m 0644 -- "$icon_source" "$ICON_PATH"
printf 'Installed application launcher: %s\n' "$DESKTOP_PATH"
printf 'Installed Yamaha application icon: %s\n' "$ICON_PATH"
