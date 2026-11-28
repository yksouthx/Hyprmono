# Changelog

Notable changes to HyprMono are documented here.

## Unreleased

### Changed

- Replaced Quickshell with Caffyne Shell and rebuilt the bar's active-window,
  process/CPU, RAM, media/CAVA, wallpaper, quick-settings and emoji integrations
  on Fabric/GTK.

### Fixed

- The Quickshell wallpaper now loads from inside the shell root instead of
  resolving to a blackholed URL outside it.
- Install smoke tests now treat Quickshell's Qt build-version notice as a
  warning, while still rolling back on QML startup errors.
- Settings window: a `Process` nested inside another `Process` prevented the
  window from loading; the performance sampler is now a sibling object.
- `Super + L` and `Super + R` no longer depend on Caelestia: lock falls back to
  hyprlock and the launcher falls back to fuzzel/wofi/rofi (new
  `lock-screen.sh` and `launch-menu.sh`).
- The project shell now draws the wallpaper, runs one bar per monitor, and the
  clock follows the system minute instead of polling.
- A polkit authentication agent, fnott and nm-applet are started with the
  session (`start-session-services.sh`).
- `~/.local/bin` is added to the PATH Hyprland launches programs with, and the
  emoji picker bind uses the absolute path.
- Smart-gaps window rules now come with the matching workspace rules.
- Lua modules use idiomatic dotted `require` paths.
- Installer: the Calm-shell build tools install no longer hangs on an
  invisible confirmation prompt; a failing QML installer falls back to the
  terminal installer; the terminal installer window stays open and its real
  exit status is reported; prompts survive end-of-input; the sudo keep-alive is
  always stopped; the installer window sources are no longer deployed into
  `~/.config`.
- Uninstall removes only directories the installer recorded as deployed
  (never unrelated fish/waybar/rofi configs) and restores the original backup.
- Migration no longer claims the project shell replaces launchers,
  notification daemons or wallpaper tools, and never offers to remove them.
- `hyprmono` runs repository scripts that are not executable; `audit` checks
  the real requirements and exits non-zero on failure.
- `watch-quality.sh` detects QML syntax errors correctly, uses a meaningful
  shellcheck severity, and formats only when asked.
- `launch_first_available.sh` no longer uses `eval`.
- `start-caelestia.sh` is renamed `start-shell.sh` (it starts the project
  shell first); the old copy is removed on install.
- Kitty config: removed an inline comment kitty does not support.

### Added

- Added `./test_install.sh` to test a minimal deployment in the active
  Hyprland/Quickshell session and automatically restore pre-test files if
  either smoke check fails. It tolerates Qt build-version notices and saves a
  private log on the Desktop.
- Reusable Quickshell easing animation for the media pill and animated
  media/quick-settings panel entrances.
- System tray context menus in the bar (right-click; left-click for menu-only
  items; middle-click and scroll are forwarded to the tray item).
- fuzzel (launcher) and fnott (notification daemon) with monochrome configs,
  installed in every profile; fnott starts only when the project shell is in
  use and no other notification daemon is running. `nm-applet` is installed
  and started for the tray.
- Tests for the Hyprland Lua config, helper scripts, profile command,
  migration, uninstall, QML syntax and repository hygiene; a GitHub Actions
  workflow runs them.

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

- Map the reorganized Hyprland and Quickshell source directories to their
  conventional config destinations, deploy Caelestia separately, and stop if
  required package installation fails.
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
