#!/usr/bin/env bash
# Lock the session with Hyprlock.
set -u

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
lock_conf="$config_home/hypr/hyprlock/hyprlock.conf"

if ! command -v hyprlock >/dev/null 2>&1; then
    printf 'lock-screen: hyprlock is not installed\n' >&2
    exit 1
fi

pidof hyprlock >/dev/null 2>&1 && exit 0

if [[ -f "$lock_conf" ]]; then
    exec hyprlock -c "$lock_conf"
fi
exec hyprlock
