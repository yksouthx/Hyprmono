#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/bin" "$TEMP_DIR/config/hyprmono" "$TEMP_DIR/config/hypr/hyprlock"
touch "$TEMP_DIR/config/hyprmono/shell.qml"
touch "$TEMP_DIR/config/hypr/hyprlock/hypridle.conf"

cat > "$TEMP_DIR/bin/hypridle" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CAPTURE"
EOF
cat > "$TEMP_DIR/bin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
cat > "$TEMP_DIR/bin/quickshell" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$TEMP_DIR/bin/caelestia" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TEMP_DIR/bin/"*

HOME="$TEMP_DIR" \
XDG_CONFIG_HOME="$TEMP_DIR/config" \
PATH="$TEMP_DIR/bin:$PATH" \
CAPTURE="$TEMP_DIR/custom.out" \
    bash "$REPO_ROOT/scripts/start-idle.sh"
[[ "$(sed -n '1p' "$TEMP_DIR/custom.out")" == "-c" ]]
[[ "$(sed -n '2p' "$TEMP_DIR/custom.out")" == "$TEMP_DIR/config/hypr/hyprlock/hypridle.conf" ]]

rm "$TEMP_DIR/config/hyprmono/shell.qml"
rm "$TEMP_DIR/custom.out"
HOME="$TEMP_DIR" \
XDG_CONFIG_HOME="$TEMP_DIR/config" \
PATH="$TEMP_DIR/bin:$PATH" \
CAPTURE="$TEMP_DIR/fallback.out" \
    bash "$REPO_ROOT/scripts/start-idle.sh"
[[ ! -e "$TEMP_DIR/fallback.out" ]]

printf 'Idle service selection passed for both shells.\n'
