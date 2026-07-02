#!/usr/bin/env bash

# H Y P R M O N O - The Definitive Installer
# Version: 4.5 (HyDE-style UI pass, bugfixes retained)
# Purpose: Robust, path-aware installation for the HyprMono environment.

set -Eeuo pipefail
shopt -s nullglob

# Terminal Title
printf "\033]0;HyprMono Installer\a"

# --- Absolute Path Resolution ---
REAL_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPTS_DIR=$(dirname "$REAL_PATH")
SELF_NAME=$(basename "$REAL_PATH")

# --- Configuration ---
readonly PROJECT="HyprMono"
CONFIG_DIR="$HOME/.config"
LOCAL_BIN="$HOME/.local/bin"
TARGET_REPO_DIR="$HOME/.local/share/hyprmono"
REPO_URL="github.com/YOURNAME/HyprMono"   # <- update to your actual repo

# Log location is intentionally independent of the repo path — we need
# somewhere to write to even if repo resolution itself fails.
LOGDIR="$HOME/.cache/hyprmono"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/install.log"

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
    read -r answer
    [[ -z "$answer" ]] && answer="$default"
    [[ "$answer" =~ ^[Yy]$ ]]
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
    (( current == total )) && printf "\n"
}

# --- Sudo keep-alive ---
keep_sudo_alive() {
    while true; do
        sudo -v
        sleep 60
    done &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

# --- Repository Resolution ---
# Figures out where the actual HyprMono repo (the one containing config/,
# assets/, scripts/) lives, without assuming the installer's own location
# is inside it. Tries, in order:
#   1. --repo flag / HYPRMONO_REPO env var (explicit override)
#   2. The directory this script is sitting in (flat layout: <repo>/install.sh)
#   3. The parent of that directory (nested layout: <repo>/scripts/install.sh)
#   4. The standard install location: ~/.local/share/hyprmono
#   5. A short list of common clone locations
#   6. A bounded search of $HOME for a hyprmono/ dir with a config/ subfolder
is_valid_repo() { [[ -d "$1/config" ]]; }

resolve_repo_root() {
    if [[ -n "${HYPRMONO_REPO:-}" ]]; then
        if is_valid_repo "$HYPRMONO_REPO"; then
            printf '%s\n' "$(cd "$HYPRMONO_REPO" && pwd)"
            return 0
        fi
        err "HYPRMONO_REPO=$HYPRMONO_REPO has no config/ directory — ignoring override" >&2
    fi

    # The script may live either directly at the repo root
    # (<repo>/install.sh) or nested one level down (<repo>/scripts/install.sh).
    # Check self first so a flat layout doesn't get walked up one directory
    # too far into the repo's parent.
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
    found=$(find "$HOME" -maxdepth 4 -type d -iname "hyprmono" 2>/dev/null | while read -r d; do
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
    hyprland hyprlock hypridle waybar kitty wofi rofi fuzzel
    xdg-desktop-portal-hyprland xdg-user-dirs polkit-kde-agent
    ttf-firacode-nerd ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
    network-manager-applet brightnessctl playerctl wireplumber pipewire-pulse
    swaync dunst wlogout swaylock
    fish fastfetch
)

# --- Pre-flight system scan ---
scan_system() {
    title "System Scan"

    echo -e "${BOLD}${WHITE}Repository${RESET}"
    [[ -d "$REPO_ROOT/config" ]]  && ok "config"  || warn "config missing"
    [[ -d "$REPO_ROOT/assets" ]]  && ok "assets"  || warn "assets missing"
    [[ -d "$REPO_ROOT/scripts" ]] && ok "scripts" || warn "scripts missing"

    echo
    echo -e "${BOLD}${WHITE}Environment${RESET}"
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

install_packages() {
    title "Package Check"
    if ! has pacman; then
        err "Pacman not found. This script requires an Arch-based system."
        exit 1
    fi

    local missing=()
    for pkg in "${PACMAN_PACKAGES[@]}"; do
        pacman -Qi "$pkg" &>/dev/null || missing+=("$pkg")
    done

    if (( ${#missing[@]} > 0 )); then
        warn "Missing packages: ${missing[*]}"
        if ask "Install missing dependencies?" y; then
            (sudo pacman -S --needed --noconfirm "${missing[@]}" &>>"$LOGFILE") &
            spinner $! "Installing packages..."
            wait $! || {
                err "Pacman failed to install some packages."
                info "If you need AUR packages like 'swaylock-effects' or 'rofi-wayland', please use an AUR helper (yay/paru)."
            }
            ok "Package installation finished."
        fi
    else
        ok "All dependencies met."
    fi
}

# --- Core Installation ---
install_configs() {
    title "Configuration Deployment"

    local source_config="$REPO_ROOT/config"

    if [[ ! -d "$source_config" ]]; then
        err "Critical Failure: Config directory not found at $source_config"
        exit 1
    fi

    log "Starting backup..."
    local backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    local deployed=()
    local folders=("$source_config"/*/)
    local total=${#folders[@]}
    local count=0

    for folder_path in "${folders[@]}"; do
        folder_path="${folder_path%/}"
        local folder_name=$(basename "$folder_path")
        count=$((count + 1))

        if [[ -d "$CONFIG_DIR/$folder_name" ]]; then
            \cp -rf "$CONFIG_DIR/$folder_name" "$backup_dir/"
            log "Backed up $folder_name"
        fi

        mkdir -p "$CONFIG_DIR/$folder_name"
        local entries=("$folder_path"/*)
        if (( ${#entries[@]} > 0 )); then
            \cp -rf "$folder_path/"* "$CONFIG_DIR/$folder_name/"
        fi

        deployed+=("$folder_name")
        progress "$count" "$total"
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
    for script in "$REPO_ROOT/scripts"/*.sh; do
        if [[ -f "$script" ]]; then
            local script_name=$(basename "$script")

            # Don't install the installer itself as a runtime script
            if [[ "$script_name" == "$SELF_NAME" ]]; then
                continue
            fi

            \cp -f "$script" "$LOCAL_BIN/"
            chmod +x "$LOCAL_BIN/$script_name"
            ok "Installed $script_name to $LOCAL_BIN"
        fi
    done

    # Create 'hyde' command symlink
    if [[ -f "$LOCAL_BIN/hyde-shell.sh" ]]; then
        ln -sf "$LOCAL_BIN/hyde-shell.sh" "$LOCAL_BIN/hyde"
        ok "Linked 'hyde' command"
    fi

    # Deploy assets
    title "Asset Deployment"
    if [[ -d "$REPO_ROOT/assets" ]]; then
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

main() {
   # --repo /path/to/Hyprmono overrides auto-detection for this run
   while [[ $# -gt 0 ]]; do
       case "$1" in
           --repo)
               HYPRMONO_REPO="$2"
               shift 2
               ;;
           --repo=*)
               HYPRMONO_REPO="${1#--repo=}"
               shift
               ;;
           *)
               shift
               ;;
       esac
   done

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

printf "${DIM}Version     1.0${RESET}\n"
printf "${DIM}Repository  %s${RESET}\n" "$REPO_ROOT"
printf "${DIM}Log File    %s${RESET}\n\n" "$LOGFILE"

    if [[ $EUID -eq 0 ]]; then
        err "Safety Check: Do NOT run as root."
        exit 1
    fi

    sudo -v || { err "Sudo authentication failed."; exit 1; }
    keep_sudo_alive

    scan_system

    # Path enforcement
    if [[ "$REPO_ROOT" != "$TARGET_REPO_DIR" ]]; then
        warn "Repository is at $REPO_ROOT instead of $TARGET_REPO_DIR"
        if ask "Migrate repository to standard location ($TARGET_REPO_DIR)?" y; then
            mkdir -p "$TARGET_REPO_DIR"
            \cp -rf "$REPO_ROOT/"* "$TARGET_REPO_DIR/"
            ok "Migration complete."
            info "Continuing install from $TARGET_REPO_DIR..."
            exec "$TARGET_REPO_DIR/scripts/$SELF_NAME" "$@"
        fi
    fi

    install_packages

    DEPLOYED_ITEMS=()
    BACKUP_DIR="(none created)"
    if ask "Proceed with configuration deployment?" y; then
        install_configs
    fi

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
    echo "  reboot"
    echo "  hyde"
    echo

    print_footer
}

main "$@"