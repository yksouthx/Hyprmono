# System Requirements and Desktop Capability Inventory

This page describes what the current HyprMono installer and checked-in
configuration actually provide. It is not a hardware certification or a claim
that every optional desktop feature has been tested on every machine.

## Supported installation environment

- Linux with `pacman`; the installer is designed for Arch Linux and
  Arch-based distributions. Other distributions need a package-name and
  installation adaptation that this repository does not provide.
- Bash 4 or newer and the standard utilities checked by `install.sh`.
- A writable home directory and configuration/install paths.
- A working Wayland session and GPU driver supported by Niri.
- The installer recommends at least 2 GiB free in `$HOME`; this is a warning
  threshold, not a measured total installation size.

The project has no benchmark-validated minimum CPU, GPU model, RAM, display
resolution, or storage capacity. Use hardware and drivers known to work with
the installed Niri version. NVIDIA-specific kernel and driver configuration is
distribution- and driver-version-dependent and is not changed automatically by
this project.

## Architecture

| Responsibility | Current owner |
| --- | --- |
| Wayland compositor, outputs, workspaces, window rules, and screenshot actions | Niri |
| Bar, Dash/application menu, media and system applets, wallpaper UI | Caffyne Shell |
| Wallpaper transitions | Caffyne's wallpaper service using `awww` |
| Lock screen | `swaylock` |
| Idle behavior | Caffyne when its startup script is present; otherwise `swayidle` |
| Authentication prompts | A detected Polkit authentication agent |
| Notifications | Existing notification-bus owner; `fnott` is started as a fallback |
| Network tray | `nm-applet`, started with Caffyne when available |
| Audio backend and controls | PipeWire/WirePlumber, `wpctl`, and Caffyne |
| Spotify metadata and bar visualization | Caffyne MPRIS applet, `playerctl`, and optional-at-runtime CAVA visualization |
| App launcher | Caffyne Dash (`Mod+R`); Fuzzel is retained for emoji picking |

Niri uses ordinary named workspaces. The persistent `Music` workspace is
focused with `Mod+M`; it is not a Hyprland-style hidden special workspace.
Spotify's configured window rules place its windows on that workspace.

The Niri session starts the session-services, idle, and Caffyne startup helpers
from `config/Niri/niri/execs.kdl`. The helper scripts and user configuration are
the integration points; the repository does not install a separate desktop
shell daemon or a systemd user service for each component.

## Dependency inventory

`scripts/install.sh` installs its core Arch package list with `pacman`, unless
package installation is explicitly skipped. The list includes:

- **Compositor and session:** `niri`, `swayidle`, `swaylock`, `kitty`,
  `fuzzel`, and `fnott`.
- **Caffyne runtime and build support:** `python`, `python-pip`, `git`,
  `base-devel`, `gtk3`, `cairo`, `libgirepository`,
  `gobject-introspection`, `gtk-layer-shell`, `libdbusmenu-gtk3`,
  `cinnamon-desktop`, `gnome-bluetooth-3.0`, and `gtk-session-lock`.
- **Desktop integration:** `networkmanager`, `network-manager-applet`, `bluez`,
  `polkit-kde-agent`, `gnome-keyring`, `xdg-user-dirs`, and the GNOME, GTK,
  and wlroots XDG portal packages.
- **Media, display, and capture utilities:** `playerctl`, `cava`,
  `brightnessctl`, `upower`, `wireplumber`, `pipewire-pulse`, `wl-clipboard`,
  `wf-recorder`, `awww`, and `matugen`.
- **Fonts:** `ttf-firacode-nerd`, `ttf-jetbrains-mono-nerd`, `noto-fonts`, and
  `noto-fonts-emoji`.
Caffyne itself is cloned from its upstream Git repository into
`$XDG_CONFIG_HOME/caffyne-shell` (normally `~/.config/caffyne-shell`). The
installer creates a Python virtual environment there, installs the upstream
Python requirements, and applies HyprMono's overrides. This is a source-based
setup, not an Arch package named `caffyne-shell`.

