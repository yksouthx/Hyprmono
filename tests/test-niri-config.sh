#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
CONFIG_DIR="$REPO_ROOT/config/Niri/niri"

required_files=(
    config.kdl environment.kdl input.kdl layout.kdl monitors.kdl
    rules.kdl workspaces.kdl animations.kdl execs.kdl keybinds.kdl custom.kdl
)

for file in "${required_files[@]}"; do
    [[ -f "$CONFIG_DIR/$file" ]] || {
        printf 'Missing Niri config module: %s\n' "$file" >&2
        exit 1
    }
done

while IFS= read -r include; do
    [[ "$include" =~ ^include[[:space:]]+\"([^\"]+)\"$ ]] || continue
    module="${BASH_REMATCH[1]}"
    [[ -f "$CONFIG_DIR/$module" ]] || {
        printf 'Niri entrypoint includes missing module: %s\n' "$module" >&2
        exit 1
    }
done < "$CONFIG_DIR/config.kdl"

grep -q 'include "keybinds.kdl"' "$CONFIG_DIR/config.kdl"
grep -q 'include "workspaces.kdl"' "$CONFIG_DIR/config.kdl"
grep -q 'include "monitors.kdl"' "$CONFIG_DIR/config.kdl"
grep -q '^workspace "Music"$' "$CONFIG_DIR/workspaces.kdl"
grep -Fq 'match app-id=r#"(?i)^spotify$"#' "$CONFIG_DIR/rules.kdl"
grep -Fq 'match app-id=r#"(?i)^com\.spotify\.Client$"#' "$CONFIG_DIR/rules.kdl"
grep -Fq 'open-on-workspace "Music"' "$CONFIG_DIR/rules.kdl"
grep -Fq 'Mod+M repeat=false { focus-workspace "Music"; }' "$CONFIG_DIR/keybinds.kdl"
grep -Fq 'Mod+R repeat=false { spawn "bash" "-lc" "$HOME/.local/bin/launch-menu.sh"; }' "$CONFIG_DIR/keybinds.kdl"
grep -q 'default=gnome;gtk' "$REPO_ROOT/config/xdg-desktop-portal/niri-portals.conf"
grep -q 'NiriMono desktop configuration' "$CONFIG_DIR/config.kdl"
grep -q 'screenshot-path "~/Pictures/NiriMono/Screenshot-%Y-%m-%d_%H-%M-%S.png"' "$CONFIG_DIR/config.kdl"
grep -q 'center-focused-column "on-overflow"' "$CONFIG_DIR/layout.kdl"
! grep -q 'struts' "$CONFIG_DIR/layout.kdl"
grep -q 'Mod+O repeat=false { toggle-overview; }' "$CONFIG_DIR/keybinds.kdl"
grep -q 'Mod+WheelScrollDown' "$CONFIG_DIR/keybinds.kdl"
! grep -q 'Mod+MouseForward\|Mod+MouseBackward' "$CONFIG_DIR/keybinds.kdl"
if grep -RqiE 'hyprland|hyprcursor|hyprctl' "$CONFIG_DIR"; then
    printf 'Niri config contains a Hyprland-specific setting or reference.\n' >&2
    exit 1
fi

printf 'Niri modular config checks passed.\n'
