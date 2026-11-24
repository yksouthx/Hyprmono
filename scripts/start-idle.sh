#!/usr/bin/env bash
# Start the idle/lock fallback (hypridle + hyprlock) ONLY when Caelestia is not
# present. Caelestia ships its own idle monitor (lock -> dpms off -> suspend) and
# its own lock screen; running hypridle next to it means two lock screens and two
# DPMS timers fighting each other.
set -u

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock/hypridle.conf"

if command -v caelestia >/dev/null 2>&1 \
    || { command -v qs >/dev/null 2>&1 && [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia" ]]; }; then
    exit 0
fi

command -v hypridle >/dev/null 2>&1 || exit 0
pgrep -x hypridle >/dev/null 2>&1 && exit 0

if [[ -f "$CONF" ]]; then
    exec hypridle -c "$CONF"
fi
exec hypridle
