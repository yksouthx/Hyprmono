#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/rebuild-quickshell.sh

Rebuild the Quickshell package against the currently installed Qt using paru
or yay. The AUR helper will show its package plan and ask before proceeding.
EOF
}

if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
    usage
    exit 0
fi
if (( $# != 0 )); then
    usage >&2
    exit 2
fi
if (( EUID == 0 )); then
    printf 'Do not run this script as root; the AUR helper will request privileges when needed.\n' >&2
    exit 1
fi
if ! command -v pacman >/dev/null 2>&1; then
    printf 'pacman is required; this helper is for Arch-based systems only.\n' >&2
    exit 1
fi
if ! command -v quickshell >/dev/null 2>&1 && ! command -v qs >/dev/null 2>&1; then
    printf 'Quickshell is not installed; refusing to build an unused package.\n' >&2
    exit 1
fi

if command -v paru >/dev/null 2>&1; then
    helper=$(command -v paru)
elif command -v yay >/dev/null 2>&1; then
    helper=$(command -v yay)
else
    printf 'Install paru or yay, then rerun this script to rebuild Quickshell.\n' >&2
    exit 1
fi

printf 'Rebuilding Quickshell against the installed Qt with %s.\n' "$(basename "$helper")"
exec "$helper" -S --rebuild quickshell
