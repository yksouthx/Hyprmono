#!/usr/bin/env bash

set -Eeuo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "SKIP: the installer scripts refuse to run as root; run this test as a normal user"
    exit 0
fi

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/bin" "$TEMP_DIR/home"
cat > "$TEMP_DIR/bin/pacman" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$TEMP_DIR/bin/pacman"

for component in fish waybar rofi dunst wofi swaync wlogout swaylock kde-material-you-colors; do
    if [[ -d "$REPO_ROOT/config/$component" ]] &&
        [[ -n "$(find "$REPO_ROOT/config/$component" -type f -print -quit)" ]]; then
        printf 'Legacy component config remains: %s\n' "$component" >&2
        exit 1
    fi
done
[[ ! -e "$REPO_ROOT/config/Hyprland" ]]

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
grep -Eq 'Dry run: would install missing packages:.*cava' "$TEMP_DIR/minimal.out"
grep -Eq 'Dry run: would install missing packages:.*niri' "$TEMP_DIR/minimal.out"
grep -Eq 'Dry run: would install missing packages:.*swayidle' "$TEMP_DIR/minimal.out"
grep -Eq 'Dry run: would install missing packages:.*swaylock' "$TEMP_DIR/minimal.out"
! grep -Eqi 'Dry run: would install missing packages:.*(hyprland|hyprlock|hypridle|hyprcursor|xdg-desktop-portal-hyprland)' "$TEMP_DIR/minimal.out"
! grep -Eq 'Dry run: would install missing packages:.*(fish|fastfetch|yazi)' "$TEMP_DIR/minimal.out"
grep -q "Dry run: would deploy niri to $TEMP_DIR/home/.config/" "$TEMP_DIR/minimal.out"
! grep -q "Dry run: would deploy hypr to $TEMP_DIR/home/.config/" "$TEMP_DIR/minimal.out"
! grep -Eq 'Dry run: would install missing packages:.*(waybar|rofi|dunst|wofi|swaync|wlogout|swaylock|hyprpaper)' "$TEMP_DIR/minimal.out"
# The project shell ships its own bar; fuzzel (launcher), fnott (notifications) and the
# network applet (shown from the bar's tray) are part of every profile.
grep -Eq 'Dry run: would install missing packages:.*fuzzel' "$TEMP_DIR/minimal.out"
grep -Eq 'Dry run: would install missing packages:.*fnott' "$TEMP_DIR/minimal.out"
grep -Eq 'Dry run: would install missing packages:.*network-manager-applet' "$TEMP_DIR/minimal.out"
grep -Eq 'Dry run: would install missing packages:.*sddm' "$TEMP_DIR/minimal.out"
grep -q "Dry run: would deploy fuzzel to $TEMP_DIR/home/.config/" "$TEMP_DIR/minimal.out"
grep -q "Dry run: would deploy fnott to $TEMP_DIR/home/.config/" "$TEMP_DIR/minimal.out"

run_profile standard
grep -q 'Dry run: would install missing packages:.*fastfetch' "$TEMP_DIR/standard.out"
grep -q 'Dry run: would deploy fastfetch' "$TEMP_DIR/standard.out"
! grep -Eq 'Dry run: would install missing packages:.*(fish|yazi)' "$TEMP_DIR/standard.out"

run_profile extended
grep -q 'Dry run: would install missing packages:.*fastfetch yazi' "$TEMP_DIR/extended.out"
grep -q 'Dry run: would deploy fastfetch' "$TEMP_DIR/extended.out"
! grep -Eq 'would (install missing packages|deploy).*(waybar|rofi|dunst|swaync|wlogout|wofi)' "$TEMP_DIR/extended.out"

run_profile custom
grep -q 'Skipping unselected optional fastfetch configuration.' "$TEMP_DIR/custom.out"
! grep -Eq 'Dry run: would install missing packages:.*(fish|fastfetch|yazi)' "$TEMP_DIR/custom.out"
! grep -Eq 'would (install missing packages|deploy).*(waybar|rofi|dunst|swaync|wlogout|wofi)' "$TEMP_DIR/custom.out"

