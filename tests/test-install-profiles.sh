#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/bin" "$TEMP_DIR/home"
cat > "$TEMP_DIR/bin/pacman" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$TEMP_DIR/bin/pacman"

for component in fish waybar rofi dunst fuzzel wofi swaync wlogout swaylock kde-material-you-colors; do
    if [[ -d "$REPO_ROOT/config/$component" ]] &&
        [[ -n "$(find "$REPO_ROOT/config/$component" -type f -print -quit)" ]]; then
        printf 'Legacy component config remains: %s\n' "$component" >&2
        exit 1
    fi
done
[[ ! -e "$REPO_ROOT/config/hypr/hyprpaper.conf" ]]

run_profile() {
    local profile="$1"
    local output="$TEMP_DIR/$profile.out"
    HOME="$TEMP_DIR/home" \
        XDG_CONFIG_HOME="$TEMP_DIR/home/.config" \
        XDG_CACHE_HOME="$TEMP_DIR/home/.cache" \
        PATH="$TEMP_DIR/bin:$PATH" \
        TERM=xterm \
        "$REPO_ROOT/install.sh" \
        --dry-run --no-cleanup --no-migrate --yes --profile "$profile" \
        > "$output" 2>&1
}

run_profile minimal
grep -q 'Environment Tests' "$TEMP_DIR/minimal.out"
grep -q 'Linux operating system' "$TEMP_DIR/minimal.out"
grep -q 'Required repository files are present' "$TEMP_DIR/minimal.out"
grep -q 'Home, configuration, and local-bin paths are writable' "$TEMP_DIR/minimal.out"
grep -q 'All required environment tests passed' "$TEMP_DIR/minimal.out"
grep -q 'Skipping unselected optional fastfetch configuration.' "$TEMP_DIR/minimal.out"
grep -q 'Dry run: would install missing packages:' "$TEMP_DIR/minimal.out"
! grep -Eq 'Dry run: would install missing packages:.*(fish|fastfetch|yazi)' "$TEMP_DIR/minimal.out"
grep -q 'Dry run: would deploy caelestia' "$TEMP_DIR/minimal.out"
! grep -Eq 'Dry run: would install missing packages:.*(waybar|rofi|dunst|fuzzel|wofi|swaync|wlogout|swaylock|hyprpaper|network-manager-applet)' "$TEMP_DIR/minimal.out"

run_profile standard
grep -q 'Dry run: would install missing packages:.*fastfetch' "$TEMP_DIR/standard.out"
grep -q 'Dry run: would deploy fastfetch' "$TEMP_DIR/standard.out"
! grep -Eq 'Dry run: would install missing packages:.*(fish|yazi)' "$TEMP_DIR/standard.out"

run_profile extended
grep -q 'Dry run: would install missing packages:.*fastfetch yazi' "$TEMP_DIR/extended.out"
grep -q 'Dry run: would deploy caelestia' "$TEMP_DIR/extended.out"
grep -q 'Dry run: would deploy fastfetch' "$TEMP_DIR/extended.out"
! grep -Eq 'would (install missing packages|deploy).*(waybar|rofi|dunst|swaync|wlogout|fuzzel|wofi)' "$TEMP_DIR/extended.out"

run_profile custom
grep -q 'Skipping unselected optional fastfetch configuration.' "$TEMP_DIR/custom.out"
! grep -Eq 'Dry run: would install missing packages:.*(fish|fastfetch|yazi)' "$TEMP_DIR/custom.out"
! grep -Eq 'would (install missing packages|deploy).*(waybar|rofi|dunst|swaync|wlogout|fuzzel|wofi)' "$TEMP_DIR/custom.out"

cat > "$TEMP_DIR/bin/uname" <<'EOF'
#!/usr/bin/env bash
printf 'TestOS\n'
EOF
chmod +x "$TEMP_DIR/bin/uname"
if HOME="$TEMP_DIR/home" \
    XDG_CONFIG_HOME="$TEMP_DIR/home/.config" \
    XDG_CACHE_HOME="$TEMP_DIR/home/.cache" \
    PATH="$TEMP_DIR/bin:$PATH" \
    TERM=xterm \
    "$REPO_ROOT/install.sh" \
    --dry-run --no-cleanup --no-migrate --yes > "$TEMP_DIR/unsupported-os.out" 2>&1; then
    printf 'Environment preflight unexpectedly accepted a non-Linux platform.\n' >&2
    exit 1
fi
grep -q 'Linux is required' "$TEMP_DIR/unsupported-os.out"
grep -q 'required environment test(s) failed' "$TEMP_DIR/unsupported-os.out"
! grep -q 'System Scan' "$TEMP_DIR/unsupported-os.out"

printf 'Installation profile package/config selection passed.\n'
