#!/usr/bin/env bash
# Pick an emoji with Fuzzel and copy it to the Wayland clipboard.
set -Eeuo pipefail

readonly DATA_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/Hyprmono/emoji-data.txt"
fallback="/usr/share/hyprmono/emoji-data.txt"

if [[ -r "$DATA_FILE" ]]; then
    emoji_file="$DATA_FILE"
elif [[ -r "$fallback" ]]; then
    emoji_file="$fallback"
else
    emoji_file="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/assets/emoji-data.txt"
fi

command -v fuzzel >/dev/null 2>&1 || {
    printf 'fuzzel-emojis: fuzzel is not installed\n' >&2
    exit 1
}
command -v wl-copy >/dev/null 2>&1 || {
    printf 'fuzzel-emojis: wl-copy is not installed\n' >&2
    exit 1
}

selection=$(fuzzel --dmenu --prompt "Emoji " < "$emoji_file") || exit 0
emoji=${selection%%[[:space:]]*}
[[ -n "$emoji" ]] || exit 0
printf '%s' "$emoji" | wl-copy
