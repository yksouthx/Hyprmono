#!/usr/bin/env bash
# Caffyne Shell owns its lock/session helpers; otherwise use Hyprmono's Hypridle config.
set -u

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
conf="$config_home/hypr/hyprlock/hypridle.conf"

[[ -x "$config_home/caffyne-shell/start.sh" ]] && exit 0

command -v hypridle >/dev/null 2>&1 || exit 0
pgrep -x hypridle >/dev/null 2>&1 && exit 0

if [[ -f "$conf" ]]; then
    exec hypridle -c "$conf"
fi
exec hypridle
