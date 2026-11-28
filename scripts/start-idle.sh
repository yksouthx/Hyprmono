#!/usr/bin/env bash
# Caffyne Shell owns its idle helpers; otherwise start swayidle for Niri.
set -u

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

[[ -x "$config_home/caffyne-shell/start.sh" ]] && exit 0

command -v swayidle >/dev/null 2>&1 || exit 0
pgrep -x swayidle >/dev/null 2>&1 && exit 0

exec swayidle -w \
    timeout 300 "$HOME/.local/bin/lock-screen.sh" \
    timeout 600 "niri msg action power-off-monitors" \
    resume "niri msg action power-on-monitors" \
    before-sleep "$HOME/.local/bin/lock-screen.sh"
