#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/config/hyprmono" "$TEMP_DIR/bin"
: > "$TEMP_DIR/config/hyprmono/Settings.qml"
: > "$TEMP_DIR/config/hyprmono/EmojiPicker.qml"
cat > "$TEMP_DIR/bin/quickshell" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$SETTINGS_CAPTURE"
EOF
chmod +x "$TEMP_DIR/bin/quickshell"

SETTINGS_CAPTURE="$TEMP_DIR/args" \
    XDG_CONFIG_HOME="$TEMP_DIR/config" \
    PATH="$TEMP_DIR/bin:$PATH" \
    bash "$REPO_ROOT/scripts/hyprmono.sh" settings

[[ "$(sed -n '1p' "$TEMP_DIR/args")" == "-n" ]]
[[ "$(sed -n '2p' "$TEMP_DIR/args")" == "-p" ]]
[[ "$(sed -n '3p' "$TEMP_DIR/args")" == "$TEMP_DIR/config/hyprmono/Settings.qml" ]]

SETTINGS_CAPTURE="$TEMP_DIR/args" \
    XDG_CONFIG_HOME="$TEMP_DIR/config" \
    PATH="$TEMP_DIR/bin:$PATH" \
    bash "$REPO_ROOT/scripts/hyprmono.sh" emoji

[[ "$(sed -n '1p' "$TEMP_DIR/args")" == "-n" ]]
[[ "$(sed -n '2p' "$TEMP_DIR/args")" == "-p" ]]
[[ "$(sed -n '3p' "$TEMP_DIR/args")" == "$TEMP_DIR/config/hyprmono/EmojiPicker.qml" ]]

printf 'Settings and emoji Quickshell command dispatch passed.\n'
