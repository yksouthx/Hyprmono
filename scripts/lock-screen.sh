#!/usr/bin/env bash
# Prefer Caffyne's native session lock and fall back to swaylock.
set -u

pgrep -x swaylock >/dev/null 2>&1 && exit 0

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
caffyne_root="$config_home/caffyne-shell"
caffyne_lock="$caffyne_root/lockscreen.py"
caffyne_python="$caffyne_root/venv/bin/python"

if [[ -r "$caffyne_lock" && -x "$caffyne_python" ]]; then
    if pgrep -f "$caffyne_lock" >/dev/null 2>&1; then
        exit 0
    fi

    if "$caffyne_python" "$caffyne_lock"; then
        exit 0
    else
        status=$?
        printf 'lock-screen: Caffyne lock failed (status %s); falling back to swaylock\n' "$status" >&2
    fi
fi

if ! command -v swaylock >/dev/null 2>&1; then
    printf 'lock-screen: neither Caffyne lock nor swaylock is available\n' >&2
    exit 1
fi

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
