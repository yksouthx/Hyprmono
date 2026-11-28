#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

export HOME="$TEMP_DIR/home"
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share" XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$HOME/.config/waybar" "$HOME/.config/rofi" "$HOME/.config/dunst" "$HOME/.config/wofi" \
    "$HOME/.config/swaync" "$HOME/.config/hyprpaper" "$HOME/.local/bin" "$TEMP_DIR/bin"
echo bar > "$HOME/.config/waybar/config.jsonc"
echo launcher > "$HOME/.config/rofi/config.rasi"
echo notifications > "$HOME/.config/dunst/dunstrc"
echo launcher2 > "$HOME/.config/wofi/config"
echo daemon > "$HOME/.config/swaync/config.json"
echo wall > "$HOME/.config/hyprpaper/hyprpaper.conf"
echo old > "$HOME/.local/bin/hyde"

cat > "$TEMP_DIR/bin/pacman" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    -Qq)
        [[ "${2:-}" == rofi ]]
        ;;
    -Qi)
        [[ "${2:-}" == rofi ]] || exit 1
        printf 'Name            : rofi\nRequired By     : None\n'
        ;;
    *)
        exit 1
        ;;
esac
EOF
chmod +x "$TEMP_DIR/bin/pacman"
export PATH="$TEMP_DIR/bin:$PATH"

# --- dry run: Caffyne-replaced Waybar/Rofi are reported; other services are preserved
out="$(bash "$REPO_ROOT/scripts/migrate.sh" --dry-run 2>&1 </dev/null)"
grep -q 'waybar' <<< "$out"
grep -q 'rofi' <<< "$out"
grep -q 'hyde' <<< "$out"
grep -q 'application menu replaced by Caffyne Dash' <<< "$out"
for kept in dunst wofi swaync hyprpaper; do
    if grep -qi "config/$kept" <<< "$out"; then
        echo "migrate.sh must not offer to remove $kept" >&2
        exit 1
    fi
done
[[ -e "$HOME/.config/waybar/config.jsonc" ]]

# --- non-interactive run (no tty): nothing is removed
bash "$REPO_ROOT/scripts/migrate.sh" >/dev/null 2>&1 </dev/null || true
for kept in waybar rofi dunst wofi swaync hyprpaper; do
    [[ -d "$HOME/.config/$kept" ]]
done
[[ -e "$HOME/.local/bin/hyde" ]]

# --- rollback refuses directories outside the migration state directory
mkdir -p "$TEMP_DIR/not-a-backup"
if bash "$REPO_ROOT/scripts/migrate.sh" --rollback "$TEMP_DIR/not-a-backup" >/dev/null 2>&1; then
    echo "rollback must reject a directory outside the migration state dir" >&2
    exit 1
fi

printf 'Migration checks passed.\n'
