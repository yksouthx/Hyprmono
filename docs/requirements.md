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
- `caffyne-shell`: GTK/Fabric desktop shell runtime, installed from GitHub.
- `cava`: Audio visualizer for the bar music element.
- `kitty`: Terminal emulator.
- `hyprlock`: Screen locker.
- `hypridle`: Idle management daemon.
- `calm-shell`: Preferred interactive terminal shell, built by the installer from `https://github.com/yksouthx/calm-shell.git`.

### Shell and optional packages

Caffyne Shell installs through its upstream repository and uses Fabric CLI from
the AUR when available. CAVA is installed as a core package and starts only
when an MPRIS player is actively playing. Without CAVA, the bar media widget
uses a static music indicator.

Fastfetch and Yazi are optional: minimal installs neither, standard adds
Fastfetch, extended adds both, and custom asks about each independently.
Calm-shell is the default terminal shell, built and installed by the installer;
Fish is not part of the project configuration.
`--full-ui` aliases extended.

### Utilities & Drivers
- `pipewire` / `wireplumber`: Audio backend.
- `brightnessctl` / `playerctl`: Hardware controls.
- `polkit-kde-agent`: Authentication agent.
- `xdg-desktop-portal-hyprland`: Wayland portal.
- `cmake`, `ninja`, `gcc`, and `git`: Build and source prerequisites for Calm-shell.

Use `./install.sh --dry-run` to preview the system scan and deployment plan.
Before scanning or changing the system, the installer runs non-destructive
environment checks for Linux, required utilities and repository files, writable
install paths, package-manager availability, and free space. Required failures
stop the install; low disk space is reported as a warning.
The installer asks before removing each recognized component and backs up
selected files. Shared packages are preserved; package removal always
requires explicit approval. Use `hyprmono migrate --rollback <backup-directory>`
to restore a migration backup.

Use `./install.sh --wipe` to remove stale files from previous HyprMono-managed
config directories. The installer creates a timestamped backup before wiping.

### Fonts
- `ttf-jetbrains-mono-nerd`
- `ttf-firacode-nerd`
- `noto-fonts`
- `noto-fonts-emoji`

---

## ◈ Hardware Compatibility Notes

- **NVIDIA Users:** Ensure you have the latest proprietary drivers (`nvidia` or `nvidia-open-dkms`) and have enabled DRM kernel mode setting.
- **Laptops:** Battery and brightness controls are available from Caffyne Shell's quick settings applets.
- **Wallpaper formats:** The shell wallpaper (`assets/wall.webp`) needs `qt6-imageformats`, which the installer includes.
- **Multi-Monitor:** Hyprland handles multi-monitor setups natively; add a monitor rule in `config/Hyprland/hypr/hyprland.lua` to customize your layout.

## Caffyne Shell

Caffyne Shell replaces the legacy Quickshell UI. The installer clones its
upstream repository to `~/.config/caffyne-shell`, creates a Python virtual
environment, installs Python dependencies, and starts `start.sh` through
`start-shell.sh`.
