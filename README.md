<div align="center">
  <h1 align="center">H Y P R M O N O</h1>
  <p align="center">
    <b>A dark fantasy, high-contrast monochrome Niri environment.</b><br>
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

HyprMono pairs a modular Niri setup with
[Caffyne Shell](https://github.com/caffyne-org/caffyne-shell), a GTK/Python
desktop shell built on Fabric. Caffyne provides the bar, applets, control hub,
workspace integration and desktop theming. Its upstream repository is cloned
into `~/.config/caffyne-shell` by the installer and launched by
`start-shell.sh`. HyprMono applies a fresh floating-bar theme and replaces the
bar's media widget with a CAVA-backed 12-band spectrum while media is playing.
The Caffyne bar also restores active-window text, CPU/process status, RAM
percentage and the HyprMono wallpaper.
The bar uses floating capsule/pill surfaces, rounded widgets, soft shadows and
a subtle top-lit gloss. The Caffyne Dash uses a dark translucent panel and
rounded app tiles to match; Fuzzel remains the emoji picker's menu.

The standard profile adds Fastfetch, extended also adds Yazi, and custom asks
about each optional app. Open Caffyne's Dash app menu with `Super + R`; use
`Super + Shift + E` or `hyprmono emoji` for the emoji picker.
`--full-ui` remains an alias for extended.

---

## Requirements

| Component | Description |
| :--- | :--- |
| **Niri** | Modular KDL configuration with a user override file. |
| **Caffyne Shell** | GTK/Fabric desktop shell and applet runtime. |
| **Swaylock** | High-contrast session lock screen. |
| **Kitty** | GPU-accelerated terminal with a custom grayscale theme. |
| **Calm-shell** | Preferred terminal shell, built from `yksouthx/calm-shell`. |

---

## ◈ Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/yksouthx/Hyprmono.git
cd Hyprmono
./install.sh
```

The installer checks the distribution and available hardware, scans for known
duplicate bars and shell frameworks (Waybar, Eww, AGS, HyprPanel), the
replaced Rofi app menu, and old HyprMono helpers under `~/.config`,
`~/.local/share` and `~/.local/bin`, and checks installed packages for reverse
dependencies. Notification daemons, wallpaper tools, lock screens, and tray
applets are never offered for removal. Each candidate is shown and requires
separate approval before removal. Selected files
are backed up under `~/.local/state/Hyprmono/migration-backups/`; packages are
never removed without an explicit per-package approval. Shared packages are
preserved. `--yes` does not approve cleanup.

When launched with `--terminal`, the installer uses the text interface explicitly.
Wayland setup and package prompts are handled in the terminal; Caffyne Shell is
cloned and configured after package setup.

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

To test a minimal deployment in an active Niri session without installing
packages or cleaning/migrating other components, run:

```bash
./test_install.sh
```

It reloads Niri with the deployed configuration and starts Caffyne Shell for a
short smoke test. If Niri or Caffyne Shell reports an error, the script restores
the files that existed before the test and reloads the previous Niri
configuration. A successful test leaves HyprMono installed.
Each run saves its full output to a unique, owner-only
`~/Desktop/hyprmono-test-install-*.log` file.

The smoke test rolls back on startup errors, missing Python resources, or an
unexpected process exit.

Existing managed configs are backed up to `~/.config-backup-<timestamp>/`
before deployment. The minimal profile is the default. Standard adds Fastfetch; `--full-ui`
selects extended and also adds Yazi. No profile installs a duplicate bar.
On upgrades, a previous HyprMono-managed `~/.config/hypr` is backed up and
removed; unrelated, untracked configs are left alone.

Every profile installs a notification daemon and a small emoji-picker
companion for the HyprMono shell (`config/fnott/`, `config/fuzzel/`):

- **Caffyne Dash** is the app menu and shell control surface (`Super + R`).
- **fuzzel** is used by the emoji picker (`Super + Shift + E`).
- **fnott** is the notification daemon, started with the session when the
  HyprMono shell is installed and no other daemon already owns
  `org.freedesktop.Notifications`.

The bar's system tray supports context menus: right-click an icon for its menu
(left-click for icons that only offer a menu), middle-click for the secondary
action, and scroll over an icon for its scroll action. `nm-applet` is started
with the session so Wi-Fi can be managed from the tray.

To remove stale files from previous HyprMono deployments, use the explicit
wipe mode. Existing managed directories are backed up before they are removed:

```bash
bash scripts/install.sh --wipe
```

Calm-shell is built from [yksouthx/calm-shell](https://github.com/yksouthx/calm-shell) and installed to `~/.local/bin/calm`. The Niri terminal launcher uses it by default and falls back to Kitty if it is unavailable.

When `paru` or `yay` is available, the installer offers
[`fabric-cli-git`](https://aur.archlinux.org/packages/fabric-cli-git), required
for Caffyne Shell IPC. Use `--skip-aur` to omit this step.

Repository configuration is grouped by application: Niri sources are in
`config/Niri/niri/`,
Caffyne design assets are in `assets/caffyne-shell/`,
and companion app configs are in `config/`. Caffyne itself is cloned to
`~/.config/caffyne-shell/`.

The installer can also install a custom monochrome SDDM login screen from
`assets/sddm/hyprmono/`, enable `sddm.service`, and use the Wayland greeter
backend. Existing SDDM theme and configuration files are preserved for
uninstallation. The package and system integration are skipped with
`--skip-deps` or `--skip-pkgs`.

The Niri setup is named **NiriMono** and is split into focused files, with
`config.kdl` as the entrypoint: `environment.kdl`, `input.kdl`, `layout.kdl`,
`monitors.kdl`, `rules.kdl`, `workspaces.kdl`, `animations.kdl`, `execs.kdl`,
`keybinds.kdl`, and `custom.kdl`. It uses the system's XCursor theme.
Screenshots are saved to
`~/Pictures/NiriMono/`.

---

## ◈ Profiles, Migration & Recovery

Open Caffyne Shell quick settings with `Super + I` or `hyprmono settings`.
Niri settings can be customized in `~/.config/niri/custom.kdl`.

Review shell components that can be replaced by Caffyne Shell without running
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
- `reinstall`: Fresh clone from GitHub and redeploy all configs (previous configs are backed up; `niri/custom.kdl` is kept).
- `uninstall`: Remove all HyprMono configurations.
- `update`: Pull latest changes and sync configurations.
- `audit`: Perform a system check for dependencies.
- `diagnostics`: Print a read-only snapshot of desktop configuration, packages, processes, and user services.
- `migrate`: Review duplicate bar/shell components and restore migration backups.
- `settings`: Toggle the Caffyne Shell settings applet.
- `emoji`: Pick and copy an emoji with Fuzzel.

Run `hyprmono diagnostics` from the target desktop session when collecting
system-audit information. It reports only selected session variables and
process names (not command-line arguments or the full environment), and does
not install, stop, or modify anything. Package and user-service details depend
on the available package manager and active user session.


---

## ◈ File Tree

```text
~/.local/share/Hyprmono/
├── assets/
│   ├── fonts/
│   ├── caffyne-shell/
│   └── wall.webp
├── config/
│   ├── Niri/
│   ├── calm-shell/
│   └── ...
├── scripts/
│   ├── hyprmono.sh
│   ├── migrate.sh
│   ├── performance.sh
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
