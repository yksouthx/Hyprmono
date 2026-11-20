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

HyprMono is built on the principle of **visual silence**. By stripping away color, the interface becomes a neutral canvas that prioritizes content and focus. Every component—from the status bar to the notification daemon—has been meticulously audited and modularized to ensure a perfect grayscale aesthetic.

With the latest update, HyprMono now supports **dynamic monochrome theming** via **Wallbash**, allowing your environment to subtly adapt to your chosen wallpaper while maintaining its lethal monochrome identity.

---

## Requirements

| Component | Description |
| :--- | :--- |
| **Hyprland** | Native `.conf` based tiling compositor configuration, heavily modularized. |
| **Caelestia shell** | Lightweight Quickshell desktop shell and status UI. |
| **Hyprlock** | Clean, high-contrast lock screen with Nothing OS typography. |
| **Kitty** | GPU-accelerated terminal with a custom grayscale theme. |
| **Fuzzel** | Lightweight application launcher and emoji picker. |
| **SwayNC** | Notification daemon for the default profile. |
| **Hyprpaper** | A lightweight wallpaper daemon for Hyprland. |
| **Waybar / Wofi / Rofi** | Optional full-UI components, not installed by the lightweight default. |
| **Calm-shell** | Preferred terminal shell, built from `yksouthx/calm-shell`. |

---

## ◈ Installation

### 1. Requirements
Ensure you have the following core packages installed (Arch Linux / Pacman):

```bash
sudo pacman -S --needed \
    hyprland hypridle hyprlock kitty fuzzel \
    xdg-desktop-portal-hyprland xdg-user-dirs polkit-kde-agent \
    ttf-firacode-nerd ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji \
    network-manager-applet brightnessctl playerctl wireplumber pipewire-pulse \
    swaynotificationcenter
```

### 2. Setup
Clone the repository and run the automated installer:

```bash
mkdir -p ~/.local/share
cd ~/.local/share
git clone https://github.com/yksouthx/Hyprmono.git
cd Hyprmono
bash scripts/install.sh
```

The installer will:
1. Check for required and optional dependencies.
2. Deploy configurations to `~/.config/`.
3. Back up existing managed directories to `~/.config-backup-<timestamp>/`.
4. Use the lightweight profile by default; pass `--full-ui` to install optional Waybar/Wofi/Rofi and utility packages.

To remove stale files from previous HyprMono deployments, use the explicit wipe mode. Existing managed directories are backed up before they are removed:

```bash
bash scripts/install.sh --wipe
```

Calm-shell is built from [yksouthx/calm-shell](https://github.com/yksouthx/calm-shell) and installed to `~/.local/bin/calm`. The Hyprland terminal launcher prefers it and falls back to Kitty if it is unavailable.

Caelestia is optional because it is distributed separately from this repository. Install the Caelestia shell using the [official installation instructions](https://github.com/caelestia-dots/shell#installation). Once `caelestia` is available, HyprMono starts it automatically with `caelestia shell -d`.

---

## ◈ Management CLI

HyprMono includes a small management CLI for installation, updates, audits, and cleanup.

```bash
hyde [command]
```

Available commands:
- `install`: Run the main installation script.
- `reinstall`: Completely wipe local configs and reinstall from GitHub.
- `uninstall`: Remove all HyprMono configurations.
- `update`: Pull latest changes and sync configurations.
- `audit`: Perform a system check for dependencies.


---

## ◈ File Tree

```text
~/.local/share/Hyprmono/
├── assets/
│   ├── fonts/
│   ├── sounds/
│   └── wall.webp
├── config/
│   ├── hypr/
│   ├── caelestia/
│   ├── calm-shell/
│   └── ...
├── scripts/
│   ├── change_wallpaper.sh
│   ├── hyde-shell.sh
│   └── install.sh
└── hyde -> scripts/hyde-shell.sh
```

---

## ◈ Uninstallation & Reinstallation

To safely remove the configuration:
```bash
hyde uninstall
```

To perform a fresh reinstall:
```bash
hyde reinstall
```

---

## ◈ License

This project is open-source and available under the [MIT License](LICENSE).
Copyright (c) 2025 s0uth09.
