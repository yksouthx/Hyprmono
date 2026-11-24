#!/usr/bin/env bash
# Hyprmono's Quickshell UI uses hypridle for locking; Caelestia has its own.
set -u

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
conf="$config_home/hypr/hyprlock/hypridle.conf"
custom_shell="$config_home/hyprmono/shell.qml"
custom_shell_available=0

if [[ -r "$custom_shell" ]] &&
    { command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1; }; then
    custom_shell_available=1
fi

if (( custom_shell_available == 0 )); then
    if command -v caelestia >/dev/null 2>&1; then
        exit 0
    fi
    if command -v qs >/dev/null 2>&1 && [[ -d "$config_home/quickshell/caelestia" ]]; then
        exit 0
    fi
fi

command -v hypridle >/dev/null 2>&1 || exit 0
pgrep -x hypridle >/dev/null 2>&1 && exit 0

if [[ -f "$conf" ]]; then
    exec hypridle -c "$conf"
fi
exec hypridle
