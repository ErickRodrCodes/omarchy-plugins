# Horizon Screens project memory

## Confirmed on 2026-09-29

The user confirmed full pointer access after loading the native input-layout
repair, closing and reopening Horizon. Before repair, the picture was aligned
but XQueryPointer clipped at x=5759 or y=599 on Dell while Hyprland continued
into its lower-right area. The Xinerama/RandR/GDK LD_PRELOAD shim alone does not
repair pointer events, queries, warps, or confinement. Repeated client restarts
and window alignment alone are not a durable correction.

Hyprland is the source of truth. The user controls monitor count, order and
positions. Never encode ASUS/Elgato/Dell names, connector order, resolutions,
three screens, or a horizontal row into runtime repair logic. Normalize the
whole resolved layout by its minimum x/y for X11; preserve relative positions,
gaps and screen dimensions. Window placement remains in Hyprland coordinates.

The shared model is recovery/plugin/scripts/layout_model.py. Native layout.hpp
must agree with its geometry constraints. Native hooks update XWayland positions
before output geometry is published so display and pointer coordinates agree.
Keep the exact Hyprland ABI/build check. Unsupported scaling, rotation, overlaps,
mirroring and oversized bounds must produce an explicit failure, not a partial
repair. General arbitrary layouts are regression-tested, but only the user's
original three-screen layout has been validated in a connected remote session.

Close Horizon before native load/unload, installing watched plugin files, or
running Horizon monitor diagnostics. Read-only status and guarded alignment are
safe during a session. Layout changes require a fresh Horizon launch; compare
the launch signature before claiming alignment. Do not silently disconnect the
user from a future active VDI session merely to update the plugin.

No persistent compositor autoload is configured. Repair is session-only. Source
and installed panel previously differed: installed panel lacked native repair.
Keep the companion horizon-display-layout launcher and panel in sync at install.
