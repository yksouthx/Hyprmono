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

HyprMono pairs a current Lua-configured Hyprland setup with
[Caffyne Shell](https://github.com/caffyne-org/caffyne-shell), a GTK/Python
desktop shell built on Fabric. Caffyne provides the bar, applets, control hub,
workspace integration and desktop theming. Its upstream repository is cloned
into `~/.config/caffyne-shell` by the installer and launched by
`start-shell.sh`. HyprMono applies a fresh floating-bar theme and replaces the
bar's media widget with a CAVA-backed 12-band spectrum while media is playing.
The Caffyne bar also restores active-window text, CPU/process status, RAM
percentage and the HyprMono wallpaper.
The bar uses floating capsule/pill surfaces, rounded widgets and soft shadows.

The standard profile adds Fastfetch, extended also adds Yazi, and custom asks
about each optional app. Caffyne's launcher is available with
`Super + Shift + E` or `hyprmono emoji`. `--full-ui` remains an alias for extended.
Hyprland also has selectable compositor profiles:
`low-resource` disables blur, shadows and animations; `balanced` uses reduced
blur and shadows with animations enabled; `full-visual` keeps the default
visual effects.

---

## Requirements

| Component | Description |
| :--- | :--- |
| **Hyprland** | Current official Lua-based configuration, split into a main module and user overrides. |
| **Caffyne Shell** | GTK/Fabric desktop shell and applet runtime. |
| **Hyprlock** | Clean, high-contrast lock screen with Nothing OS typography. |
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
duplicate bars and shell frameworks (Waybar, Eww, AGS, HyprPanel) and old
HyprMono helpers under `~/.config`, `~/.local/share` and `~/.local/bin`, and
checks installed packages for reverse dependencies. Launchers, notification
daemons, wallpaper tools, lock screens and tray applets are never offered for
removal, because the HyprMono bar does not replace them. It shows each
candidate and asks separately before removing it. Selected files
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

To test a minimal deployment in an active Hyprland session without installing
packages or cleaning/migrating other components, run:

```bash
./test_install.sh
```

It reloads Hyprland, checks for configuration errors, and starts Caffyne Shell for
a short smoke test. If the installer, Hyprland, or Caffyne Shell reports an error,
the script restores the files that existed before the test and reloads the
previous Hyprland configuration. A successful test leaves HyprMono installed.
Each run saves its full output to a unique, owner-only
`~/Desktop/hyprmono-test-install-*.log` file.

The smoke test rolls back on startup errors, missing Python resources, or an
unexpected process exit.

Existing managed configs are backed up to `~/.config-backup-<timestamp>/`
before deployment. The minimal profile is the default. Standard adds Fastfetch; `--full-ui`
selects extended and also adds Yazi. No profile installs a duplicate bar.

Every profile installs two small companions for the HyprMono shell, themed to
match it (`config/fuzzel/`, `config/fnott/`):

- **fuzzel** is the application launcher (`Super + R`).
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

Calm-shell is built from [yksouthx/calm-shell](https://github.com/yksouthx/calm-shell) and installed to `~/.local/bin/calm`. The Hyprland terminal launcher uses it by default and falls back to Kitty if it is unavailable.

When `paru` or `yay` is available, the installer offers
[`fabric-cli-git`](https://aur.archlinux.org/packages/fabric-cli-git), required
for Caffyne Shell IPC. Use `--skip-aur` to omit this step.

Repository configuration is grouped by application: Hyprland sources are in
`config/Hyprland/hypr/`, Caffyne design assets are in `assets/caffyne-shell/`,
and companion app configs are in `config/`. Caffyne itself is cloned to
`~/.config/caffyne-shell/`.

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

Open Caffyne Shell quick settings with `Super + I` or `hyprmono settings`.
The Visual Profile control cycles low-resource, balanced and full-visual modes
and reloads Hyprland. Advanced configuration remains editable in
`~/.config/hypr/custom/`.

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
- `reinstall`: Fresh clone from GitHub and redeploy all configs (previous configs are backed up; `hypr/custom` is kept).
- `uninstall`: Remove all HyprMono configurations.
- `update`: Pull latest changes and sync configurations.
- `audit`: Perform a system check for dependencies.
- `migrate`: Review duplicate bar/shell components and restore migration backups.
- `profile`: Switch `low-resource` / `balanced` / `full-visual` compositor modes.
- `settings`: Toggle the Caffyne Shell settings applet.
- `emoji`: Pick and copy an emoji with Fuzzel.


---

## ◈ File Tree

```text
~/.local/share/Hyprmono/
├── assets/
│   ├── fonts/
│   ├── caffyne-shell/
│   └── wall.webp
├── config/
│   ├── hypr/
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
