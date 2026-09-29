# Horizon Screens for Omarchy

A bar panel that derives Horizon display positions and mouse boundaries from the
active Hyprland monitors. No connector names, monitor counts, resolutions, or
left-to-right order are hardcoded.

## Actions

| Button | Action | While Horizon is running |
| --- | --- | --- |
| Align screens | Move the existing all-screen window to the monitor layout origin | Available for one eligible spanning window |
| Repair screens and mouse | Match XWayland geometry and pointer bounds to Hyprland for this session | Blocked |
| Undo input layout | Unload the session repair | Blocked |
| Check screens | Read Hyprland monitor/window positions and process state | Available |
| Verify launch fix | Ask a diagnostic Horizon process to enumerate corrected monitors | Blocked |
| Restore launch fix | Back up and rebuild compatibility; repair selected shortcuts | Blocked |

Opening the panel performs only a read-only check. Loading the service does not
compile code, move windows, start Horizon, or run monitor-list diagnostics.
Buttons disable during commands. Backend guards recheck session state at action
time, so stale panel state cannot bypass the running-client restriction.
The panel uses existing Omarchy colors/components and scrolls on short displays.

## Launcher shortcuts

Expand **Launcher shortcuts**. The panel detects candidate desktop entries from
`~/.local/share/applications` and `/usr/share/applications`, preferring user entries
with the same filename. Edit the list (one full `.desktop` path per line), then
click **Save shortcut selection**. Saving only stores your selection; it does not
change any shortcuts. Restore requires a saved selection and modifies only those
entries. An empty saved list deliberately restores compatibility without changing
shortcuts. Duplicate filenames are rejected.

Supported commands are direct `horizon-client` commands, optionally `/usr/bin/`
and/or `env GDK_SCALE=1`, and the existing compatibility wrapper. Arguments such
as `%u` and direct desktop URLs are preserved. A system shortcut is repaired by
creating a user override, never by modifying `/usr/share/applications`.

The selectable **Command for a custom launcher** shows the replacement Exec
command for a normal Horizon launcher. For direct-desktop shortcuts, preserve
that shortcut's existing URL argument instead of `%u`. Unrecognized custom shell
commands are rejected rather than guessed at. The editor selects files; it does
not execute arbitrary code.

Selection is saved in `~/.local/state/horizon-screens/launchers.json` (respects
`XDG_STATE_HOME`). Reopen the panel or click Check after closing Horizon to
refresh which actions are available.

## Install

Fully quit Horizon first, then run:

```bash
~/Work/omarchy-plugins/plugins/horizon-screens/install
```

The installer checks for running Horizon processes/windows before writing
anything. It copies this directory to
`~/.config/omarchy/plugins/io.github.tbogard.horizon-screens` and enables it in
the right bar. Existing copies are backed up under
`~/.local/state/horizon-screens/install-backups/`.

The installer also backs up and updates the companion `horizon-display-layout`
launcher, so the panel and launch-time coordinate model stay in sync. This new panel calls the guarded recovery script;
it does not use the old panel's unguarded Verify button. The new panel's installer
does not itself run Restore or launch Horizon.

After installation:

1. Open the Horizon Screens bar icon.
2. Review and save Launcher shortcuts.
3. If needed, Restore launch fix while Horizon is closed.
4. While Horizon is closed, click **Repair screens and mouse**.
5. Open Horizon normally and select Full Screen → All Screens.
6. Open the panel and click Align screens if the window is shifted.

After changing the monitor arrangement, fully quit and reopen Horizon. The launch
signature detects changes even if the combined window size stays the same. The
native hook follows supported monitor rearrangements for the current desktop
session; click Repair again after logging in to a new session. No persistent
compositor autoload is installed.

If Super+F has constrained the window to one monitor, turn off that compositor
fullscreen state before alignment. Alignment does not change the remote desktop's
monitor selection or size.

## Display and pointer coordinates

Hyprland's resolved monitor positions are the source of truth. The shared model
in `recovery/plugin/scripts/layout_model.py` computes the bounding rectangle and
each output rectangle. For X11, the minimum x/y is subtracted from every output;
this preserves negative-origin layouts, offsets, vertical stacking, and gaps.
The Horizon spanning window is aligned to the original Hyprland minimum x/y.

The native compositor hook changes XWayland positions before output geometry is
published. This corrects the coordinate space used by both displays and input,
rather than trying to remap individual mouse events after clipping has occurred.
Once those rectangles agree, the launcher removes its old display override and
lets Horizon use native display/input APIs. The legacy override remains a display
fallback, but Check and Align never report it as a complete input repair.

The original defect was confirmed again on September 29: X11 clipped x to 5759
or y to 599 in Dell's lower-right area, while Hyprland's pointer continued.
The user confirmed the session repair restored access. See [AGENTS.md](AGENTS.md)
for durable project memory and the distinction between live and offline checks.

Supported: any nonempty set of nonoverlapping, unrotated monitors at scale 1,
including automatic placement, reordered outputs, offsets, stacks, gaps, and
negative origins. Bounding width/height must fit X11's 32767-pixel limit.
Scaling, rotation, and mirroring are explicitly rejected; their conversion is
not yet implemented. Empty space between screens remains empty space.

Native hooks are pinned to Hyprland commit
`efb50993780079460b0cbed1363e2166a2de1d9f` and checked against the running ABI.
A different build requires code review/rebuild, not bypassing the guard.
Loading/unloading affects all X11 applications and requires Horizon to be closed.
Failed post-load geometry verification unloads the correction. **Undo input
layout** restores stock XWayland arrangement. If an older repair is loaded,
Undo it before enabling the updated repair. The installer does not silently
replace a loaded compositor library.

## Validation

```bash
python3 ~/Work/omarchy-plugins/plugins/horizon-screens/test_backend.py
python3 ~/Work/omarchy-plugins/plugins/horizon-screens/recovery/test_recovery.py
```

Run all Python checks and the native build/tests:

```bash
python3 test_backend.py
python3 recovery/test_recovery.py
python3 recovery/test_layout_model.py
python3 native/test_control.py
python3 native/test_launcher.py
python3 native/control.py build /tmp/horizon-layout-build
```

Regression coverage includes pointer clipping geometry, monitor reordering,
negative coordinates, vertical layouts, one/two/four outputs, gaps, disabled
outputs, invalid layouts, launch signatures, argument preservation, session
guards, and rollback. These offline tests do not prove remote pointer behavior
for every arrangement. The original three-screen arrangement was validated live.

Requirements: Omarchy/Hyprland at the supported build, Python 3, Quickshell, jq,
xrandr, Horizon Client, C/C++ compiler, Hyprland/X11 headers, pkg-config, and
update-desktop-database. There is no background window alignment watcher.

## Remove

Close Horizon before changing watched plugin files, then run:

```bash
omarchy plugin disable io.github.tbogard.horizon-screens
```

Removing this panel does not remove the separate launch compatibility wrapper or
undo launcher repairs. Use the restore backups described in the incident document
if you want to revert those separately.
