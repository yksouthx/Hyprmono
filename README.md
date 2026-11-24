<div align="center">
  <h1 align="center">H Y P R M O N O</h1>
  <p align="center">
    <b>A dark fantasy, high-contrast monochrome Hyprland environment.</b><br>
    <i>Inspired by the modularity of the HyDE Project. Designed for visual silence and lethal efficiency.</i>
  </p>
</div>

<p align="center">
  <img src="assets/wall.webp" width="800" alt="Dark Fantasy Monochrome Preview" />
</p>

---

## ◈ Palette

| Role | Color | Hex Code |
| :--- | :---: | :--- |
| **Background** | <img src="https://placehold.co/15x15/000000/000000.png" width="15" height="15" /> | `#000000` |
| **Surface** | <img src="https://placehold.co/15x15/111111/111111.png" width="15" height="15" /> | `#111111` |
| **Border** | <img src="https://placehold.co/15x15/444444/444444.png" width="15" height="15" /> | `#444444` |
| **Accent** | <img src="https://placehold.co/15x15/cccccc/cccccc.png" width="15" height="15" /> | `#CCCCCC` |
| **Foreground / Active** | <img src="https://placehold.co/15x15/ffffff/ffffff/ffffff.png" width="15" height="15" /> | `#FFFFFF` |

---

## Contents

HyprMono pairs a current Lua-configured Hyprland setup with the Caelestia
Quickshell shell. Quickshell provides the bar, launcher, dock, widgets, quick
settings, notifications, media controls, system information and wallpaper
controls in one integrated UI. Caelestia is an upstream dependency; this
repository configures and launches it rather than copying or forking its QML.

Caelestia is the sole bar, launcher, notification center, quick settings and
session menu. HyprMono configures its existing workspaces, task list, clock,
tray, audio/network/battery status, media, performance dashboard, fuzzy app
search and notification timing through the documented `shell.json`. It does
not deploy competing Waybar, Rofi, Dunst, Fuzzel, Wofi, SwayNC or Wlogout
configs/packages. The standard profile adds Fastfetch, extended also adds
Yazi, and custom asks about each optional app. A small on-demand Quickshell emoji
picker is available with `Super + Shift + E` or `hyprmono emoji`; it uses
`wl-clipboard` to copy selections.
`--full-ui` remains an alias for extended. Hyprland also has selectable compositor profiles:
`low-resource` disables blur, shadows and animations; `balanced` uses reduced
blur and shadows with animations enabled; `full-visual` keeps the default
visual effects.

---

## Requirements

| Component | Description |
| :--- | :--- |
| **Hyprland** | Current official Lua-based configuration, split into a main module and user overrides. |
| **Caelestia shell** | Lightweight Quickshell desktop shell and status UI. |
| **Hyprlock** | Clean, high-contrast lock screen with Nothing OS typography. |
| **Kitty** | GPU-accelerated terminal with a custom grayscale theme. |
| **Caelestia / Quickshell** | The single integrated bar, app launcher, notification center, quick settings, media and session UI. |
| **Calm-shell** | Preferred terminal shell, built from `yksouthx/calm-shell`. |

---

