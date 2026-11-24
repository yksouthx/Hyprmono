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
- Added a project-owned three-section Quickshell bar with workspace and active
  window indicators, clock, system load, tray, and quick audio settings.
- Added an MPRIS media pill and dashboard with artwork, track details, seeking,
  playback, shuffle, repeat, and volume controls; CAVA visualization is opt-in.
- Added installer environment checks for platform, utilities, repository files,
  writable targets, package manager, and available disk space.
- Added `scripts/watch-quality.sh` to run project checks and tests continuously
  while source files change, with optional automatic shell formatting.

### Changed

- Read bar RAM and load metrics asynchronously from `/proc` instead of spawning
  a recurring shell process.
- Group repository-owned Hyprland and Quickshell sources under descriptive
  app directories while preserving their installed config paths.
- Keep the repository quality watcher out of the installed runtime scripts.
- Remove the redundant `fuzzel-emojis.sh` forwarder; `hyprmono emoji` remains
  the supported entry point.
- Made the project-owned Quickshell UI the default startup path and retained
  Caelestia as a compatibility fallback.
- Start Hypridle with the project-owned shell, which does not manage idle
  locking; Caelestia continues to use its own idle monitor.
- Expanded installation scanning and added post-install validation.
- Stop unsupported distributions before sudo authentication or cleanup; dry-run
  remains available for compatibility checks.
- Back up existing local-bin scripts before replacing them and restore them
  during uninstall. Existing backups are no longer pruned automatically.
- Refuse to replace an existing Calm-shell source directory unless it is a
  valid Git checkout.

### Documentation

- Removed duplicate top-level policy/contribution documents, an outdated
  duplicate README, stale repository history/audit notes, and the empty sounds
  placeholder.
- Documented the modular bar, optional CAVA setup, and GPL-3.0 Lyne Dots
  visual reference; no Lyne Dots code or assets were copied.
- Updated installation and requirements guides with Quickshell, migration,
  rollback, dry-run, and profile usage.
