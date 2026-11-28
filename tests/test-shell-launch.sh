#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

[[ -s "$REPO_ROOT/config/quickshell/assets/wall.webp" ]]
grep -q 'source: Qt.resolvedUrl("assets/wall.webp")' \
    "$REPO_ROOT/config/quickshell/Wallpaper.qml"

mkdir -p "$TEMP_DIR/bin" "$TEMP_DIR/config/hyprmono"
touch "$TEMP_DIR/config/hyprmono/shell.qml"

cat > "$TEMP_DIR/bin/quickshell" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CAPTURE"
EOF
cat > "$TEMP_DIR/bin/caelestia" <<'EOF'
#!/usr/bin/env bash
printf 'caelestia %s\n' "$*" > "$CAPTURE"
EOF
chmod +x "$TEMP_DIR/bin/quickshell" "$TEMP_DIR/bin/caelestia"

HOME="$TEMP_DIR" \
XDG_CONFIG_HOME="$TEMP_DIR/config" \
PATH="$TEMP_DIR/bin:$PATH" \
CAPTURE="$TEMP_DIR/launch.out" \
    bash "$REPO_ROOT/scripts/start-shell.sh"

[[ "$(sed -n '1p' "$TEMP_DIR/launch.out")" == "-n" ]]
[[ "$(sed -n '2p' "$TEMP_DIR/launch.out")" == "-p" ]]
[[ "$(sed -n '3p' "$TEMP_DIR/launch.out")" == "$TEMP_DIR/config/hyprmono/shell.qml" ]]
[[ "$(sed -n '4p' "$TEMP_DIR/launch.out")" == "-d" ]]

rm "$TEMP_DIR/config/hyprmono/shell.qml"
HOME="$TEMP_DIR" \
XDG_CONFIG_HOME="$TEMP_DIR/config" \
PATH="$TEMP_DIR/bin:$PATH" \
CAPTURE="$TEMP_DIR/fallback.out" \
    bash "$REPO_ROOT/scripts/start-shell.sh"
grep -q '^caelestia shell -d$' "$TEMP_DIR/fallback.out"

printf 'Quickshell startup and Caelestia fallback passed.\n'