## ◈ Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/yksouthx/Hyprmono.git
cd Hyprmono
./install.sh
```

The installer checks the distribution and available hardware, scans known
duplicate shell configs under `~/.config`, `~/.local/share` and
`~/.local/bin`, and checks installed packages for reverse dependencies. It
shows each candidate and asks separately before removing it. Selected files
are backed up under `~/.local/state/Hyprmono/migration-backups/`; packages are
never removed without an explicit per-package approval. Shared packages are
preserved. `--yes` does not approve cleanup.

When launched without arguments in a Wayland session, the installer opens a
wallpaper-centered Quickshell/QML window with an animated progress line when
Quickshell and a supported terminal are available. Detailed logs and cleanup
approvals run in that terminal. Otherwise the installer falls back to the
terminal interface; `--terminal` selects it explicitly. The QML is interpreted
directly and requires no build step.

Use `--profile minimal|standard|extended|custom` to choose an installation
profile. The `custom` profile asks separately about each optional package and
configuration, defaulting to keeping each optional component out unless
selected. Use `--no-cleanup` to skip migration scanning, and `--skip-deps` to
avoid package installation.
`--rollback <backup-directory>` restores a migration backup and exits; combine
it with `--dry-run` to preview restoration.

Before installing, preview the scan and deployment plan without changing
packages or configuration:

```bash
./install.sh --dry-run
```

Existing managed configs are backed up to `~/.config-backup-<timestamp>/`
before deployment. The minimal profile is the default. Standard adds Fastfetch; `--full-ui`
selects extended and also adds Yazi. No profile installs duplicate bar,
launcher or notification components.

To remove stale files from previous HyprMono deployments, use the explicit
wipe mode. Existing managed directories are backed up before they are removed:

```bash
bash scripts/install.sh --wipe
```

Calm-shell is built from [yksouthx/calm-shell](https://github.com/yksouthx/calm-shell) and installed to `~/.local/bin/calm`. The Hyprland terminal launcher uses it by default and falls back to Kitty if it is unavailable.

When `paru` or `yay` is available, the installer offers the official
[Caelestia CLI](https://aur.archlinux.org/packages/caelestia-cli) and
[Caelestia shell](https://aur.archlinux.org/packages/caelestia-shell)
packages. The shell package supplies the upstream QML, icons, animations,
fonts, and runtime assets; HyprMono only keeps the local integration config
and wallpaper. Use `--skip-aur` to omit this step.

HyprMono follows the current Hyprland Lua configuration API. The installed entrypoint is
`~/.config/hypr/hyprland.lua`; the monochrome palette lives in
`~/.config/hypr/modules/colours.lua`, and personal changes belong in
`~/.config/hypr/custom/*.lua`, which are loaded after the defaults. This avoids mixing
the legacy native `.conf` syntax with the current official wiki format.

---

## ◈ Profiles, Migration & Recovery

Switch the Hyprland compositor between visual modes:

```bash
hyprmono profile low-resource
hyprmono profile balanced
hyprmono profile full-visual
hyprmono profile show
```

Open the graphical performance settings window with `Super + I` or
`hyprmono settings`. The current window manages compositor performance
profiles; advanced Hyprland configuration remains editable in
`~/.config/hypr/custom/`.

Review shell components that can be replaced by Quickshell without running
the installer:

```bash
hyprmono migrate --dry-run
hyprmono migrate
```

The migration command asks before each removal and never removes packages
needed by another installed package. It logs operations to
`~/.cache/Hyprmono/migration.log`. To restore a migration backup, use the exact
path printed at the end of the run:

```bash
hyprmono migrate --rollback ~/.local/state/Hyprmono/migration-backups/<timestamp>
```

Rollback restores files only when their original path is still absent; it
asks again before reinstalling packages. The installer does not uninstall
system packages during normal removal.

## ◈ Management CLI

HyprMono includes a small management CLI for installation, updates, audits, and cleanup.

```bash
hyprmono [command]
```

Available commands:
- `install`: Run the main installation script.
- `reinstall`: Fresh clone from GitHub and redeploy all configs (previous configs are backed up; `hypr/custom` is kept).
- `uninstall`: Remove all HyprMono configurations.
- `update`: Pull latest changes and sync configurations.
- `audit`: Perform a system check for dependencies.
- `migrate`: Review duplicate shell components and restore migration backups.
- `profile`: Switch `low-resource` / `balanced` / `full-visual` compositor modes.
- `settings`: Open the graphical performance settings window.
- `emoji`: Open the Quickshell emoji picker.


---

## ◈ File Tree

```text
~/.local/share/Hyprmono/
├── assets/
│   ├── fonts/
│   ├── sounds/
│   └── wall.webp
├── config/
│   ├── installer/
│   ├── hyprmono/
│   ├── hypr/
│   ├── caelestia/
│   ├── calm-shell/
│   └── ...
├── scripts/
│   ├── hyprmono.sh
│   ├── migrate.sh
│   ├── performance.sh
│   ├── profile.sh
│   ├── run-installer-terminal
│   └── install.sh
└── (installer links scripts/hyprmono.sh to ~/.local/bin/hyprmono)
```

---

## ◈ Uninstallation & Reinstallation

To safely remove the configuration:
```bash
hyprmono uninstall
```

To perform a fresh reinstall:
```bash
hyprmono reinstall
```

---

## ◈ License

This project is open-source and available under the [MIT License](LICENSE).
Copyright (c) 2025 s0uth09.
