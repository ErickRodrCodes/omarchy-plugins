# Virtualization Input Mode

An Omarchy bar plugin that temporarily yields compositor-level shortcuts to a
guest application. It is intended for virtual machines, VDIs, remote desktop
clients, nested compositors, game streaming, and any other application that
needs to receive combinations such as `Alt+Tab` or `Super`.

## Why it is needed

Omarchy implements its desktop shortcuts in Hyprland. Those global bindings
remain active while a VM or remote desktop has focus, so Hyprland consumes the
key combination before the guest can receive it. This is especially visible
with the `Super` key and `Alt+Tab`: instead of reaching the guest operating
system, they continue to control the local Omarchy desktop.

Virtualization Input Mode activates an otherwise empty Hyprland submap. While
that submap is active, the usual Omarchy bindings are not matched and the key
events can reach the focused application. Turning the mode off restores the
default Omarchy submap.

The toggle is fully manual and does not require a particular application or
open window. Enable it before launching a full-screen VM, VDI, remote desktop,
or similar environment so the guest starts with the expected keyboard
behavior. `Super+Ctrl+Escape` is always available inside the special submap as an
emergency way to restore Omarchy shortcuts.

While input mode is on, each monitor's bar moves to the bottom layer, above
its wallpaper and below application windows. The bar remains enabled: a guest
can cover it, and minimizing or closing the covering window reveals it again.
This also works for multi-monitor VDIs that use a large borderless window
without reporting fullscreen. Turning input mode off restores the previous
bar layer. `Super+Ctrl+Escape` restores local shortcuts and the normal bar layer
(within the service's one-second status refresh).
On startup, the plugin restores a bar hidden by an older version of its guard.

The active submap survives an Omarchy shell restart. When the shell returns,
the plugin reads Hyprland's current submap and restores the toggle's displayed
state instead of resetting the user's choice.

## Optional status providers

The current plugin includes a separate, read-only Omnissa Horizon detector.
It reports whether a Horizon VDI window is open, but it never enables,
disables, or gates Virtualization Input Mode. Other virtualization detectors
can be added later without changing the toggle.

The bar uses a vendor-neutral virtualization/input icon.

## Requirements

- Omarchy `4.0.1-1` with its Quickshell bar and Lua-based Hyprland configuration.
- Bash and `hyprctl` (provided by the desktop environment).
- A guest application that accepts keyboard input. No Horizon installation is required.

## Install

Clone this collection, copy the plugin into the user plugin directory, and enable it:

```sh
git clone https://github.com/ErickRodrCodes/omarchy-plugins.git
mkdir -p ~/.config/omarchy/plugins
cp -a omarchy-plugins/plugins/virtualization-input-mode \
  ~/.config/omarchy/plugins/io.github.tbogard.virtualization-input-mode
omarchy plugin enable io.github.tbogard.virtualization-input-mode --section right
```

For an existing installation, back up its directory before replacing its files.
Plugin files normally reload automatically. If the bar retains stale state after
an update, run `omarchy restart shell`.

## Usage

1. Open the virtualization icon on the bar and turn input mode on.
2. Focus your VM or remote desktop. Local Omarchy shortcuts yield to that application,
   and the bars remain below application windows on every monitor.
3. Minimize or close the covering application to access the bar toggle again,
   or press `Super+Ctrl+Escape` to restore local shortcuts and the normal bar layer.

The mode is manual and applies across the desktop until disabled. It does not
follow application focus. Layer restoration can take up to one second.

## Verified behavior

Version `0.2.1` fixes the bar becoming inaccessible when input mode is enabled.
It lowers the bar instead of hiding it. This was tested with Omnissa Horizon
spanning three monitors as a 6784×2160 floating window with no compositor
fullscreen flag. ON/OFF and the emergency reset action restored the expected
layers on all three monitors; the user confirmed the multi-monitor VDI worked.

## Diagnostics

Open **Diagnostic log** from the panel, or inspect:

`~/.local/state/virtualization-input-mode/activity.log`

## Uninstall

Turn input mode off first (or press `Super+Ctrl+Escape`) so the active
Hyprland submap does not retain guest-mode shortcuts after removal.

```sh
omarchy plugin disable io.github.tbogard.virtualization-input-mode
```

Then remove the plugin directory.
