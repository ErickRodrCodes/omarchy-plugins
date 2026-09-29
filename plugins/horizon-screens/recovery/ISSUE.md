# Recover Horizon screens on Omarchy

Verified on this machine on September 11, 2026. The user confirmed all three
screens worked after correcting both the remote monitor topology and the local
Horizon window position.

## Quick recovery

Run from a terminal in your logged-in Omarchy desktop:

```bash
~/Work/horizon-layout-repair/fix-horizon-screens
```

This aligns the existing spanning Horizon window with the active monitor layout.
It does not disconnect the VDI. Running it again on an aligned window sends no move command.

Inspect or preview first:

```bash
~/Work/horizon-layout-repair/fix-horizon-screens status
~/Work/horizon-layout-repair/fix-horizon-screens fix --dry-run
```

If monitor ordering broke after a Horizon update, or the compatibility plugin or
launchers were removed, **fully quit Horizon first**, then run:

```bash
~/Work/horizon-layout-repair/fix-horizon-screens restore
```

Both `restore` and `verify` refuse to run while Horizon is open.

Recovery sequence:

1. Before running `restore`, disconnect from the remote desktop and fully quit Horizon. Disconnecting alone
   leaves the old process and its old environment running. Do not sign out of
   Windows unless you intend to end the remote session.
2. Run `fix-horizon-screens restore` while Horizon is closed. After it succeeds,
   open Horizon through its normal application launcher or the Cloud Desktop
   shortcut. The browser sign-in handler also uses the repaired application entry.
3. Select all three monitors in Horizon and choose Full Screen → All Screens.
4. If Omarchy's Super+F has constrained the window to a single monitor, toggle
   that compositor fullscreen state off. The working configuration is a floating
   all-screen window, not Hyprland single-monitor fullscreen.
5. Run `fix-horizon-screens` again to align the spanning window.
6. Check that maximized remote windows and the pointer line up on each display.

To verify the corrected monitor enumeration independently, **fully quit Horizon first**:

```bash
~/Work/horizon-layout-repair/fix-horizon-screens verify
```

This launches a diagnostic process. During testing, running this diagnostic and
restoring plugin files with an active VDI was followed by the render window being
recreated at −1920,0. The precise trigger was not isolated. Both operations are
therefore blocked while Horizon is running; only `fix` and `status` are intended
for an active session. A passing enumeration check alone does not
prove that an already-running VDI has loaded the fix or that its window is aligned.

## What went wrong

The physical and Hyprland arrangement was:

| Display | Connector at diagnosis | Resolution | Position |
| --- | --- | --- | --- |
| ASUS PB287Q | DP-3 | 3840×2160 | 0,0 |
| Elgato Prompter | DVI-I-1 | 1024×600 | 3840,0 |
| Dell S2522HG | DP-2 | 1920×1080 | 4864,0 |

All displays used scale 1, no rotation, and top alignment. The combined bounding
rectangle was 6784×2160. Black areas below shorter monitors in a combined screenshot
are expected because those coordinates have no physical display.

There were two separate failures:

1. **Wrong monitor topology inside Horizon.** XWayland exposed Dell at 0,0,
   ASUS at 1920,0, and Elgato at 5760,0. Horizon therefore numbered them
   Dell → ASUS → Elgato, even though Hyprland's positions were correct.
   The saved Horizon Display Layout plugin was absent from its installed path,
   and the running client had no compatibility library loaded. Restoring the
   library and routing both launchers through its wrapper made Horizon report
   ASUS → Elgato → Dell. The desktop preferences already selected all three
   monitors; changing the unrelated app monitor preference was not the fix.
2. **Correctly sized window at the wrong origin.** Even after relaunching with
   the compatibility library, Hyprland placed Horizon's 6784×2160 window at
   **−1920,0**. Its right edge was 4864, exactly where the Dell began. Moving
   the window to **0,0** restored all three screens. The user confirmed success.

The working move on this Lua-based Hyprland build was:

```lua
hl.dsp.window.move({ window = "address:<current-window-address>", x = 0, y = 0 })
```

Here x/y are **absolute coordinates**. The script discovers the address and the
bounding rectangle each time; it does not reuse the original process/window ID.
Legacy `hyprctl dispatch movewindowpixel ...` syntax failed on this build.

Temporarily setting `xwayland.force_zero_scaling` to false did not change the live
XWayland topology. It was restored to true; this recovery does not modify it.

The September 6 bar-layer fix addressed a different issue: a spanning floating
VDI window did not report compositor fullscreen and the top bar stayed above it.
This recovery does not modify bar layers or virtualization input mode.

## Files and behavior

