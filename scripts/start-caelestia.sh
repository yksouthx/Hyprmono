#!/usr/bin/env bash
# Start Hyprmono's Quickshell UI, with Caelestia as a compatibility fallback.
set -u

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
shell_file="$config_home/hyprmono/shell.qml"

if [[ -r "$shell_file" ]]; then
    if command -v quickshell >/dev/null 2>&1; then
        exec quickshell -n -p "$shell_file" -d
    fi
    if command -v qs >/dev/null 2>&1; then
        exec qs -n -p "$shell_file" -d
    fi
fi

if command -v caelestia >/dev/null 2>&1; then
    exec caelestia shell -d
fi

if command -v qs >/dev/null 2>&1 && [[ -d "$config_home/quickshell/caelestia" ]]; then
    exec qs -c caelestia -n -d
fi

exit 0
