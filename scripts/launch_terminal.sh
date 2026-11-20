#!/usr/bin/env bash
# Launch Kitty with Calm-shell when installed, otherwise open a normal terminal.
set -u

if ! command -v kitty >/dev/null 2>&1; then
    printf 'launch_terminal: kitty is not installed\n' >&2
    exit 1
fi

if [[ -x "$HOME/.local/bin/calm" ]]; then
    exec kitty -1 "$HOME/.local/bin/calm"
fi

exec kitty -1
