#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/bin"
cat > "$TEMP_DIR/bin/fabric-cli" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$SETTINGS_CAPTURE"
EOF
chmod +x "$TEMP_DIR/bin/fabric-cli"
cat > "$TEMP_DIR/bin/fuzzel" <<'EOF'
#!/usr/bin/env bash
printf '😀 grinning face\n'
EOF
cat > "$TEMP_DIR/bin/wl-copy" <<'EOF'
#!/usr/bin/env bash
cat > "$EMOJI_CAPTURE"
EOF
chmod +x "$TEMP_DIR/bin/fuzzel" "$TEMP_DIR/bin/wl-copy"

SETTINGS_CAPTURE="$TEMP_DIR/args" \
    XDG_CONFIG_HOME="$TEMP_DIR/config" \
    PATH="$TEMP_DIR/bin:$PATH" \
    bash "$REPO_ROOT/scripts/hyprmono.sh" settings

grep -q "^exec$" "$TEMP_DIR/args"
grep -q "^bar_manager.toggle('Settings')$" "$TEMP_DIR/args"

EMOJI_CAPTURE="$TEMP_DIR/emoji" \
    XDG_CONFIG_HOME="$TEMP_DIR/config" \
    PATH="$TEMP_DIR/bin:$PATH" \
    bash "$REPO_ROOT/scripts/hyprmono.sh" emoji

grep -q '^😀$' "$TEMP_DIR/emoji"

printf 'Caffyne Shell settings and launcher dispatch passed.\n'
