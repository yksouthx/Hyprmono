#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
THEME_DIR="$REPO_ROOT/assets/sddm/hyprmono"

for file in Main.qml metadata.desktop theme.conf wall.webp; do
    [[ -f "$THEME_DIR/$file" ]] || {
        printf 'Missing SDDM theme file: %s\n' "$file" >&2
        exit 1
    }
done

grep -q 'sddm.login(username.text, password.text, session.currentIndex)' "$THEME_DIR/Main.qml"
grep -q 'onLoginFailed' "$THEME_DIR/Main.qml"
grep -q 'onLoginSucceeded' "$THEME_DIR/Main.qml"
grep -q 'sddm.reboot()' "$THEME_DIR/Main.qml"
grep -q 'sddm.powerOff()' "$THEME_DIR/Main.qml"
grep -q 'background=wall.webp' "$THEME_DIR/theme.conf"

grep -q 'sddm' "$REPO_ROOT/scripts/install.sh"
grep -q 'install_sddm_theme' "$REPO_ROOT/scripts/install.sh"
grep -q 'remove_sddm_theme' "$REPO_ROOT/scripts/uninstall.sh"

printf 'SDDM theme checks passed.\n'
