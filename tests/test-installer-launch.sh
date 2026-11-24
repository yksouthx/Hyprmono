#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/bin"
cat > "$TEMP_DIR/bin/quickshell" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$QS_CAPTURE"
EOF
cat > "$TEMP_DIR/bin/kitty" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$TERMINAL_CAPTURE"
EOF
chmod +x "$TEMP_DIR/bin/quickshell" "$TEMP_DIR/bin/kitty"

QS_CAPTURE="$TEMP_DIR/quickshell-args" \
    PATH="$TEMP_DIR/bin:$PATH" \
    WAYLAND_DISPLAY=wayland-test \
    "$REPO_ROOT/install.sh"

[[ "$(sed -n '1p' "$TEMP_DIR/quickshell-args")" == "-p" ]]
[[ "$(sed -n '2p' "$TEMP_DIR/quickshell-args")" == "$REPO_ROOT/config/installer/Installer.qml" ]]

TERMINAL_CAPTURE="$TEMP_DIR/terminal-args" \
    PATH="$TEMP_DIR/bin:$PATH" \
    bash "$REPO_ROOT/scripts/run-installer-terminal" \
    "$REPO_ROOT/scripts/install.sh" --terminal --minimal

[[ "$(sed -n '1p' "$TEMP_DIR/terminal-args")" == "--" ]]
[[ "$(sed -n '2p' "$TEMP_DIR/terminal-args")" == "bash" ]]
[[ "$(sed -n '3p' "$TEMP_DIR/terminal-args")" == "$REPO_ROOT/scripts/install.sh" ]]
[[ "$(sed -n '4p' "$TEMP_DIR/terminal-args")" == "--terminal" ]]
[[ "$(sed -n '5p' "$TEMP_DIR/terminal-args")" == "--minimal" ]]

printf 'Installer GUI dispatch and terminal argument forwarding passed.\n'
