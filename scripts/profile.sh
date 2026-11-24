#!/usr/bin/env bash

set -Eeuo pipefail

readonly PROFILE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/profile"
readonly LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/Hyprmono/profile.log"

current_profile() {
    if [[ -r "$PROFILE_FILE" ]]; then
        IFS= read -r profile < "$PROFILE_FILE" || true
        if [[ "$profile" == "low-resource" || "$profile" == "balanced" || "$profile" == "full-visual" ]]; then
            printf '%s\n' "$profile"
            return
        fi
    fi
    printf '%s\n' "full-visual"
}

case "${1:-show}" in
    show)
        printf 'HyprMono compositor profile: %s\n' "$(current_profile)"
        ;;
    low-resource|balanced|full-visual)
        mkdir -p "$(dirname "$PROFILE_FILE")"
        temporary_file=$(mktemp "${PROFILE_FILE}.XXXXXX")
        printf '%s\n' "$1" > "$temporary_file"
        mv -f -- "$temporary_file" "$PROFILE_FILE"
        mkdir -p "$(dirname "$LOG_FILE")"
        printf '[%s] Set compositor profile to %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
        printf 'Set HyprMono compositor profile to %s.\n' "$1"
        if command -v hyprctl >/dev/null 2>&1; then
            if ! hyprctl reload; then
                printf 'Profile saved, but Hyprland reload failed; reload it manually.\n' >&2
                exit 1
            fi
        else
            printf 'Profile saved; reload Hyprland to apply it.\n'
        fi
        ;;
    --help|-h)
        printf 'Usage: hyprmono profile [show|low-resource|balanced|full-visual]\n'
        ;;
    *)
        printf 'Invalid profile: %s\nUsage: hyprmono profile [show|low-resource|balanced|full-visual]\n' "$1" >&2
        exit 2
        ;;
esac
