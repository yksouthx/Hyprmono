#!/usr/bin/env bash
# Lock the session with whichever lock screen is actually available:
# Caelestia's when the shell has registered its global shortcut, else hyprlock.
set -u

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
lock_conf="$config_home/hypr/hyprlock/hyprlock.conf"

if command -v hyprctl >/dev/null 2>&1 \
    && hyprctl globalshortcuts 2>/dev/null | grep -q 'caelestia:lock'; then
    exec hyprctl dispatch 'hl.dsp.global("caelestia:lock")'
fi

if ! command -v hyprlock >/dev/null 2>&1; then
    printf 'lock-screen: hyprlock is not installed\n' >&2
    exit 1
fi

pidof hyprlock >/dev/null 2>&1 && exit 0

if [[ -f "$lock_conf" ]]; then
    exec hyprlock -c "$lock_conf"
fi
exec hyprlock
