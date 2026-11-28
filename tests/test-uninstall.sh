#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

if [[ $EUID -eq 0 ]]; then
    echo "SKIP: the installer scripts refuse to run as root; run this test as a normal user"
    exit 0
fi

if ! command -v script >/dev/null 2>&1; then
    echo "SKIP: 'script' (util-linux) is needed to give the uninstaller a terminal"
    exit 0
fi

export HOME="$TEMP_DIR/home"
unset XDG_CONFIG_HOME
mkdir -p "$HOME/.config/hypr" "$HOME/.config/hyprmono" "$HOME/.config/fish" "$HOME/.config/rofi" \
    "$HOME/.local/bin" "$HOME/.cache/Hyprmono"
echo deployed > "$HOME/.config/hypr/hyprland.lua"
echo "user fish config" > "$HOME/.config/fish/config.fish"
echo "user rofi config" > "$HOME/.config/rofi/config.rasi"
for name in hyprmono.sh start-shell.sh start-idle.sh launch-menu.sh lock-screen.sh; do
    printf '#!/bin/sh\n' > "$HOME/.local/bin/$name"
done
ln -s "$HOME/.local/bin/hyprmono.sh" "$HOME/.local/bin/hyprmono"
echo "unrelated" > "$HOME/.local/bin/my-own-tool"

# The installer records what it deployed; uninstall must stay inside that list.
printf 'hypr\nhyprmono\n../../etc\n..\n' > "$HOME/.cache/Hyprmono/deployed-targets"

# The first backup holds the user's ORIGINAL config and is what uninstall restores.
mkdir -p "$HOME/.config-backup-20260101-000000/hypr"
echo "original hypr" > "$HOME/.config-backup-20260101-000000/hypr/hyprland.conf"
printf '%s\n' "$HOME/.config-backup-20260101-000000" > "$HOME/.cache/Hyprmono/original-backup"
mkdir -p "$HOME/.config-backup-20260202-000000/hypr"
echo "later hyprmono install" > "$HOME/.config-backup-20260202-000000/hypr/hyprland.lua"

script -qec "bash '$REPO_ROOT/scripts/uninstall.sh'" /dev/null <<< "yy" >"$TEMP_DIR/uninstall.out" 2>&1 || {
    cat "$TEMP_DIR/uninstall.out" >&2
    exit 1
}

# Managed directories are gone; the original hypr config is back (not the later backup).
[[ ! -e "$HOME/.config/hyprmono" ]]
[[ ! -e "$HOME/.config/hypr/hyprland.lua" ]]
[[ "$(< "$HOME/.config/hypr/hyprland.conf")" == "original hypr" ]]

# Unrelated user data must survive.
[[ "$(< "$HOME/.config/fish/config.fish")" == "user fish config" ]]
[[ "$(< "$HOME/.config/rofi/config.rasi")" == "user rofi config" ]]
[[ -e "$HOME/.local/bin/my-own-tool" ]]

# Installed helpers and the command link are removed.
for name in hyprmono hyprmono.sh start-shell.sh start-idle.sh launch-menu.sh lock-screen.sh; do
    [[ ! -e "$HOME/.local/bin/$name" && ! -L "$HOME/.local/bin/$name" ]]
done

# Path-traversal entries in the deployment record are ignored.
[[ -d "$TEMP_DIR/home/.config" ]]

printf 'Uninstall checks passed.\n'
