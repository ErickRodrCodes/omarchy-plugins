# Yamaha MG-XU Compatibility

An Omarchy bar widget by Erick Rodriguez for Yamaha MG10XU/MG-XU mixers that lose playback sound after a few seconds. Turn the compatibility layer on when playback starts normally and then becomes silent even though PipeWire still shows it as active.

The workaround runs a user-level service that reads the Yamaha capture source and sends every sample to `/dev/null`. Nothing is recorded, retained, or transmitted.

The Yamaha badge follows the active Omarchy theme: normal foreground means the compatibility layer is active, while the standard dimmed treatment means it is off. Left-click opens the panel; right-click toggles the layer directly. The panel's Activity log subpanel shows recent service starts, stops, restarts, and errors from the systemd user journal.

## Install

From a checkout of this collection:

```bash
mkdir -p ~/.config/omarchy/plugins
cp -a yamaha-mg10xu-compat ~/.config/omarchy/plugins/io.github.tbogard.yamaha-mg-xu
omarchy plugin enable io.github.tbogard.yamaha-mg-xu right
```

For a standalone repository containing this directory at its root:

```bash
omarchy plugin add https://github.com/tbogard/yamaha-mg10xu-compat.git --enable
```

## Requirements

- Yamaha MG10XU/MG-XU visible to PipeWire
- PipeWire tools (`pw-record`, `pw-dump`, `wpctl`) and `jq`
- systemd user services

The plugin runs with your user permissions. It uses no root privileges and depends on `pw-record`, `pw-dump`, `wpctl`, `jq`, and a systemd user session. Enabling it installs and starts `~/.config/systemd/user/yamaha-mg10xu-audio-keepalive.service`.

## Safety

- Never runs `sudo`, `pkexec`, a second Quickshell process, or remote code.
- Never edits packaged files under `/usr/share/omarchy`.
- Writes only its exact systemd user-unit path and refuses path-like unit names.
- Refuses to overwrite or remove a unit unless it contains this plugin's ownership marker.
- Validates the PipeWire source name before placing it in the service definition.
- Detects an MG-XU capture node from Yamaha's USB vendor ID (`0499`) and the MG-XU family name; it does not require a particular product ID such as `1703`.
- Refuses to enable the layer when no matching device is present or when multiple matches make selection ambiguous.
- Rolls back the installed file if systemd cannot activate the service.
- Runs `pw-record` with systemd restrictions including `NoNewPrivileges`, protected system/home paths, private devices and temporary files, and Unix-socket-only networking.
- Continuously discards capture samples to `/dev/null`; it does not save or transmit them.

## Usage

If your MG-XU mixer loses sound after a few seconds, click the Yamaha badge and turn the compatibility layer on. Turn it off when the workaround is not needed. Press `T` or Enter to toggle, `R` to refresh, and Escape to close. You can also use:

```bash
scripts/status.sh
scripts/activity-log.sh
scripts/install.sh --dry-run
scripts/install.sh
scripts/uninstall.sh --dry-run
scripts/uninstall.sh
```

The capture source is discovered from live PipeWire metadata, so PipeWire naming changes and Yamaha product IDs other than `1703` do not require configuration. If more than one MG-XU capture source is connected, set `YAMAHA_SOURCE` to the exact node name you want to use.

## How it works

Omarchy's audio panel creates a `PwNodePeakMonitor` for the default input while the panel is open. On an affected MG-XU, that capture activity keeps the USB duplex clock moving and playback audible. The service reproduces only that keepalive behavior without requiring the panel to remain open.

## Validate

```bash
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml
tests/detection.sh
```

## Remove

Turn the compatibility layer off first, then remove the widget:

```bash
scripts/uninstall.sh
omarchy plugin remove io.github.tbogard.yamaha-mg-xu
```

The plugin never edits `/usr/share/omarchy`.
