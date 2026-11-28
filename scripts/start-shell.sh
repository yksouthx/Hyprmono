#!/usr/bin/env bash
# Start Caffyne Shell, HyprMono's desktop-shell runtime.
set -u

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
caffyne_start="$config_home/caffyne-shell/start.sh"
if [[ -x "$caffyne_start" ]]; then
    exec "$caffyne_start"
fi

# Compatibility launcher for installations that use Caffyne's legacy clone layout.
caffyne_clone="$config_home/caffyne-shell/main.py"
caffyne_venv="$config_home/caffyne-shell/venv/bin/python"
if [[ -r "$caffyne_clone" && -x "$caffyne_venv" ]]; then
    exec "$caffyne_venv" "$caffyne_clone"
fi

exit 0
