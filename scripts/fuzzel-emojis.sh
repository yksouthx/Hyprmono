#!/usr/bin/env bash
set -euo pipefail

if ! command -v hyprmono >/dev/null 2>&1; then
    printf 'fuzzel-emojis: run this after installing HyprMono; use `hyprmono emoji`.\n' >&2
    exit 1
fi

exec hyprmono emoji
