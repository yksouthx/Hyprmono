#!/usr/bin/env bash

# H Y P R M O N O - The Definitive Installer
# Version: 4.5
# Purpose: Robust, path-aware installation for the HyprMono environment.

set -Eeuo pipefail
shopt -s nullglob

# Report exactly what failed (command + line number) instead of silently
# exiting when set -e kills the script on a non-zero return.
trap 'err "Failed (exit $?) at line $LINENO: $BASH_COMMAND"' ERR

# Single EXIT handler: stop the sudo keep-alive, report the exit status to a
# parent launcher (HYPRMONO_STATUS_FILE) and optionally keep the terminal open
# (HYPRMONO_PAUSE_ON_EXIT) so errors can be read.
on_exit() {
    local status=$?
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
    if [[ -n "${HYPRMONO_STATUS_FILE:-}" ]]; then
        printf '%s\n' "$status" > "$HYPRMONO_STATUS_FILE" 2>/dev/null || true
    fi
    if [[ "${HYPRMONO_PAUSE_ON_EXIT:-0}" == 1 && -t 0 ]]; then
        printf '\nInstaller finished with exit status %s. Press Enter to close this window. ' "$status"
        read -r _ || true
    fi
}
trap on_exit EXIT

# Terminal Title
printf "\033]0;Hyprmono Installer\a"

# --- Absolute Path Resolution ---
REAL_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPTS_DIR=$(dirname "$REAL_PATH")
SELF_NAME=$(basename "$REAL_PATH")

# --- Configuration ---
readonly PROJECT="Hyprmono"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="$HOME/.local/bin"
TARGET_REPO_DIR="$HOME/.local/share/Hyprmono"
REPO_URL="https://github.com/yksouthx/Hyprmono"

# Log location is intentionally independent of the repo path — we need
# somewhere to write to even if repo resolution itself fails.
LOGDIR="$HOME/.cache/Hyprmono"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/install.log"

# --- Flags (set via CLI args in main()) ---
NO_MIGRATE=0
NO_CLEANUP=0
SKIP_DEPS=0
SKIP_PKGS=0
SKIP_AUR=0
ASSUME_YES=0
WIPE_CONFIGS=0
INSTALL_PROFILE="minimal"
SELECTED_OPTIONAL_PACKAGES=()
DRY_RUN=0
TERMINAL_MODE=0
ROLLBACK_DIR=""

# --- Colors ---
RESET="\e[0m"

BOLD="\e[1m"
DIM="\e[2m"

WHITE="\e[38;5;255m"
GRAY="\e[38;5;244m"

ACCENT="\e[38;5;81m"
SUCCESS="\e[38;5;114m"
WARNING="\e[38;5;221m"
ERROR="\e[38;5;203m"

WIDTH=$(tput cols 2>/dev/null || echo 80)

# --- Helpers ---
log() { printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$*" >> "$LOGFILE"; }

title() {
    echo
    printf "${GRAY}"
    printf '━%.0s' $(seq 1 "$WIDTH")
    printf "\n"
    printf "${BOLD}${WHITE}%s${RESET}\n" "$1"
    printf "${GRAY}"
    printf '━%.0s' $(seq 1 "$WIDTH")
    printf "${RESET}\n"
}

ok()   { printf "${SUCCESS}[ OK ]${RESET} %s\n" "$1"; log "[ OK ] $1"; }
warn() { printf "${WARNING}[WARN]${RESET} %s\n" "$1"; log "[WARN] $1"; }
err()  { printf "${ERROR}[FAIL]${RESET} %s\n" "$1"; log "[FAIL] $1"; }
info() { printf "${ACCENT}[INFO]${RESET} %s\n" "$1"; log "[INFO] $1"; }

has() { command -v "$1" >/dev/null 2>&1; }

ask() {
    local prompt="$1"
    local default="${2:-y}"
    local answer=""

    if [[ "$ASSUME_YES" -eq 1 ]]; then
        info "Auto-confirming (--yes): $prompt -> ${default}"
        [[ "$default" == y ]]
        return
    fi

    echo
    printf "${GRAY}"
    printf '─%.0s' $(seq 1 46)
    printf "${RESET}\n"
    printf "${WHITE}%s${RESET}\n\n" "$prompt"
    if [[ "$default" == y ]]; then
        printf "${ACCENT}[Y/n] ${RESET}"
    else
        printf "${ACCENT}[y/N] ${RESET}"
    fi
    read -r answer || answer=""
    [[ -z "$answer" ]] && answer="$default"
    [[ "$answer" =~ ^[Yy]$ ]]
}

usage() {
    cat <<'EOF'
Usage: ./install.sh [OPTIONS]

Install HyprMono; uses Caffyne Shell for the desktop UI.

Options:
  --terminal          Use the terminal installer explicitly
  --dry-run           Preview migration and deployment without changing the system
  --profile PROFILE   Choose minimal, standard, extended, or custom
  --minimal           Alias for --profile minimal
  --full-ui           Alias for --profile extended
  --no-cleanup        Skip scanning/removing existing desktop components
  --skip-deps         Skip system and AUR dependency installation
  --skip-pkgs         Skip system package installation
  --skip-aur          Skip AUR package installation
  --rollback DIR      Restore a migration backup and exit
  --no-migrate        Do not offer to move the repository into its standard location
  --wipe              Back up and remove existing managed configs before deployment
  --yes               Automatically accept installer prompts (not cleanup approvals)
  --help              Show this help
EOF
}

# Spinner for long-running background commands.
# Usage: some_long_command & spinner $! "Doing thing..."
spinner() {
    local pid=$1
    local label="${2:-Working...}"
    local delay=.08
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 "$pid" 2>/dev/null; do
        for i in $(seq 0 9); do
            printf "\r${ACCENT}%s${RESET} %s" "${spin:$i:1}" "$label"
            sleep "$delay"
        done
    done
    printf "\r%*s\r" "$((${#label}+2))" ""
}

# Simple progress bar. Usage: progress <current> <total>
progress() {
    local current=$1 total=$2 width=40
    local filled=$(( current * width / total ))
    printf "\r["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=filled; i<width; i++)); do printf "░"; done
    printf "] %d%%" "$(( 100 * current / total ))"
    if (( current == total )); then
        printf "\n"
    fi
}

