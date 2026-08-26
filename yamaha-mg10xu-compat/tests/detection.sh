#!/usr/bin/env bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/../scripts/common.sh"

fixture='[]'
pw-dump() {
  printf '%s\n' "$fixture"
}

source_node() {
  local components="$1"
  local name="$2"
  jq -cn --arg components "$components" --arg name "$name" '[{
    type: "PipeWire:Interface:Node",
    info: {props: {
      "media.class": "Audio/Source",
      "alsa.components": $components,
      "alsa.card_name": "MG-XU",
      "node.name": $name
    }}
  }]'
}

expected="alsa_input.usb-Yamaha_Corporation_MG-XU-00.analog-stereo"

# The Yamaha vendor and MG-XU family identify the device; the product ID may vary.
fixture="$(source_node "USB0499:BEEF" "$expected")"
[[ "$(resolve_yamaha_source)" == "$expected" ]]

# A different vendor using the same product label must not match.
fixture="$(source_node "USB1234:1703" "$expected")"
if resolve_yamaha_source >/dev/null 2>&1; then
  printf 'Non-Yamaha device was incorrectly detected.\n' >&2
  exit 1
fi

# Multiple valid capture nodes require an explicit choice.
fixture="$(jq -s '.[0] + .[1]' \
  <(source_node "USB0499:1703" "alsa_input.usb-Yamaha_MG-XU-A") \
  <(source_node "USB0499:1704" "alsa_input.usb-Yamaha_MG-XU-B"))"
if resolve_yamaha_source >/dev/null 2>&1; then
  printf 'Ambiguous Yamaha devices were incorrectly accepted.\n' >&2
  exit 1
else
  [[ $? -eq 2 ]]
fi

printf 'Detection tests passed.\n'
