# Horizon Display Layout

An Omarchy shell plugin that makes Omnissa Horizon see monitors in the same
positions the user configured in Hyprland.

## Why it is needed

Omnissa Horizon Client for Linux runs through XWayland. On some multi-monitor
Omarchy systems, XWayland packs outputs in connector enumeration order instead
of preserving Hyprland's logical coordinates. Horizon then sends that incorrect
topology to the remote desktop.

For example, Hyprland may correctly arrange monitors as:

`ASUS -> Elgato -> Dell`

while Horizon reports:

`Dell -> ASUS -> Elgato`

This plugin reads the active monitor names and coordinates from `hyprctl`, then
launches Horizon with a small compatibility library that corrects the Xinerama
and RandR coordinates returned specifically to Horizon. It does not modify the
global XWayland layout, `~/.config/hypr/monitors.lua`, or Horizon's broker
preferences.

The service builds the compatibility library when Omarchy Shell loads.
Left-click the bar icon to open its status panel. The panel compares the
Hyprland preference with Horizon's uncorrected XWayland order and provides two
separate actions:

- **Verify fix** asks Horizon itself to list the monitors through the
  compatibility layer and displays the result.
- **Launch Horizon** starts the normal client with the corrected layout.

The layout is captured on every verification and launch, covering login and
monitor hot-plug changes. The bar icon becomes fully opaque after Horizon has
verified the expected layout during the current shell session.

## Requirements

- Omarchy with Hyprland and XWayland
- Omnissa Horizon Client for Linux
- `hyprctl`
- `jq`
- `xrandr` from `xorg-xrandr`
- A C compiler (`cc`) to build the small compatibility library

## Install

Place this directory at:

`~/.config/omarchy/plugins/io.github.tbogard.horizon-display-layout`

Then enable it:

```sh
omarchy plugin enable io.github.tbogard.horizon-display-layout --section right
```

## Active-session restriction

Use `../fix-horizon-screens` from the recovery bundle for live alignment.
Fully quit Horizon before setup, verification, monitor enumeration, or restoring
plugin files. Testing these operations during an active VDI was followed by a
recreated, misplaced render window. The recovery script guards restore and
verification; the raw helper and panel buttons below do not.

## Command-line diagnostics

```sh
scripts/horizon-display-layout setup
scripts/horizon-display-layout layout
scripts/horizon-display-layout status
scripts/horizon-display-layout verify
scripts/horizon-display-layout monitors
scripts/horizon-display-layout launch
scripts/horizon-display-layout log
```

The activity log is stored at:

`~/.local/state/horizon-display-layout/activity.log`

The bar and panel use the Omnissa Horizon icon distributed with the Linux
client package. Its opacity indicates whether the layout has been verified in
the current Omarchy Shell session.

## Uninstall

```sh
omarchy plugin disable io.github.tbogard.horizon-display-layout
```

Then remove the plugin directory. The generated compatibility library under
`~/.local/state/horizon-display-layout/` is inert when Horizon is launched
normally and may be removed at any time.
