# Omarchy Plugins

A collection of Omarchy shell integrations by Erick Rodriguez. Each plugin is designed as a self-contained, theme-aware component with documented dependencies, safe installation and removal, and an explicit tested Omarchy version.

## Plugins

| Plugin | Omarchy version | Description |
| --- | --- | --- |
| [Yamaha MG-XU Compatibility](yamaha-mg10xu-compat/) | `4.0.1-1` | Detects Yamaha MG10XU/MG-XU mixers and provides one synchronized compatibility interface as both a bar panel and launcher app. It manages the user-level PipeWire capture keepalive, reports device and service status, and includes a clearable activity log. |
| [Virtualization Input Mode](plugins/virtualization-input-mode/) | `4.0.1-1` | Manually pass desktop shortcuts to VMs and remote desktops. Keeps bars beneath guest windows across monitors; turning the mode off or using `Super+Ctrl+Escape` restores local shortcuts and bar layers. |

The listed Omarchy version is the version used for live validation. Each plugin directory is self-contained; see its README and manifest for requirements, configuration, installation, usage, and removal instructions.