Caffyne's Fabric IPC CLI is an AUR dependency (`fabric-cli-git`). The installer
uses `yay` or `paru` when available. If neither helper is available, or AUR
installation is skipped, Fabric IPC may be unavailable and shell bindings that
depend on it will not work until it is installed separately.

The following are optional rather than core desktop requirements:

- `fastfetch` and `yazi` are selected by the install profile.
- Calm-shell is offered separately. Its setup may require `cmake`, `ninja`,
  and `gcc`; it is not required for Niri or Caffyne.
- Caffyne setup and configuration deployment can each be skipped.
- Login-manager selection and configuration remain host-managed.

## Capability and known-gap audit

| Capability | Repository status and boundary |
| --- | --- |
| Bar, application menu, media, network, audio, brightness, and energy applets | Provided by Caffyne's configured bar and Dash. Hardware availability and upstream applet behavior still depend on the host. |
| Spotify music workspace | Configured as a named Niri workspace with a `Mod+M` binding and Spotify window rules. |
| Wallpaper | HyprMono copies `assets/wall.webp` into Caffyne's wallpaper directory and selects it in the shell config. Caffyne's wallpaper service uses `awww` and starts its daemon when needed. |
| Locking and idle | `swaylock` and lock helper are configured. `start-idle.sh` uses Caffyne when its startup script exists; otherwise it runs `swayidle`. A present but failing Caffyne startup script does not trigger that fallback. |
| Display configuration | Niri detects outputs and supports the checked-in monitor configuration. No `kanshi` display-profile service is installed or configured. |
| Night light | No `wlsunset` dependency or night-light startup configuration is included. |
| Authentication | `start-session-services.sh` starts the first available Polkit agent from its supported paths. The actual agent and policy integration depend on installed host packages. |
| Notifications | The startup helper avoids starting `fnott` when another process owns `org.freedesktop.Notifications`. Caffyne or another existing owner can therefore remain authoritative. |
| Clipboard | `wl-clipboard` is installed and used by the emoji picker. A clipboard-history manager such as `cliphist` is not installed or configured. |
| Screenshots | Niri's built-in screenshot actions are bound to Print, Ctrl+Print, and Alt+Print and save under `~/Pictures/NiriMono`. `grim` and `slurp` are not required by these bindings. |
| Network and Bluetooth | NetworkManager, its tray applet, and BlueZ are included. `nm-applet` is launched when present; device support and Bluetooth service state are host-dependent. |
| Power and battery | `upower` is included for battery information. `power-profiles-daemon` is not installed by this project, so profile switching is not guaranteed. |
| Rofi and Waybar migration | Caffyne replaces their menu/bar roles in the configured setup. Migration candidates are backed up and removed only with explicit per-item confirmation; existing packages/configurations are not silently removed. |

Do not treat an item marked absent or host-dependent as verified functionality.
Add and validate such components on the target machine before making them part
of session startup.

## Installation, verification, and rollback

1. Review the repository changes and run `./install.sh --dry-run` to inspect
   the environment checks and planned package/configuration work.
2. Run the installer interactively on the target Arch-based host. Review each
   prompt; do not use `--wipe` unless replacing existing managed configs is
   intended. Wipe mode creates a timestamped backup first.
3. Log into the Niri session and verify the shell, notifications, Polkit
   prompts, network tray, audio, locking, wallpaper, screenshots, and the
   hardware-specific controls in use.
4. Run `hyprmono diagnostics` for a read-only snapshot of relevant tools,
   packages, processes, services, and session variables. Run
   `hyprmono audit` for its narrower core executable check.
5. On the running desktop, use `hyprmono performance --seconds 10` to sample
   Niri and Caffyne CPU and resident memory. `--record` saves a host-local
   baseline and `--compare` compares against it. These measurements do not
   cover GPU use, system-wide memory, or startup latency.

The installer backs up managed configuration before replacing it. The
migration tool also backs up selected Rofi/Waybar files and requires explicit
confirmation for each removal; use `hyprmono migrate --rollback <backup-dir>`
to restore a migration backup. Package changes are not a performance result:
measure on the target host before and after any change.
