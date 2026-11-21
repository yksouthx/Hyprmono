#!/usr/bin/env bash
set -euo pipefail

mode="${1:-type}"

usage() {
    printf 'Usage: %s [type|copy|both]\n' "$0" >&2
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'fuzzel-emojis: required command not found: %s\n' "$1" >&2
        exit 1
    fi
}

case "$mode" in
    type|copy|both) ;;
    *)
        usage
        exit 2
        ;;
esac

require_command fuzzel
data_file="${HYPRMONO_EMOJI_DATA:-$HOME/.config/hypr/assets/emoji-data.txt}"
if [[ ! -f "$data_file" && -n "${HYPRMONO_REPO:-}" ]]; then
    data_file="$HYPRMONO_REPO/assets/emoji-data.txt"
fi
if [[ ! -f "$data_file" ]]; then
    data_file="$(cd -- "$(dirname -- "$0")/.." 2>/dev/null && pwd)/assets/emoji-data.txt"
fi
if [[ ! -f "$data_file" ]]; then
    printf 'fuzzel-emojis: emoji data not found: %s\n' "$data_file" >&2
    exit 1
fi
if [[ "$mode" == "copy" ]]; then
    require_command wl-copy
elif [[ "$mode" == "type" ]]; then
    command -v wtype >/dev/null 2>&1 || require_command wl-copy
else
    require_command wl-copy
fi

selection=$(fuzzel --match-mode fzf --dmenu < "$data_file" || true)
emoji=$(printf '%s' "$selection" | awk 'NF { print $1; exit }')

[[ -n "$emoji" ]] || exit 0

case "$mode" in
    type)
        if command -v wtype >/dev/null 2>&1; then
            wtype "$emoji" || wl-copy "$emoji"
        else
            wl-copy "$emoji"
        fi
        ;;
    copy)
        wl-copy "$emoji"
        ;;
    both)
        if command -v wtype >/dev/null 2>&1; then
            wtype "$emoji" || true
        fi
        wl-copy "$emoji"
        ;;
esac

exit 0
