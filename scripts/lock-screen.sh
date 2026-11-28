#!/usr/bin/env bash
# Lock the Niri session with swaylock.
set -u

if ! command -v swaylock >/dev/null 2>&1; then
    printf 'lock-screen: swaylock is not installed\n' >&2
    exit 1
fi

pgrep -x swaylock >/dev/null 2>&1 && exit 0
exec swaylock -f \
    --color 080808 \
    --inside-color 171717 \
    --ring-color cccccc \
    --key-hl-color ffffff \
    --line-color 000000 \
    --separator-color 444444 \
    --text-color ffffff \
    --ring-ver-color b0b0b0 \
    --inside-ver-color 202020 \
    --text-ver-color ffffff \
    --ring-wrong-color ffffff \
    --inside-wrong-color 303030 \
    --text-wrong-color ffffff
