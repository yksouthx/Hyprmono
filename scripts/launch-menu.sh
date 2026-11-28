#!/usr/bin/env bash
# Toggle the Caffyne Dash, which provides the app menu and shell controls.
set -u

if ! command -v fabric-cli >/dev/null 2>&1; then
    printf 'launch-menu: fabric-cli is not installed; Caffyne Dash is unavailable\n' >&2
    exit 1
fi

exec fabric-cli exec caffyne-shell "bar_manager.toggle('Dash')"
