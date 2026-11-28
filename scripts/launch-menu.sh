#!/usr/bin/env bash
# Open an application launcher: Caelestia's when its shortcut is registered,
# otherwise the first installed of fuzzel, wofi or rofi.
set -u

if command -v hyprctl >/dev/null 2>&1 \
    && hyprctl globalshortcuts 2>/dev/null | grep -q 'caelestia:launcher'; then
    exec hyprctl dispatch 'hl.dsp.global("caelestia:launcher")'
fi

if command -v fuzzel >/dev/null 2>&1; then
    exec fuzzel
elif command -v wofi >/dev/null 2>&1; then
    exec wofi --show drun
elif command -v rofi >/dev/null 2>&1; then
    exec rofi -show drun
fi

message='No application launcher found. Install fuzzel, wofi or rofi (or Caelestia).'
printf 'launch-menu: %s\n' "$message" >&2
if command -v notify-send >/dev/null 2>&1; then
    notify-send 'HyprMono' "$message" 2>/dev/null || true
fi
exit 1
