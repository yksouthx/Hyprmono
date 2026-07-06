<div align="center">
  <h1 align="center">H Y P R M O N O</h1>
  <p align="center">
    <b>A dark fantasy, high-contrast monochrome Hyprland environment.</b><br>
    <i>Inspired by the modularity of the HyDE Project. Designed for visual silence and lethal efficiency.</i>
  </p>
</div>

<p align="center">
  <img src="assets/wallpapers/dark_fantasy_city.jpg" width="800" alt="Dark Fantasy Monochrome Preview" />
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
| **Waybar** | Minimalist status bar with custom monochrome modules. |
| **Hyprlock** | Clean, high-contrast lock screen with Nothing OS typography. |
| **Kitty** | GPU-accelerated terminal with a custom grayscale theme. |
| **Wofi / Rofi** | Unified application launchers and window switchers. |
| **Dunst / SwayNC** | Ported notification systems for seamless visual integration. |
| **Awww** | The modern, efficient wallpaper daemon (successor to swww). |
| **Wallbash** | Dynamic theme generation that injects wallpaper-derived accents. |
| **Fish** | Clean and functional shell configuration. |
| **Fastfetch** | System information tool with monochrome output. |

---

## ◈ Installation

### 1. Requirements
Ensure you have the following core packages installed (Arch Linux / Pacman):

```bash
sudo pacman -S --needed \
    hyprland hypridle hyprlock waybar kitty wofi rofi-wayland fuzzel \
    xdg-desktop-portal-hyprland xdg-user-dirs polkit-kde-agent \
    ttf-firacode-nerd ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji \
    network-manager-applet brightnessctl playerctl wireplumber pipewire-pulse \
    swaynotificationcenter dunst wlogout swaylock-effects \
    fish fastfetch awww wallbash-git
```

### 2. Setup
Clone the repository and run the automated installer:

```bash
mkdir -p ~/.local/share
cd ~/.local/share
git clone https://github.com/s0uth09/Hyprmono.git
cd Hyprmono
./hyde install
```

The installer will:
1. Check for required and optional dependencies.
2. Deploy configurations to `~/.config/`.
3. Back up existing files as `filename.bak.<timestamp>`.
4. Configure **Awww** and **Wallbash** for immediate use.

---

## ◈ Hyde Shell

HyprMono features a centralized management utility: **Hyde Shell**.

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

## ◈ Wallpaper & Theming

HyprMono uses **Awww** for wallpaper management and **Wallbash** for theme synchronization.

| Action | Keybind |
| :--- | :--- |
| **Next Wallpaper** | `Super + Alt + Right` |
| **Previous Wallpaper** | `Super + Alt + Left` |
| **Wallpaper Menu** | `Super + Shift + W` |

When a wallpaper is changed, **Wallbash** automatically updates the system colors (Kitty, Waybar, Rofi, etc.) to match the new visual profile while preserving the monochrome aesthetic.

---

## ◈ File Tree

```text
~/.local/share/Hyprmono/
├── assets/
│   ├── fonts/
│   ├── sounds/
│   └── wallpapers/
├── config/
│   ├── awww/          <-- New wallpaper config
│   ├── hypr/
│   ├── waybar/
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
