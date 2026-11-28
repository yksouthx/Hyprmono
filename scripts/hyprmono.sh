#!/usr/bin/env bash

# H Y P R M O N O - The Definitive CLI
# Centralized entry point for the HyprMono environment.

set -Eeuo pipefail

# --- Absolute Path Resolution ---
REAL_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPTS_DIR=$(dirname "$REAL_PATH")
STANDARD_REPO_DIR="$HOME/.local/share/Hyprmono"

resolve_repo_dir() {
    local candidates=(
        "${HYPRMONO_REPO:-}"
        "$STANDARD_REPO_DIR"
        "$(cd "$SCRIPTS_DIR/.." && pwd)"
    )

    local candidate
    for candidate in "${candidates[@]}"; do
        [[ -n "$candidate" ]] || continue
        if [[ -d "$candidate/.git" && -d "$candidate/scripts" && -d "$candidate/config" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

REPO_DIR=$(resolve_repo_dir || true)

# --- Colors ---
RED="\e[38;5;203m"
GREEN="\e[38;5;114m"
CYAN="\e[38;5;117m"
MAGENTA="\e[38;5;213m"
BOLD="\e[1m"
RESET="\e[0m"

# --- Helpers ---
log() { echo -e "${CYAN}hyprmono >${RESET} $*"; }
err() { echo -e "${RED}hyprmono error >${RESET} $*" >&2; }

run_repo_script() {
    local script_name="$1"
    shift

    # Scripts are always run through bash, so they only need to exist (not be +x).
    if [[ -n "$REPO_DIR" && -f "$REPO_DIR/scripts/$script_name" ]]; then
        bash "$REPO_DIR/scripts/$script_name" "$@"
    elif [[ -f "$SCRIPTS_DIR/$script_name" ]]; then
        bash "$SCRIPTS_DIR/$script_name" "$@"
    else
        err "Unable to locate $script_name. Set HYPRMONO_REPO to your HyprMono checkout."
        exit 1
    fi
}

show_help() {
    echo -e "${BOLD}${MAGENTA}H Y P R M O N O${RESET} - HyprMono Management"
    echo
    echo -e "${BOLD}Usage:${RESET} hyprmono [command]"
    echo
    echo -e "${BOLD}Commands:${RESET}"
    echo -e "  install     Execute the professional installer"
    echo -e "  reinstall   Fresh clone from GitHub and redeploy (configs are backed up first)"
    echo -e "  uninstall   Completely remove all configurations"
    echo -e "  update      Pull latest repository changes and sync"
    echo -e "  audit       Verify system dependencies"
    echo -e "  migrate     Scan duplicate shell components; --rollback DIR restores backups"
    echo -e "  settings    Open Caffyne Shell quick settings"
    echo -e "  performance Measure Niri and Caffyne Shell CPU/RAM; compare a baseline"
    echo -e "  emoji       Pick and copy an emoji with Fuzzel"
    echo -e "  help        Display this help interface"
    echo
}

case "${1:-help}" in
    install)
        log "Initializing Installer..."
        run_repo_script install.sh
        ;;
    reinstall)
        log "Initializing Reinstaller..."
        run_repo_script reinstall.sh
        ;;
    uninstall)
        log "Initializing Uninstaller..."
        run_repo_script uninstall.sh
        ;;
    update)
        log "Syncing Repository..."
        if [[ -n "$REPO_DIR" && -d "$REPO_DIR/.git" ]]; then
            cd "$REPO_DIR"
            branch=$(git symbolic-ref --short HEAD 2>/dev/null || printf 'master')
            git pull --ff-only origin "$branch"
            log "Syncing Configurations..."
            bash "$REPO_DIR/scripts/install.sh" --skip-pkgs --yes --no-migrate
        else
            err "Update failed: Not a git repository."
        fi
        ;;
    audit)
        log "Running System Audit..."
        missing=()
        bins=(niri swayidle swaylock kitty wpctl brightnessctl playerctl wl-copy fuzzel fnott)
        for bin in "${bins[@]}"; do
            command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
        done
        if [[ ! -x "${XDG_CONFIG_HOME:-$HOME/.config}/caffyne-shell/start.sh" ]] &&
            [[ ! -r "${XDG_CONFIG_HOME:-$HOME/.config}/caffyne-shell/main.py" ]]; then
            missing+=("caffyne-shell")
        fi
        if (( ${#missing[@]} == 0 )); then
            log "${GREEN}Audit successful: core components present.${RESET}"
        else
            err "Audit failed: missing components: ${missing[*]}"
            exit 1
        fi
        ;;
    migrate)
        run_repo_script migrate.sh "${@:2}"
        ;;
    settings)
        fabric-cli exec caffyne-shell "bar_manager.toggle('Settings')" 2>/dev/null ||
            err "Caffyne Shell settings applet is unavailable."
        ;;
    emoji)
        run_repo_script fuzzel-emojis.sh
        ;;
    performance)
        run_repo_script performance.sh "${@:2}"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        err "Invalid command: $1"
        show_help
        exit 1
        ;;
esac
