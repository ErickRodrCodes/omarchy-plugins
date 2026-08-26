---
name: yamaha-mg10xu-audio
description: Diagnose and fix Yamaha MG10XU or MG-XU USB playback that becomes silent on PipeWire or Omarchy but returns while an audio panel or input monitor is open.
---

# Yamaha MG10XU Audio Compatibility

Use the bundled scripts to diagnose and manage the workaround. Do not assume every Yamaha audio problem has this cause.

## Diagnosis

Run `scripts/status.sh` from the plugin root. The workaround applies when:

- A PipeWire capture node has Yamaha's USB vendor ID (`0499`) and an MG-XU family label. Do not require product ID `1703`; it may vary by model or revision.
- Playback becomes silent although the sink remains running and unmuted.
- Playback returns while an application holds the MG-XU capture source open, such as Omarchy's audio-panel peak monitor.

If the sink actually suspends, changes route, becomes muted, or disappears from USB, diagnose that distinct condition instead.

## Install

Explain that the workaround continuously reads the Yamaha capture source and discards samples to `/dev/null`; it does not save or transmit audio. Obtain the user's approval before installation, then run:

```bash
scripts/install.sh
```

The installer creates and enables a user-level systemd service. It must not use root privileges or edit `/usr/share/omarchy`.

After installation, run `scripts/status.sh` and confirm both the service and the `pw-record` capture link are active. Ask the user to verify playback with the Omarchy audio panel closed.

## Removal

Obtain approval before removing the installed workaround, then run:

```bash
scripts/uninstall.sh
```

Removal stops and disables only `yamaha-mg10xu-audio-keepalive.service` and deletes that exact user unit.

## Overrides

The scripts discover the capture source from PipeWire metadata. They accept `YAMAHA_SOURCE` to choose an exact node when multiple MG-XU mixers are connected, and `UNIT_NAME` to avoid a local unit-name collision. Preserve automatic source discovery for an ordinary single-device setup.
