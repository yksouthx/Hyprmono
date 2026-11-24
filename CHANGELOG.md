# Changelog

Notable changes to HyprMono are documented here.

## Unreleased

### Added

- Added a repository-root `./install.sh` entry point.
- Added `hyprmono migrate` to scan known duplicate shell configurations, user
  data, local executables, and installed packages.
- Added per-item cleanup approval, package reverse-dependency checks,
  timestamped migration backups, operation logs, dry-run, and rollback.
- Added `hyprmono profile` with `low-resource` and `full-visual` Hyprland
  compositor profiles.
- Added a balanced compositor profile with intermediate blur and shadow settings.
- Added installer options for terminal mode, minimal profile, skipping cleanup
  or dependencies, and migration rollback.
- Added minimal, standard, extended, and custom installation profiles; optional
  app configurations now follow the selected component set.
- Added an interpreted Quickshell/QML installer window for supported Wayland
  sessions, with the project wallpaper and an installation progress indicator.
- Added a Quickshell settings window and `Super + I` shortcut for live
  compositor performance profile changes.

### Changed

- Made the Caelestia Quickshell integration the default UI path. The minimal
  installer no longer deploys or installs duplicate bars, launchers, and
  notification components; `--full-ui` retains those alternatives.
- Expanded installation scanning and added post-install validation.
- Stop unsupported distributions before sudo authentication or cleanup; dry-run
  remains available for compatibility checks.
- Back up existing local-bin scripts before replacing them and restore them
  during uninstall. Existing backups are no longer pruned automatically.
- Refuse to replace an existing Calm-shell source directory unless it is a
  valid Git checkout.

### Documentation

- Updated installation and requirements guides with Quickshell, migration,
  rollback, dry-run, and profile usage.
- Clarified that Caelestia's QML and UI runtime are provided by the upstream
  shell package.