# --- Sudo keep-alive ---
keep_sudo_alive() {
    while true; do
        sudo -v
        sleep 60
    done &
    SUDO_KEEPALIVE_PID=$!
}

is_valid_repo() { [[ -d "$1/config" ]]; }

resolve_repo_root() {
    if [[ -n "${HYPRMONO_REPO:-}" ]]; then
        if is_valid_repo "$HYPRMONO_REPO"; then
            printf '%s\n' "$(cd "$HYPRMONO_REPO" && pwd)"
            return 0
        fi
        err "HYPRMONO_REPO=$HYPRMONO_REPO has no config/ directory — ignoring override" >&2
    fi

    if is_valid_repo "$SCRIPTS_DIR"; then
        printf '%s\n' "$SCRIPTS_DIR"
        return 0
    fi

    local script_parent
    script_parent=$(cd "$SCRIPTS_DIR/.." && pwd)
    if is_valid_repo "$script_parent"; then
        printf '%s\n' "$script_parent"
        return 0
    fi

    if is_valid_repo "$TARGET_REPO_DIR"; then
        printf '%s\n' "$TARGET_REPO_DIR"
        return 0
    fi

    local candidates=(
        "$HOME/Hyprmono" "$HOME/HyprMono" "$HOME/hyprmono"
        "$HOME/dotfiles/Hyprmono" "$HOME/repos/Hyprmono"
        "$HOME/git/Hyprmono" "$HOME/Projects/Hyprmono"
        "$HOME/Downloads/Hyprmono"
        "$(pwd)"
    )
    local c
    for c in "${candidates[@]}"; do
        is_valid_repo "$c" && { printf '%s\n' "$c"; return 0; }
    done

    local found
    found=$(find "$HOME" -maxdepth 4 -name '.*' -prune -o -type d -iname "hyprmono" -print 2>/dev/null | while read -r d; do
        is_valid_repo "$d" && { printf '%s\n' "$d"; break; }
    done)
    if [[ -n "$found" ]]; then
        printf '%s\n' "$found"
        return 0
    fi

    return 1
}

# --- Package Management ---
PACMAN_PACKAGES=(
    qt6-imageformats fuzzel fnott network-manager-applet
    git
    hyprland hyprlock hypridle kitty
    gtk3 cairo libgirepository gobject-introspection gtk-layer-shell
    libdbusmenu-gtk3 cinnamon-desktop gnome-bluetooth-3.0 gtk-session-lock
    matugen playerctl brightnessctl wf-recorder upower swayidle cava
    networkmanager bluez python python-pip awww base-devel
    xdg-desktop-portal-hyprland xdg-user-dirs polkit-kde-agent
    ttf-firacode-nerd ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
    brightnessctl playerctl wireplumber pipewire-pulse wl-clipboard
)

OPTIONAL_PACKAGES=(fastfetch yazi)
CALM_BUILD_PACKAGES=(cmake ninja gcc)
CONFIG_SOURCES=()
CONFIG_TARGETS=()

# Caffyne Shell uses Fabric CLI; keep it in the AUR layer.
CAFFYNE_AUR_PACKAGES=(fabric-cli-git)

