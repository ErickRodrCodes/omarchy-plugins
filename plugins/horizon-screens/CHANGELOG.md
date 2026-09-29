# Changelog

## 1.1.0 — 2026-09-29

- Add session-only native XWayland layout repair and undo actions to correct
  Horizon display geometry and mouse boundaries together, with an exact
  Hyprland build check and rollback when geometry verification fails.
- Derive display geometry from the active Hyprland layout, preserving relative
  positions, negative origins, vertical arrangements, offsets, and gaps without
  hardcoded monitor names, counts, or resolutions.
- Reject unsupported scaling, rotation, overlapping or mirrored outputs, and
  layouts exceeding X11 bounds explicitly.
- Detect monitor layout changes through launch signatures and require a fresh
  Horizon launch before alignment. Use native display APIs when input geometry
  is repaired, retaining the legacy display override as a fallback.
- Guard repair, undo, restore, diagnostics, and installation while Horizon is
  running; retain read-only checks and guarded window alignment during sessions.
- Install the companion Horizon Display Layout launcher alongside the panel to
  keep their coordinate model synchronized, with backups of existing copies.
- Include launcher selection and restoration, regression tests for layout and
  session guards, and documentation of supported layouts and recovery limits.

The original three-screen arrangement was validated in a connected remote
session. Other supported arrangements have offline regression coverage; native
repair is session-only and does not configure compositor autoload.
