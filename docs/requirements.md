# System Requirements for HyprMono

To ensure a smooth and responsive experience with the HyprMono configuration, we recommend the following minimum and recommended system specifications.

## ◈ Minimum Requirements

These specifications are intended for a functional, albeit basic, experience.

| Component | Minimum Specification |
| :--- | :--- |
| **CPU** | Dual-core 2.0GHz (x86_64) |
| **RAM** | 4 GB DDR4 |
| **GPU** | Integrated Graphics (Intel HD 4000+ / AMD Radeon Vega 3+) |
| **Storage** | 2 GB available space (excluding OS) |
| **Display** | 1280x720 resolution |
| **OS** | Arch Linux (Minimal Install) |

## ◈ Recommended Specifications

For optimal performance, smooth animations, and heavy multitasking.

| Component | Recommended Specification |
| :--- | :--- |
| **CPU** | Quad-core 3.0GHz+ (Ryzen 5 / Core i5 or better) |
| **RAM** | 8 GB+ DDR4/DDR5 |
| **GPU** | Dedicated GPU (NVIDIA GTX 10-series+ / AMD RX 500-series+) |
| **Storage** | SSD with 5 GB+ available space |
| **Display** | 1920x1080 or 4K resolution (144Hz+ supported) |
| **OS** | Arch Linux / EndeavourOS / CachyOS |

## ◈ Software Dependencies

The installation script (`install.sh`) will attempt to install these automatically via `pacman`.

### Core Packages
- `hyprland`: The tiling compositor.
- `caelestia shell`: Lightweight desktop shell and status UI, installed separately.
- `kitty`: Terminal emulator.
- `fuzzel`: Lightweight application launcher.
- `swaynotificationcenter`: Notification daemon.
- `hyprpaper`: Wallpaper utility.
- `hyprlock`: Screen locker.
- `hypridle`: Idle management daemon.
- `calm-shell`: Preferred interactive terminal shell, built by the installer from `https://github.com/yksouthx/calm-shell.git`.

### AUR packages

If `paru` or `yay` is installed, the installer uses it for `caelestia-cli` and `caelestia-shell`. The official shell package supplies Caelestia's QML, icons, animations, fonts, and runtime assets. Pass `--skip-aur` to skip AUR installation.

Waybar, Wofi, Rofi, Dunst, Swaylock, Fish, and Fastfetch are optional full-UI packages. Pass `--full-ui` to the installer when those components are wanted; the default profile avoids installing or autostarting duplicate desktop-shell components.

### Utilities & Drivers
- `pipewire` / `wireplumber`: Audio backend.
- `brightnessctl` / `playerctl`: Hardware controls.
- `network-manager-applet`: Network tray icon.
- `polkit-kde-agent`: Authentication agent.
- `xdg-desktop-portal-hyprland`: Wayland portal.
- `cmake`, `ninja`, `gcc`, and `git`: Build and source prerequisites for Calm-shell.

Use `install.sh --wipe` to remove stale files from previous HyprMono-managed config directories. The installer creates a timestamped backup before wiping.

### Fonts
- `ttf-jetbrains-mono-nerd`
- `ttf-firacode-nerd`
- `noto-fonts`
- `noto-fonts-emoji`

---

## ◈ Hardware Compatibility Notes

- **NVIDIA Users:** Ensure you have the latest proprietary drivers (`nvidia` or `nvidia-open-dkms`) and have enabled DRM kernel mode setting.
- **Laptops:** Battery and backlight modules in Waybar are pre-configured but may require specific `sysfs` paths depending on your hardware.
- **Multi-Monitor:** Hyprland handles multi-monitor setups natively; check `config/hypr/hyprland/monitors.conf` to customize your layout.

## Optional Caelestia shell

HyprMono includes a guarded startup hook for the [Caelestia shell](https://github.com/caelestia-dots/shell). Install the shell and its CLI using the official Arch/AUR or manual instructions. When `caelestia` is available, Hyprland starts it with `caelestia shell -d`; otherwise the hook exits quietly and the regular HyprMono desktop continues to start.
