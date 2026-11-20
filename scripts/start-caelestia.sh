#!/usr/bin/env bash
# Start Caelestia only when it is installed, keeping Hyprland usable without it.
set -u

if command -v caelestia >/dev/null 2>&1; then
    exec caelestia shell -d
fi

if command -v qs >/dev/null 2>&1 && [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia" ]]; then
    exec qs -c caelestia -n -d
fi

exit 0