- `fix-horizon-screens`: recovery script, defaulting to live window alignment.
- `plugin/`: a bundled copy of the verified Horizon Display Layout plugin,
  including its C compatibility source and launch wrapper. Keep this directory
  alongside the script; copying the script alone is not sufficient for `restore`.
- `backups/`: timestamped backups created by `restore` before overwriting the
  installed plugin, existing compatibility library, and any launchers it changes.
- `*.desktop.before`: original launcher backups from the September 11 repair.

`restore` copies the bundled plugin to
`~/.config/omarchy/plugins/io.github.tbogard.horizon-display-layout`, rebuilds
`~/.local/state/horizon-display-layout/libhorizon-display-layout.so`, and verifies
monitor enumeration before updating launcher entries. The shared library is
replaced atomically so an existing process's mapped library is not overwritten
in place. The plugin does not need a bar widget enabled for the wrapper to work.

Launcher changes preserve arguments, including browser authentication URLs.
Existing repaired entries are left alone. Ordinary user desktop entries that
invoke `horizon-client` directly are routed through the wrapper. A removed main
entry is recreated from `/usr/share/applications/horizon-client.desktop`.
The script never edits packaged files, monitor configuration, or broker settings.
A restore failure can leave partially restored files; backups remain available.
Restore is not a transaction and does not automatically roll changes back.

## Limits after updates

Requires Python 3, hyprctl, xrandr, jq, a C compiler and X11 development headers,
Horizon Client, and update-desktop-database. Run as your normal desktop user,
not with sudo.

Recovery deliberately expects three active displays, scale 1 and no rotation.
If Elgato is missing at the Hyprland level, restore its driver/display first;
this script cannot recreate a missing physical output. Connector names and
positions are read dynamically, so a connector rename alone is not a problem.

The live fix only acts on one mapped, floating Horizon window whose size matches
the full layout and whose process environment contains the compatibility wrapper
variables. It refuses ambiguous sessions, single-screen windows, or missing
launch compatibility. It checks the resulting position and size after dispatch.

A future Horizon or Hyprland update may change APIs or window behavior. A failed
verification is a reason to inspect `status` and the plugin's activity log, not
proof that the old shim still works. The script does not automatically disconnect
sessions, change remote Windows display settings, or run a background watcher.
Re-run the live fix if entering fullscreen or reconnecting reintroduces the offset.

Activity log: `~/.local/state/horizon-display-layout/activity.log`.

## Active-session regression during recovery testing

The restore test on September 11 disturbed the working session: the Horizon
render window acquired a new address and reverted to −1920,0 while remaining
6784×2160. Moving the new window to 0,0 repaired its placement. The restore
operation included plugin file replacement and a Horizon monitor-list process;
we did not isolate which triggered recreation. The script now checks for running
Horizon processes and windows before any restore writes or verification launch.
Do not use the plugin’s Verify button or its raw helper monitor-list command
during an active VDI session. Use the guarded recovery script instead.

## Roll back a restore

Fully quit Horizon first. Find the backup path printed by the restore command
under `backups/`. Its timestamp identifies that particular attempt.

- Copy backed-up `.desktop` files to `~/.local/share/applications/`, then run
  `update-desktop-database ~/.local/share/applications`.
- If `plugin/` exists in that backup, restore its files to
  `~/.config/omarchy/plugins/io.github.tbogard.horizon-display-layout/`.
- If `libhorizon-display-layout.so` exists in that backup, restore it to
  `~/.local/state/horizon-display-layout/` (or the corresponding XDG state path).
- Files that did not exist before restore have no backup. The newly installed
  plugin and generated library can remain inert if launchers no longer use them.
  If the main user launcher was newly created, the backup contains the packaged
  launcher used as its source; restoring that copy removes the wrapper routing.

Backups may contain custom launcher arguments. Keep them local. The script never
uploads backups, screenshots, or logs.

## Validation and maintenance

Run the isolated regression suite without interacting with your desktop:

```bash
python3 ~/Work/horizon-layout-repair/test_recovery.py
```

All 10 tests passed after the active-session guard was added. They cover:

- Absolute positioning, a shifted monitor origin, and already-aligned windows.
- Dry runs, missing displays, scaling/rotation, ambiguous or fullscreen windows,
  absent compatibility variables, and failed placement verification.
- Refusal before restore writes or diagnostic launches when Horizon is active.
- Restore and repeated restore in a temporary directory, preserving launcher
  arguments and backing up the plugin, launcher, and existing library.

The suite substitutes desktop commands and the compiler with test doubles;
its restore tests do not prove compatibility with future Horizon versions.
Earlier live testing confirmed corrected three-monitor enumeration and window
alignment, and the user confirmed the visual result. Running a live restore test
also exposed the regression documented above. After that incident, further
script tests ran in isolation without modifying the active desktop.