select_profile_components() {
    local package
    SELECTED_OPTIONAL_PACKAGES=()

    case "$INSTALL_PROFILE" in
        minimal)
            ;;
        standard)
            SELECTED_OPTIONAL_PACKAGES=(fastfetch)
            ;;
        extended)
            SELECTED_OPTIONAL_PACKAGES=(fastfetch yazi)
            ;;
        custom)
            for package in "${OPTIONAL_PACKAGES[@]}"; do
                if ask "Include optional component '$package'?" n; then
                    SELECTED_OPTIONAL_PACKAGES+=("$package")
                fi
            done
            ;;
        *)
            err "Invalid installation profile: $INSTALL_PROFILE"
            exit 2
            ;;
    esac

    if (( ${#SELECTED_OPTIONAL_PACKAGES[@]} > 0 )); then
        info "Profile '$INSTALL_PROFILE' selected optional components: ${SELECTED_OPTIONAL_PACKAGES[*]}"
    else
        info "Profile '$INSTALL_PROFILE' has no optional components selected."
    fi
}

component_selected() {
    local selected
    for selected in "${SELECTED_OPTIONAL_PACKAGES[@]}"; do
        [[ "$selected" == "$1" ]] && return 0
    done
    return 1
}

collect_config_deployments() {
    local source_config="$REPO_ROOT/config"
    local folder_path folder_name

    CONFIG_SOURCES=()
    CONFIG_TARGETS=()

    for folder_path in "$source_config"/*/; do
        folder_name=$(basename "${folder_path%/}")
        case "$folder_name" in
            Hyprland)
                CONFIG_SOURCES+=("$folder_path/hypr")
                CONFIG_TARGETS+=(hypr)
                ;;
            installer)
                # The installer window runs from the repository; it is not a user config.
                ;;
            fastfetch)
                if component_selected "$folder_name"; then
                    CONFIG_SOURCES+=("$folder_path")
                    CONFIG_TARGETS+=("$folder_name")
                else
                    info "Skipping unselected optional $folder_name configuration."
                fi
                ;;
            *)
                CONFIG_SOURCES+=("$folder_path")
                CONFIG_TARGETS+=("$folder_name")
                ;;
        esac
    done
}

# --- Pre-flight system scan ---
scan_system() {
    title "System Scan"

    echo -e "${BOLD}${WHITE}Repository${RESET}"
    [[ -d "$REPO_ROOT/config" ]]  && ok "config"  || warn "config missing"
    [[ -d "$REPO_ROOT/assets" ]]  && ok "assets"  || warn "assets missing"
    [[ -d "$REPO_ROOT/scripts" ]] && ok "scripts" || warn "scripts missing"

    echo
    echo -e "${BOLD}${WHITE}Environment${RESET}"
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        info "Distribution: ${PRETTY_NAME:-unknown} (${ID:-unknown})"
    fi
    info "Architecture: $(uname -m); logical CPUs: $(getconf _NPROCESSORS_ONLN 2>/dev/null || echo unknown)"
    if [[ -r /proc/meminfo ]]; then
        local memory_kib
        memory_kib=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
        [[ -n "$memory_kib" ]] && info "Memory: $((memory_kib / 1024)) MiB"
    fi
    if has lspci; then
        info "Display adapters: $(lspci -mm 2>/dev/null | awk -F '"' '/VGA compatible controller|3D controller|Display controller/ {print $2}' | paste -sd ', ' -)"
    else
        info "Display adapter details unavailable (install pciutils for lspci)."
    fi

    if has pacman; then ok "Arch Linux (pacman found)"; else err "Not an Arch-based system"; fi

    if getent hosts archlinux.org &>/dev/null || curl -fsS --max-time 3 https://archlinux.org &>/dev/null; then
        ok "Internet reachable"
    else
        warn "No internet detected — package install may fail"
    fi

    if sudo -n true 2>/dev/null; then
        ok "sudo (cached)"
    else
        info "sudo will prompt for a password"
    fi

    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        ok "Wayland session active"
    else
        info "No active Wayland session (expected if installing from TTY/X11)"
    fi

    echo
}

can_write_target() {
    local target="$1"
    local parent

    if [[ -e "$target" ]]; then
        [[ -d "$target" && -w "$target" ]]
        return
    fi

    parent="$target"
    while [[ ! -e "$parent" && "$parent" != "/" ]]; do
        parent="${parent%/*}"
        [[ -n "$parent" ]] || parent="/"
    done
    [[ -d "$parent" && -w "$parent" ]]
}

run_environment_tests() {
    local failures=0
    local missing=()
    local command
    local available_kib

    title "Environment Tests"

    if [[ "$(uname -s)" == "Linux" ]]; then
        ok "Linux operating system"
    else
        err "Linux is required."
        failures=$((failures + 1))
    fi

    if (( BASH_VERSINFO[0] >= 4 )); then
        ok "Bash ${BASH_VERSION}"
    else
        err "Bash 4 or newer is required."
        failures=$((failures + 1))
    fi

    for command in uname readlink find cp mkdir mktemp awk; do
        has "$command" || missing+=("$command")
    done
    if (( ${#missing[@]} == 0 )); then
        ok "Required system utilities are available"
    else
        err "Required system utilities are missing: ${missing[*]}"
        failures=$((failures + 1))
    fi

    if [[ -d "$REPO_ROOT/config" &&
        -f "$REPO_ROOT/config/Hyprland/hypr/hyprland.lua" &&
        -f "$REPO_ROOT/scripts/install-caffyne-shell.sh" &&
        -f "$REPO_ROOT/scripts/migrate.sh" ]]; then
        ok "Required repository files are present"
    else
        err "Required configuration or installer files are missing from $REPO_ROOT."
        failures=$((failures + 1))
    fi

    if [[ -d "$HOME" && -w "$HOME" ]] &&
        can_write_target "$CONFIG_DIR" &&
        can_write_target "$LOCAL_BIN"; then
        ok "Home, configuration, and local-bin paths are writable"
    else
        err "Home or install target paths are not writable (HOME=$HOME, CONFIG_DIR=$CONFIG_DIR)."
        failures=$((failures + 1))
    fi

    if has pacman; then
        ok "Pacman package manager is available"
    elif [[ "$DRY_RUN" -eq 1 ]]; then
        warn "Pacman is unavailable; a dry run can continue, but installation cannot install system packages."
    else
        err "Pacman is required for installation."
        failures=$((failures + 1))
    fi

    if has df && has awk; then
        if available_kib=$(df -Pk "$HOME" 2>/dev/null | awk 'NR == 2 { print $4 }') &&
            [[ "$available_kib" =~ ^[0-9]+$ ]]; then
            if (( available_kib >= 2097152 )); then
                ok "At least 2 GiB of free space is available"
            else
                warn "Less than the recommended 2 GiB of free space is available in $HOME."
            fi
        else
            warn "Could not determine free space for $HOME."
        fi
    else
        warn "Cannot check free space because df or awk is unavailable."
    fi

    if (( failures > 0 )); then
        err "$failures required environment test(s) failed; no installation changes were made."
        return 1
    fi
    ok "All required environment tests passed."
}

install_packages() {
    title "Package Check"
    if ! has pacman; then
        err "Pacman not found. This script requires an Arch-based system."
        exit 1
    fi

    local packages=("${PACMAN_PACKAGES[@]}" "${SELECTED_OPTIONAL_PACKAGES[@]}")
    info "Installing dependencies for the '$INSTALL_PROFILE' profile."

    local missing=()
    for pkg in "${packages[@]}"; do
        pacman -Qi "$pkg" &>/dev/null || missing+=("$pkg")
    done

    if (( ${#missing[@]} > 0 )); then
        warn "Missing packages: ${missing[*]}"
        if [[ "$DRY_RUN" -eq 1 ]]; then
            info "Dry run: would install missing packages: ${missing[*]}"
            return 0
        fi
        if ask "Install missing dependencies?" y; then
            # The redirect belongs to the (unprivileged) subshell and writes the user's own log.
            # shellcheck disable=SC2024
            (sudo pacman -S --needed --noconfirm "${missing[@]}" &>>"$LOGFILE") &
            local pm_pid=$!
            spinner "$pm_pid" "Installing packages..."
            if wait "$pm_pid"; then
                ok "Package installation finished."
            else
                err "Pacman failed to install some packages (see $LOGFILE)."
                info "If you need Caffyne Shell packages, use an AUR helper (yay/paru) or pass --skip-aur."
                return 1
            fi
        fi
    else
        ok "All dependencies met."
    fi
}

find_aur_helper() {
    if has paru; then
        printf '%s\n' paru
    elif has yay; then
        printf '%s\n' yay
    else
        return 1
    fi
}

install_aur_packages() {
    if [[ "$SKIP_AUR" -eq 1 ]]; then
        info "Skipping AUR packages (--skip-aur)."
        return 0
    fi

    local helper
    if ! helper=$(find_aur_helper); then
        warn "Neither paru nor yay was found; Caffyne Shell Fabric CLI was not installed."
        info "Install an AUR helper, then run this installer again, or use --skip-aur."
        return 0
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "Dry run: would install ${CAFFYNE_AUR_PACKAGES[*]} with $helper."
        return 0
    fi

    info "Using AUR helper: $helper"
    if ask "Install Caffyne Shell CLI dependencies from the AUR with $helper?" y; then
        ("$helper" -S --needed --noconfirm "${CAFFYNE_AUR_PACKAGES[@]}" &>>"$LOGFILE") &
        local aur_pid=$!
        spinner "$aur_pid" "Installing Caffyne Shell Fabric CLI..."
        if wait "$aur_pid"; then
            ok "Caffyne Shell Fabric CLI installed."
        else
            warn "AUR helper failed to install Caffyne packages (see $LOGFILE); continuing with config deployment."
        fi
    else
        warn "Caffyne AUR setup skipped; the guarded launcher may remain inactive until it is installed."
    fi
}

# --- Backup bookkeeping ---
# The first backup ever taken holds the user's *original* configs. Later runs
# (e.g. `hyprmono update`) back up Hyprmono's own previous install, so the original
# is recorded separately, never pruned, and is what uninstall restores.
ORIGINAL_BACKUP_FILE="$LOGDIR/original-backup"

record_original_backup() {
    local dir="$1"
    if [[ ! -s "$ORIGINAL_BACKUP_FILE" ]]; then
        printf '%s\n' "$dir" > "$ORIGINAL_BACKUP_FILE"
        log "Recorded $dir as the original-config backup"
    fi
}

backup_local_bin_entry() {
    local name="$1" backup_dir="$2"
    local source="$LOCAL_BIN/$name"
    local destination="$backup_dir/.local-bin/$name"
    [[ -e "$source" || -L "$source" ]] || return 0
    [[ -e "$destination" || -L "$destination" ]] && return 0
    mkdir -p "$backup_dir/.local-bin"
    \cp -a -- "$source" "$destination"
    log "Backed up existing local executable $source"
}

# --- Core Installation ---
install_configs() {
    title "Configuration Deployment"

    local source_config="$REPO_ROOT/config"

    if [[ ! -d "$source_config" ]]; then
        err "Critical Failure: Config directory not found at $source_config"
        exit 1
    fi

    local deployed=()
    collect_config_deployments
    local total=${#CONFIG_SOURCES[@]}
    local count=0
    local folder_path folder_name

    if [[ "$DRY_RUN" -eq 1 ]]; then
        local index
        for index in "${!CONFIG_SOURCES[@]}"; do
            info "Dry run: would deploy ${CONFIG_TARGETS[$index]} to $CONFIG_DIR/"
        done
        info "Dry run: would deploy runtime scripts and assets; no backup or files created."
        return 0
    fi

    log "Starting backup..."
    local backup_dir
    backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    [[ -e "$backup_dir" ]] && backup_dir="${backup_dir}-$$"
    mkdir -p "$backup_dir"
    if [[ -n "${HYPRMONO_BACKUP_DIR_FILE:-}" ]]; then
        printf '%s\n' "$backup_dir" > "$HYPRMONO_BACKUP_DIR_FILE"
    fi
    record_original_backup "$backup_dir"

    local index
    for index in "${!CONFIG_SOURCES[@]}"; do
        folder_path="${CONFIG_SOURCES[$index]%/}"
        folder_name=$(basename "$folder_path")
        local target_name="${CONFIG_TARGETS[$index]}"
        count=$((count + 1))

        printf "\n${DIM}  → %s${RESET}\n" "$folder_name"
        log "Deploying $folder_name"

        local dest="$CONFIG_DIR/$target_name"

        if [[ -L "$dest" ]]; then
            local link_target
            link_target=$(readlink -f "$dest" 2>/dev/null || true)
            warn "$folder_name is a symlink -> ${link_target:-broken link}, replacing with a real directory"
            \cp -a -- "$dest" "$backup_dir/"
            log "Backed up symlink $dest"
            log "Removing symlink $dest (was -> $link_target)"
            rm -f "$dest"
        elif [[ -d "$dest" ]]; then
            log "Backing up existing $dest ($(du -sh "$dest" 2>/dev/null | cut -f1))"
            \cp -rf "$dest" "$backup_dir/"
            log "Backed up $folder_name"
        elif [[ -e "$dest" ]]; then
            log "Backing up existing file $dest"
            \cp -a -- "$dest" "$backup_dir/"
            rm -f -- "$dest"
        fi

        # hypr/custom/*.lua are the user's personal overrides: never clobber them
        # with the empty stubs from the repo, not even in --wipe mode.
        local preserved_custom=""
        if [[ "$target_name" == hypr && -d "$dest/custom" ]]; then
            preserved_custom=$(mktemp -d)
            \cp -a "$dest/custom/." "$preserved_custom/"
        fi

        if [[ "$WIPE_CONFIGS" -eq 1 ]]; then
            log "Wiping managed destination $dest"
            rm -rf -- "$dest"
        fi

        mkdir -p "$dest"
        local entries=("$folder_path"/*)
        local entry
        for entry in "${entries[@]}"; do
            \cp -rf "$entry" "$dest/"
        done

        if [[ -n "$preserved_custom" ]]; then
            mkdir -p "$dest/custom"
            \cp -a "$preserved_custom/." "$dest/custom/"
            rm -rf -- "$preserved_custom"
            info "Preserved your hypr/custom overrides"
        fi
        log "Deployed $folder_name"

        deployed+=("$target_name")
        progress "$count" "$total"
    done

    # Scripts that Hyprland tools execute directly must carry the exec bit.
    if [[ -d "$CONFIG_DIR/hypr/hyprlock" ]]; then
        find "$CONFIG_DIR/hypr/hyprlock" -type f -name '*.sh' -exec chmod +x {} +
    fi

    # Record what was deployed so uninstall removes exactly these directories.
    mkdir -p "$LOGDIR"
    local recorded_file="$LOGDIR/deployed-targets" recorded
    for recorded in "${deployed[@]}"; do
        grep -qxF -- "$recorded" "$recorded_file" 2>/dev/null || printf '%s\n' "$recorded" >> "$recorded_file"
    done
    # Tree-style summary of what was deployed
    echo -e "\n${BOLD}${WHITE}Configuration${RESET}"
    local last_idx=$(( ${#deployed[@]} - 1 ))
    for i in "${!deployed[@]}"; do
        if (( i == last_idx )); then
            printf "${GRAY}└── ${RESET}%s\n" "${deployed[$i]}"
            printf "${GRAY}    └── installed${RESET}\n"
        else
            printf "${GRAY}├── ${RESET}%s\n" "${deployed[$i]}"
            printf "${GRAY}│   └── installed${RESET}\n"
        fi
    done

    # Deploy scripts to ~/.local/bin
    title "Script Deployment"
    mkdir -p "$LOCAL_BIN"
    if [[ "$WIPE_CONFIGS" -eq 1 ]]; then
        # Include tools from earlier releases so a wipe removes stale copies.
        local managed_script
        for managed_script in change_wallpaper.sh cpuinfo.sh fuzzel-emojis.sh gpuinfo.sh hyprmono hyprmono.sh install-caffyne-shell.sh install-calm-shell.sh launch-menu.sh launch_first_available.sh launch_terminal.sh lock-screen.sh migrate.sh performance.sh profile.sh reinstall.sh start-idle.sh start-session-services.sh start-shell.sh uninstall.sh watch-quality.sh; do
            backup_local_bin_entry "$managed_script" "$backup_dir"
            rm -f -- "$LOCAL_BIN/$managed_script"
        done
    fi
    for script in "$REPO_ROOT/scripts"/*.sh; do
        if [[ -f "$script" ]]; then
            local script_name
            script_name=$(basename "$script")

            # Keep installer and repository-only development tools out of the runtime bin.
            if [[ "$script_name" == "$SELF_NAME" || "$script_name" == "watch-quality.sh" ]]; then
                continue
            fi

            local script_dest="$LOCAL_BIN/$script_name"
            backup_local_bin_entry "$script_name" "$backup_dir"

            if [[ -L "$script_dest" ]]; then
                local script_link_target
                script_link_target=$(readlink -f "$script_dest" 2>/dev/null || true)
                warn "$script_name is a symlink -> ${script_link_target:-broken link}, replacing with a real file"
                rm -f "$script_dest"
            fi

            \cp -f "$script" "$LOCAL_BIN/"
            chmod +x "$script_dest"
            ok "Installed $script_name to $LOCAL_BIN"
        fi
    done

    # Create 'hyprmono' command symlink
    if [[ -f "$LOCAL_BIN/hyprmono.sh" ]]; then
        backup_local_bin_entry "hyprmono" "$backup_dir"
        ln -sf "$LOCAL_BIN/hyprmono.sh" "$LOCAL_BIN/hyprmono"
        ok "Linked 'hyprmono' command"
    fi

    # Deploy assets
    title "Asset Deployment"
    if [[ -d "$REPO_ROOT/assets" ]]; then
        if [[ "$WIPE_CONFIGS" -eq 1 ]]; then
            rm -rf -- "$CONFIG_DIR/hypr/assets"
        fi
        mkdir -p "$CONFIG_DIR/hypr/assets"
        \cp -rf "$REPO_ROOT/assets/"* "$CONFIG_DIR/hypr/assets/"
        ok "Deployed assets to $CONFIG_DIR/hypr/assets"

        if [[ -d "$REPO_ROOT/assets/fonts" ]]; then
            info "Updating font cache..."
            mkdir -p "$HOME/.local/share/fonts"
            local font_files=("$REPO_ROOT/assets/fonts"/*.otf "$REPO_ROOT/assets/fonts"/*.ttf)
            if (( ${#font_files[@]} > 0 )); then
                \cp -f "${font_files[@]}" "$HOME/.local/share/fonts/"
            fi
            fc-cache -f &>/dev/null
            ok "Fonts installed successfully."
        fi
    fi

    # stash for the final summary screen
    DEPLOYED_ITEMS=("${deployed[@]}")
    BACKUP_DIR="$backup_dir"
}

install_calm_shell() {
    title "Calm-shell Setup"
    if [[ "$SKIP_DEPS" -eq 1 ]]; then
        info "Skipping optional Calm-shell setup because dependencies were disabled."
        return 0
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "Dry run: would offer to build Calm-shell from github.com/yksouthx/calm-shell.git."
        return 0
    fi
    if ask "Build and install Calm-shell from github.com/yksouthx/calm-shell.git?" y; then
        local missing_build=()
        local pkg
        for pkg in "${CALM_BUILD_PACKAGES[@]}"; do
            pacman -Qi "$pkg" &>/dev/null || missing_build+=("$pkg")
        done
        if (( ${#missing_build[@]} > 0 )); then
            if [[ "$SKIP_PKGS" -eq 1 ]]; then
                warn "Skipping Calm-shell build; required build packages are missing and --skip-pkgs was set."
                return 0
            fi
            info "Installing optional Calm-shell build tools: ${missing_build[*]}"
            # shellcheck disable=SC2024  # the log file is the user's own
            sudo pacman -S --needed --noconfirm "${missing_build[@]}" &>>"$LOGFILE"
        fi
        bash "$REPO_ROOT/scripts/install-calm-shell.sh"
        ok "Calm-shell is ready at $HOME/.local/bin/calm"
    else
        warn "Calm-shell setup skipped; terminal launcher will fall back to Kitty."
    fi
}

print_footer() {
    printf "${GRAY}"
    printf '━%.0s' $(seq 1 "$WIDTH")
    printf "${RESET}\n"
    printf "${BOLD}${WHITE}%s${RESET}\n" "$PROJECT"
    printf "${DIM}Minimal • Fast • Beautiful${RESET}\n"
    printf "${DIM}%s${RESET}\n" "$REPO_URL"
    printf "${GRAY}"
    printf '━%.0s' $(seq 1 "$WIDTH")
    printf "${RESET}\n"
}

validate_installation() {
    title "Installation Validation"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "Dry run: installed files and runtime services cannot be validated yet."
        return 0
    fi

    if [[ -f "$CONFIG_DIR/hypr/hyprland.lua" ]]; then
        ok "Hyprland configuration is present."
    else
        warn "Hyprland configuration is missing; configuration deployment may have been skipped."
    fi

    local script
    for script in start-shell.sh start-idle.sh start-session-services.sh lock-screen.sh launch-menu.sh migrate.sh performance.sh profile.sh; do
        if [[ -x "$LOCAL_BIN/$script" ]]; then
            ok "Runtime helper is installed: $script"
        else
            warn "Runtime helper is missing: $LOCAL_BIN/$script"
        fi
    done

    if [[ -L "$LOCAL_BIN/hyprmono" && -e "$LOCAL_BIN/hyprmono" ]]; then
        ok "hyprmono command resolves to $(readlink "$LOCAL_BIN/hyprmono")"
    else
        warn "hyprmono command link is missing or broken: $LOCAL_BIN/hyprmono"
    fi

    if [[ -x "$CONFIG_DIR/caffyne-shell/start.sh" ]] ||
        [[ -r "$CONFIG_DIR/caffyne-shell/main.py" ]]; then
        ok "Caffyne Shell is ready."
    else
        warn "Caffyne Shell is not installed; run scripts/install-caffyne-shell.sh manually."
    fi

    case ":$PATH:" in
        *":$LOCAL_BIN:"*) ;;
        *) warn "$LOCAL_BIN is not in PATH; add it to your shell profile to run 'hyprmono' directly." ;;
    esac
}

main() {
   local ORIG_ARGS=("$@")
   # --repo /path/to/Hyprmono overrides auto-detection for this run
     while [[ $# -gt 0 ]]; do
       case "$1" in
           --repo)
                 if [[ $# -lt 2 || -z "$2" ]]; then
                     err "--repo requires a repository path"
                     exit 2
                 fi
               HYPRMONO_REPO="$2"
               shift 2
               ;;
           --repo=*)
                 HYPRMONO_REPO="${1#--repo=}"
                 if [[ -z "$HYPRMONO_REPO" ]]; then
                     err "--repo requires a repository path"
                     exit 2
                 fi
               shift
               ;;
           --no-migrate)
               NO_MIGRATE=1
               shift
               ;;
           --no-cleanup)
               NO_CLEANUP=1
               shift
               ;;
           --skip-pkgs)
               SKIP_PKGS=1
               shift
               ;;
           --skip-deps)
               SKIP_DEPS=1
               SKIP_PKGS=1
               SKIP_AUR=1
               shift
               ;;
           --skip-aur)
               SKIP_AUR=1
               shift
               ;;
           --terminal)
               TERMINAL_MODE=1
               shift
               ;;
           --minimal)
               INSTALL_PROFILE="minimal"
               shift
               ;;
           --standard)
               INSTALL_PROFILE="standard"
               shift
               ;;
           --extended)
               INSTALL_PROFILE="extended"
               shift
               ;;
           --custom)
               INSTALL_PROFILE="custom"
               shift
               ;;
           --profile)
               if [[ $# -lt 2 || ! "$2" =~ ^(minimal|standard|extended|custom)$ ]]; then
                   err "--profile requires minimal, standard, extended, or custom"
                   exit 2
               fi
               INSTALL_PROFILE="$2"
               shift 2
               ;;
           --wipe|--fresh)
               WIPE_CONFIGS=1
               shift
               ;;
           --full-ui)
               INSTALL_PROFILE="extended"
               shift
               ;;
           --dry-run)
               DRY_RUN=1
               shift
               ;;
           --rollback)
               if [[ $# -lt 2 || -z "$2" ]]; then
                   err "--rollback requires a migration backup directory"
                   exit 2
               fi
               ROLLBACK_DIR="$2"
               shift 2
               ;;
           --yes|--non-interactive)
               ASSUME_YES=1
               shift
               ;;
           --help|-h)
               usage
               return 0
               ;;
           *)
               err "Unknown option: $1"
               usage >&2
               exit 2
               ;;
       esac
   done

    if ! REPO_ROOT=$(resolve_repo_root); then
        err "Could not locate the HyprMono repository."
        info "Looked next to the installer, in $TARGET_REPO_DIR, and in common clone locations."
        info "Fix by either:"
        info "  1. Running from inside the cloned repo, or"
        info "  2. ./install.sh --repo /path/to/HyprMono, or"
        info "  3. HYPRMONO_REPO=/path/to/HyprMono ./install.sh"
        exit 1
    fi
    ok "Repository located at $REPO_ROOT"

    if [[ $EUID -eq 0 ]]; then
        err "Safety Check: Do NOT run as root."
        exit 1
    fi

    if [[ -n "$ROLLBACK_DIR" ]]; then
        local rollback_args=(--rollback "$ROLLBACK_DIR")
        if [[ "$DRY_RUN" -eq 1 ]]; then
            rollback_args=(--dry-run "${rollback_args[@]}")
        fi
        bash "$REPO_ROOT/scripts/migrate.sh" "${rollback_args[@]}"
        return
    fi

   clear

cat <<EOF

╭──────────────────────────────────────────────────────────────╮
│                                                              │
│                       H Y P R M O N O                        │
│                                                              │
│              Minimal • Beautiful • Wayland                   │
│                                                              │
╰──────────────────────────────────────────────────────────────╯

EOF

    if [[ "$TERMINAL_MODE" -eq 1 ]]; then
        info "Using the terminal installer."
    fi

printf "${DIM}Version     4.5${RESET}\n"
printf "${DIM}Repository  %s${RESET}\n" "$REPO_ROOT"
printf "${DIM}Log File    %s${RESET}\n\n" "$LOGFILE"

    if ! run_environment_tests; then
        exit 1
    fi

    scan_system

    select_profile_components

    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "Dry run enabled: no package, repository, or configuration changes will be made."
    elif [[ "$SKIP_PKGS" -eq 1 ]]; then
        info "Skipping sudo pre-authentication because system package installation is disabled."
    else
        sudo -v || { err "Sudo authentication failed."; exit 1; }
        keep_sudo_alive
    fi

    if [[ "$NO_CLEANUP" -eq 1 ]]; then
        info "Skipping desktop-component cleanup (--no-cleanup)."
    elif [[ -x "$REPO_ROOT/scripts/migrate.sh" || -f "$REPO_ROOT/scripts/migrate.sh" ]]; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
            bash "$REPO_ROOT/scripts/migrate.sh" --dry-run
        else
            bash "$REPO_ROOT/scripts/migrate.sh"
        fi
    fi

    # Path enforcement
    if [[ "$NO_MIGRATE" -eq 1 ]]; then
        info "Skipping repository migration (--no-migrate)."
    elif [[ "$REPO_ROOT" != "$TARGET_REPO_DIR" ]]; then
        warn "Repository is at $REPO_ROOT instead of $TARGET_REPO_DIR"
        if [[ "$DRY_RUN" -eq 1 ]]; then
            info "Dry run: would offer to migrate repository to $TARGET_REPO_DIR."
        elif ask "Migrate repository to standard location ($TARGET_REPO_DIR)?" y; then
            mkdir -p "$TARGET_REPO_DIR"
            # "/." copies dotfiles too, so .git survives and `hyprmono update` keeps working
            \cp -a "$REPO_ROOT/." "$TARGET_REPO_DIR/"
            ok "Migration complete."
            info "Continuing install from $TARGET_REPO_DIR..."
            # exec skips the EXIT trap, so stop the sudo keep-alive loop ourselves
            # (the re-executed installer starts its own).
            kill "${SUDO_KEEPALIVE_PID:-}" 2>/dev/null || true
            local exec_args=()
            local arg_index=0
            while (( arg_index < ${#ORIG_ARGS[@]} )); do
                case "${ORIG_ARGS[$arg_index]}" in
                    --repo)
                        arg_index=$((arg_index + 2))
                        ;;
                    --repo=*)
                        arg_index=$((arg_index + 1))
                        ;;
                    *)
                        exec_args+=("${ORIG_ARGS[$arg_index]}")
                        arg_index=$((arg_index + 1))
                        ;;
                esac
            done
            exec_args+=("--no-migrate")
            export HYPRMONO_REPO="$TARGET_REPO_DIR"
            exec "$TARGET_REPO_DIR/scripts/$SELF_NAME" "${exec_args[@]}"
        fi
    fi

    if [[ "$SKIP_PKGS" -eq 1 ]]; then
        info "Skipping system package check (--skip-pkgs/--skip-deps)."
    else
        install_packages || exit 1
    fi

    install_aur_packages

    if [[ "$SKIP_PKGS" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
        title "Caffyne Shell Setup"
        if ask "Clone and configure Caffyne Shell?" y; then
            if bash "$REPO_ROOT/scripts/install-caffyne-shell.sh" &>>"$LOGFILE"; then
                ok "Caffyne Shell is ready."
            else
                warn "Caffyne Shell setup failed (see $LOGFILE); the terminal installer remains available."
            fi
        else
            warn "Caffyne Shell setup skipped."
        fi
    elif [[ "$DRY_RUN" -eq 1 ]]; then
        title "Caffyne Shell Setup"
        info "Dry run: would clone Caffyne Shell to \$XDG_CONFIG_HOME/caffyne-shell."
    fi

    DEPLOYED_ITEMS=()
    BACKUP_DIR="(none created)"
    if [[ "$WIPE_CONFIGS" -eq 1 ]]; then
        warn "Wipe mode removes existing managed HyprMono config directories after creating a timestamped backup."
    fi
    if ask "Proceed with configuration deployment?" y; then
        install_configs
        install_calm_shell
    fi

    validate_installation

    title "Installation Complete"

    echo -e "${BOLD}${WHITE}Repository${RESET}"
    echo "  $REPO_ROOT"
    echo

    echo -e "${BOLD}${WHITE}Installed${RESET}"
    if (( ${#DEPLOYED_ITEMS[@]} > 0 )); then
        for item in "${DEPLOYED_ITEMS[@]}"; do
            printf "  ${SUCCESS}✓${RESET} %s\n" "$item"
        done
    else
        printf "  ${WARNING}!${RESET} Configuration deployment skipped\n"
    fi
    echo

    echo -e "${BOLD}${WHITE}Backup${RESET}"
    echo "  $BACKUP_DIR"
    echo

    echo -e "${BOLD}${WHITE}Next${RESET}"
    echo "  reboot (or reload Hyprland)"
    echo "  calm"
    echo "  start-shell.sh (launches Caffyne Shell)"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "  rerun without --dry-run to apply changes"
    fi
    echo

    print_footer
}

main "$@"
