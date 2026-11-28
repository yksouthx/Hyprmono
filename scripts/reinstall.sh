#!/usr/bin/env bash

# H Y P R M O N O - The Reinstaller
# Purpose: Total cleanup and fresh deployment from GitHub.

set -Eeuo pipefail

# --- Configuration ---
NEW_PATH="$HOME/.local/share/Hyprmono"
# Override to reinstall from a fork or a local mirror.
REPO_URL="${HYPRMONO_REPO_URL:-https://github.com/yksouthx/Hyprmono.git}"

# --- Colors ---
RED="\e[38;5;203m"
GREEN="\e[38;5;114m"
YELLOW="\e[38;5;222m"
CYAN="\e[38;5;117m"
BOLD="\e[1m"
RESET="\e[0m"

# --- Helpers ---
log() { printf '%b> %s%b\n' "${CYAN}" "$*" "${RESET}"; }
ok() { printf '%b✓%b %s\n' "${GREEN}" "${RESET}" "$*"; }
err() { printf '%b✗%b %s\n' "${RED}" "${RESET}" "$*" >&2; }

confirm() {
    local prompt="$1"

    if [[ ! -t 0 ]]; then
        err "Refusing destructive reinstall without an interactive confirmation."
        exit 1
    fi

    printf '%b?%b %s [y/N] ' "${BOLD}${YELLOW}" "${RESET}" "$prompt"
    read -r -n 1 reply
    printf '\n'

    [[ "$reply" =~ ^[Yy]$ ]] || exit 1
}

main() {
    [[ -t 1 ]] && clear
    printf '%bHyprMono Fresh Reinstallation%b\n' "${BOLD}" "${RESET}"
    printf 'This replaces the repository checkout and re-deploys all managed configs.\n'
    printf 'Existing configs are backed up to ~/.config-backup-<timestamp> first;\n'
    printf 'your niri/custom.kdl override is kept.\n\n'

    if [[ $EUID -eq 0 ]]; then
        err "Do not run this script as root."
        exit 1
    fi

    if ! command -v git >/dev/null 2>&1; then
        err "git is required for reinstall."
        exit 1
    fi

    confirm "Proceed with total reset?"

    # Clone FIRST. If this fails (offline, bad URL) nothing has been touched yet.
    local tmp_clone
    mkdir -p "$HOME/.local/share"
    tmp_clone=$(mktemp -d "$HOME/.local/share/.hyprmono-reinstall.XXXXXX")
    # shellcheck disable=SC2064
    trap "rm -rf -- '$tmp_clone'" EXIT

    log "Fetching a fresh copy of the repository..."
    if ! git clone --quiet "$REPO_URL" "$tmp_clone/repo"; then
        err "git clone failed; nothing was changed."
        exit 1
    fi
    ok "Fetched $REPO_URL"

    # Move the old checkout aside instead of deleting it: it may hold local edits.
    if [[ -e "$NEW_PATH" ]]; then
        local old_checkout
        old_checkout="$NEW_PATH.old-$(date +%Y%m%d-%H%M%S)"
        mv -- "$NEW_PATH" "$old_checkout"
        ok "Previous checkout kept at $old_checkout"
    fi
    mv -- "$tmp_clone/repo" "$NEW_PATH"
    ok "Deployed fresh repository to $NEW_PATH"

    # install.sh --wipe backs up every managed directory before removing it.
    log "Initializing Framework..."
    cd "$NEW_PATH"
    bash scripts/install.sh --no-migrate --wipe
}

main "$@"