cat > "$TEMP_DIR/bin/fc-cache" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TEMP_DIR/bin/fc-cache"
mkdir -p "$TEMP_DIR/home/.local/bin"
mkdir -p "$TEMP_DIR/home/.config/niri"
mkdir -p "$TEMP_DIR/home/.config/hypr"
printf 'old managed Hyprland config\n' > "$TEMP_DIR/home/.config/hypr/hyprland.lua"
mkdir -p "$TEMP_DIR/home/.cache/Hyprmono"
printf 'hypr\n' > "$TEMP_DIR/home/.cache/Hyprmono/deployed-targets"
printf '// personal niri override\n' > "$TEMP_DIR/home/.config/niri/custom.kdl"
printf 'stale developer copy\n' > "$TEMP_DIR/home/.local/bin/watch-quality.sh"
printf 'stale compositor profile helper\n' > "$TEMP_DIR/home/.local/bin/profile.sh"
HOME="$TEMP_DIR/home" \
    XDG_CONFIG_HOME="$TEMP_DIR/home/.config" \
    XDG_CACHE_HOME="$TEMP_DIR/home/.cache" \
    PATH="$TEMP_DIR/bin:$PATH" \
    TERM=xterm \
    "$REPO_ROOT/install.sh" \
    --terminal --skip-deps --skip-aur --no-cleanup --no-migrate --yes --wipe \
    > "$TEMP_DIR/deployment.out" 2>&1
[[ ! -e "$TEMP_DIR/home/.local/bin/watch-quality.sh" ]]
[[ ! -e "$TEMP_DIR/home/.local/bin/profile.sh" ]]
[[ ! -e "$TEMP_DIR/home/.config/hypr" ]]
[[ -f "$TEMP_DIR/home/.config/niri/config.kdl" ]]
[[ -f "$TEMP_DIR/home/.config/niri/keybinds.kdl" ]]
[[ -f "$TEMP_DIR/home/.config/niri/workspaces.kdl" ]]
grep -q 'personal niri override' "$TEMP_DIR/home/.config/niri/custom.kdl"
backup_dir=$(< "$TEMP_DIR/home/.cache/Hyprmono/original-backup")
[[ "$(< "$backup_dir/hypr/hyprland.lua")" == "old managed Hyprland config" ]]
[[ "$(< "$backup_dir/.local-bin/profile.sh")" == "stale compositor profile helper" ]]

mkdir -p "$TEMP_DIR/failure-home" "$TEMP_DIR/bin"
cat > "$TEMP_DIR/bin/pacman" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == "-Qi" ]] && exit 1
[[ "$1" == "-S" ]] && exit 1
exit 2
EOF
cat > "$TEMP_DIR/bin/sudo" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    -n) exit 1 ;;
    -v) exit 0 ;;
    *) shift; exec "$@" ;;
esac
EOF
chmod +x "$TEMP_DIR/bin/pacman" "$TEMP_DIR/bin/sudo"
if HOME="$TEMP_DIR/failure-home" \
    XDG_CONFIG_HOME="$TEMP_DIR/failure-home/.config" \
    XDG_CACHE_HOME="$TEMP_DIR/failure-home/.cache" \
    PATH="$TEMP_DIR/bin:$PATH" \
    TERM=xterm \
    "$REPO_ROOT/install.sh" \
    --terminal --no-cleanup --no-migrate --yes > "$TEMP_DIR/package-failure.out" 2>&1; then
    printf 'Installer continued after pacman failed to install required packages.\n' >&2
    exit 1
fi
grep -q 'Pacman failed to install some packages' "$TEMP_DIR/package-failure.out"
! grep -q 'Installation Complete' "$TEMP_DIR/package-failure.out"
[[ ! -e "$TEMP_DIR/failure-home/.config/niri/config.kdl" ]]

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
