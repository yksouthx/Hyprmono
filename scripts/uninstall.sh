#!/usr/bin/env bash

# HyprMono Uninstaller
# Version: 1.1

set -Eeuo pipefail

# --- Configuration ---
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="$HOME/.local/bin"
TARGETS=(hypr hyprmono kitty wofi rofi fuzzel waybar swaylock swaync dunst fastfetch fish vim wlogout fontconfig xdg-desktop-portal kde-material-you-colors caelestia calm-shell)
# Include tools from earlier releases so uninstall removes stale copies.
INSTALLED_SCRIPTS=(change_wallpaper.sh cpuinfo.sh fuzzel-emojis.sh gpuinfo.sh hyprmono hyprmono.sh install-calm-shell.sh launch_first_available.sh launch_terminal.sh migrate.sh performance.sh profile.sh reinstall.sh start-caelestia.sh uninstall.sh watch-quality.sh)
BACKUP_PREFIX=".config-backup-"
LOG_FILE="$HOME/.cache/Hyprmono/uninstall.log"
# install.sh records the very first backup (the user's original configs) here.
ORIGINAL_BACKUP_FILE="$HOME/.cache/Hyprmono/original-backup"

# --- Colors ---
RED="\e[38;5;203m"
GREEN="\e[38;5;114m"
YELLOW="\e[38;5;222m"
CYAN="\e[38;5;117m"
BOLD="\e[1m"
RESET="\e[0m"

# --- Helpers ---
log() {
    printf '%b> %s%b\n' "${CYAN}" "$*" "${RESET}"
    mkdir -p "$(dirname "$LOG_FILE")"
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}
ok() { printf '%b✓%b %s\n' "${GREEN}" "${RESET}" "$*"; }
warn() { printf '%b!%b %s\n' "${YELLOW}" "${RESET}" "$*"; }
err() { printf '%b✗%b %s\n' "${RED}" "${RESET}" "$*" >&2; }

confirm() {
    local prompt="$1"

    if [[ ! -t 0 ]]; then
        err "Refusing destructive uninstall without an interactive confirmation."
        exit 1
    fi

    printf '%b?%b %s [y/N] ' "${BOLD}${YELLOW}" "${RESET}" "$prompt"
    read -r -n 1 reply
    printf '\n'

    [[ "$reply" =~ ^[Yy]$ ]] || exit 1
}

remove_configs() {
    log "Removing HyprMono configurations..."
    for target in "${TARGETS[@]}"; do
        if [[ -e "$CONFIG_DIR/$target" || -L "$CONFIG_DIR/$target" ]]; then
            log "Removing $CONFIG_DIR/$target"
            rm -rf -- "${CONFIG_DIR:?}/$target"
            ok "Removed $CONFIG_DIR/$target"
        fi
    done
}

remove_installed_scripts() {
    log "Removing installed HyprMono scripts..."
    for script in "${INSTALLED_SCRIPTS[@]}"; do
        if [[ -e "$LOCAL_BIN/$script" || -L "$LOCAL_BIN/$script" ]]; then
            log "Removing $LOCAL_BIN/$script"
            rm -f -- "$LOCAL_BIN/$script"
            ok "Removed $LOCAL_BIN/$script"
        fi
    done
}

restore_latest_backup() {
    log "Searching for latest backup..."

    # Prefer the backup of the user's ORIGINAL configs. The newest backup is
    # usually just the previous HyprMono install, which is not what they want back.
    local latest_backup=""
    if [[ -s "$ORIGINAL_BACKUP_FILE" ]]; then
        latest_backup=$(< "$ORIGINAL_BACKUP_FILE")
        [[ -d "$latest_backup" ]] || latest_backup=""
    fi
    if [[ -z "$latest_backup" ]]; then
        local newest
        newest=$(find "$HOME" -maxdepth 1 -type d -name "${BACKUP_PREFIX}*" -printf '%f\n' 2>/dev/null | sort -r | head -n 1 || true)
        [[ -n "$newest" ]] && latest_backup="$HOME/$newest"
    fi

    if [[ -n "$latest_backup" ]]; then
        warn "Found backup: $latest_backup"
        confirm "Restore this backup?"

        for target in "${TARGETS[@]}"; do
            if [[ -e "$latest_backup/$target" || -L "$latest_backup/$target" ]]; then
                cp -a "$latest_backup/$target" "$CONFIG_DIR/"
                log "Restored $target from $latest_backup"
                ok "Restored $target from backup"
            fi
        done
        if [[ -d "$latest_backup/.local-bin" ]]; then
            mkdir -p "$LOCAL_BIN"
            local saved name
            for saved in "$latest_backup/.local-bin/"*; do
                [[ -e "$saved" || -L "$saved" ]] || continue
                name=$(basename "$saved")
                if [[ -e "$LOCAL_BIN/$name" || -L "$LOCAL_BIN/$name" ]]; then
                    warn "Skipped $LOCAL_BIN/$name because it already exists."
                    continue
                fi
                cp -a "$saved" "$LOCAL_BIN/"
                log "Restored $LOCAL_BIN/$name from $latest_backup"
                ok "Restored $LOCAL_BIN/$name from backup"
            done
        fi
    else
        warn "No backups found to restore."
    fi
}

main() {
    printf '%bHyprMono Uninstaller%b\n' "${BOLD}" "${RESET}"
    printf 'This will remove HyprMono configurations from your system.\n\n'

    if [[ $EUID -eq 0 ]]; then
        err "Do not run this script as root."
        exit 1
    fi

    confirm "Are you sure you want to proceed?"

    remove_configs
    remove_installed_scripts
    printf '\n'
    restore_latest_backup

    printf '\n'
    ok "Uninstallation complete."
    log "Note: System packages installed by HyprMono were not removed."
}

main "$@"
