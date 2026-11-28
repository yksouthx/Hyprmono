#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

grep -q '^bars = 12$' "$REPO_ROOT/assets/caffyne-shell/cava.conf"
grep -q 'bar-cava' "$REPO_ROOT/assets/caffyne-shell/hyprmono.css"
grep -q 'border-radius: 999px' "$REPO_ROOT/assets/caffyne-shell/hyprmono.css"
grep -q '_read_cava' "$REPO_ROOT/assets/caffyne-shell/media.py"
grep -q '"Focused"' "$REPO_ROOT/assets/caffyne-shell/config.json"
grep -q '"Processes"' "$REPO_ROOT/assets/caffyne-shell/config.json"
grep -q '"RAM"' "$REPO_ROOT/assets/caffyne-shell/config.json"
grep -q '__HYPRMONO_WALLPAPER__' "$REPO_ROOT/assets/caffyne-shell/config.json"

mkdir -p "$TEMP_DIR/bin" "$TEMP_DIR/config/caffyne-shell"
cat > "$TEMP_DIR/config/caffyne-shell/start.sh" <<'EOF'
#!/usr/bin/env bash
printf 'caffyne shell started\n' > "$CAPTURE"
EOF
chmod +x "$TEMP_DIR/config/caffyne-shell/start.sh"

HOME="$TEMP_DIR" \
XDG_CONFIG_HOME="$TEMP_DIR/config" \
PATH="$TEMP_DIR/bin:$PATH" \
CAPTURE="$TEMP_DIR/launch.out" \
    bash "$REPO_ROOT/scripts/start-shell.sh"

rm "$TEMP_DIR/config/caffyne-shell/start.sh"
HOME="$TEMP_DIR" \
XDG_CONFIG_HOME="$TEMP_DIR/config" \
PATH="$TEMP_DIR/bin:$PATH" \
CAPTURE="$TEMP_DIR/no-shell.out" \
    bash "$REPO_ROOT/scripts/start-shell.sh"

grep -q '^caffyne shell started$' "$TEMP_DIR/launch.out"
[[ ! -e "$TEMP_DIR/no-shell.out" ]]

printf 'Caffyne Shell startup passed.\n'
