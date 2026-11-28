#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/bin" "$TEMP_DIR/config/caffyne-shell"
cat > "$TEMP_DIR/config/caffyne-shell/start.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TEMP_DIR/config/caffyne-shell/start.sh"

cat > "$TEMP_DIR/bin/swayidle" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CAPTURE"
EOF
cat > "$TEMP_DIR/bin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$TEMP_DIR/bin/"*

HOME="$TEMP_DIR" \
XDG_CONFIG_HOME="$TEMP_DIR/config" \
PATH="$TEMP_DIR/bin:$PATH" \
CAPTURE="$TEMP_DIR/custom.out" \
    bash "$REPO_ROOT/scripts/start-idle.sh"
[[ ! -e "$TEMP_DIR/custom.out" ]]

rm "$TEMP_DIR/config/caffyne-shell/start.sh"
HOME="$TEMP_DIR" \
XDG_CONFIG_HOME="$TEMP_DIR/config" \
PATH="$TEMP_DIR/bin:$PATH" \
CAPTURE="$TEMP_DIR/fallback.out" \
    bash "$REPO_ROOT/scripts/start-idle.sh"
[[ "$(sed -n '1p' "$TEMP_DIR/fallback.out")" == "-w" ]]
grep -q 'niri msg action power-off-monitors' "$TEMP_DIR/fallback.out"
grep -q 'lock-screen.sh' "$TEMP_DIR/fallback.out"

printf 'Niri idle service selection passed.\n'
