# Yamaha MG-XU Compatibility

An Omarchy bar widget by Erick Rodriguez for Yamaha MG10XU/MG-XU mixers that lose playback sound after a few seconds. Turn the compatibility layer on when playback starts normally and then becomes silent even though PipeWire still shows it as active.

The workaround runs a user-level service that reads the Yamaha capture source and sends every sample to `/dev/null`. Nothing is recorded, retained, or transmitted.

The Yamaha `Y` badge indicates status: green means the compatibility layer is active, normal foreground means the mixer is detected but the layer is off, and dim means no MG-XU is detected. Left-click opens the panel; right-click toggles the layer directly.

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
- PipeWire tools (`pw-record`, `wpctl`)
- systemd user services

The plugin runs unsandboxed with your user permissions. It uses no root privileges and depends on `pw-record`, `wpctl`, and a systemd user session. Enabling it installs and starts `~/.config/systemd/user/yamaha-mg10xu-audio-keepalive.service`.

## Usage

If your MG-XU mixer loses sound after a few seconds, click the Yamaha badge and turn the compatibility layer on. Turn it off when the workaround is not needed. Press `T` or Enter to toggle, `R` to refresh, and Escape to close. You can also use:

```bash
scripts/status.sh
scripts/install.sh --dry-run
scripts/install.sh
scripts/uninstall.sh --dry-run
scripts/uninstall.sh
```

Set `YAMAHA_SOURCE` if the PipeWire source name differs from the default.

## How it works

Omarchy's audio panel creates a `PwNodePeakMonitor` for the default input while the panel is open. On an affected MG-XU, that capture activity keeps the USB duplex clock moving and playback audible. The service reproduces only that keepalive behavior without requiring the panel to remain open.

## Validate

```bash
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml
```

## Remove

Turn the compatibility layer off first, then remove the widget:

```bash
scripts/uninstall.sh
omarchy plugin remove io.github.tbogard.yamaha-mg-xu
```

The plugin never edits `/usr/share/omarchy`.
