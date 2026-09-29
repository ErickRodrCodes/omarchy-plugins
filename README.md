# Omarchy Plugins

A catalog of Omarchy shell integrations by Erick Rodriguez. Each published plugin is maintained in its own repository; follow its installation instructions and changelog there.

## Plugins

<!-- plugins:start -->

| Plugin | Version | Tested Omarchy | Changelog | Description |
| --- | --- | --- | --- | --- |
| [Horizon Display Layout](https://github.com/ErickRodrCodes/horizon-display-layout) | `0.1.0` | `4.0.1-1` | [Changelog](https://github.com/ErickRodrCodes/horizon-display-layout/blob/main/CHANGELOG.md) | Keep Omnissa Horizon's XWayland monitor layout aligned with the user's Hyprland display positions. |
| [Horizon Screens](https://github.com/ErickRodrCodes/horizon-screens) | `1.1.0` | `4.0.1-1` | [Changelog](https://github.com/ErickRodrCodes/horizon-screens/blob/main/CHANGELOG.md) | Align Horizon screens and mouse boundaries with the current Hyprland display arrangement. |
| [Litra Beam for Omarchy](https://github.com/ErickRodrCodes/litra-beam-for-omarchy) | `0.1.0` | `4.0.1-1` | [Changelog](https://github.com/ErickRodrCodes/litra-beam-for-omarchy/blob/main/CHANGELOG.md) | Control one or many Logitech Litra Beam lights over USB or Bluetooth, independently or in sync. |
| RGB-Fireblade for Omarchy (unpublished) | `0.1.0` | `4.0.1-1` | [Changelog](changelogs/rbg-fireblade.md) | Theme-aware RGB controls for Omarchy, beginning with the active theme accent color. |
| [Virtualization Input Mode](https://github.com/ErickRodrCodes/virtualization-input-mode) | `0.2.0` | `4.0.1-1` | [Changelog](https://github.com/ErickRodrCodes/virtualization-input-mode/blob/main/CHANGELOG.md) | Pass Omarchy desktop shortcuts through to virtual machines, VDIs, and remote desktop clients. |
| [Yamaha MG-XU Compatibility](https://github.com/ErickRodrCodes/yamaha-mg10xu-compat) | `1.1.1` | `4.0.1-1` | [Changelog](https://github.com/ErickRodrCodes/yamaha-mg10xu-compat/blob/main/CHANGELOG.md) | Turn it on when a Yamaha MG-XU mixer loses playback sound after a few seconds; it keeps the PipeWire capture side active. |

<!-- plugins:end -->

Plugin versions come from each repository's `manifest.json` on `main`; they do not imply a tagged release. Tested Omarchy is the version recorded by the plugin author, not a guarantee of compatibility with newer versions.

RGB-Fireblade is currently an unpublished local project. Its baseline changelog is included here until a standalone repository is available.

## Keeping the catalog current

A daily GitHub Actions workflow refreshes published plugin versions and tested Omarchy versions. It also runs when catalog files change and can be started manually from the Actions tab.

To refresh locally:

```sh
python3 scripts/update-catalog.py --refresh
```

To render from the checked-in metadata without network access, omit `--refresh`. Use `--check` to verify that the README matches the metadata. Add repositories in `plugins.json`; published repositories must provide a root `manifest.json` and `CHANGELOG.md`. Record changes in the plugin's changelog whenever its version changes. Update unpublished entries manually from their local manifests.

Plugin source directories are intentionally excluded from this catalog repository.
