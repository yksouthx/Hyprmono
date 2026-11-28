#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

if [[ $EUID -eq 0 ]]; then
    echo "SKIP: rebuild-quickshell.sh refuses to run as root"
    exit 0
fi

mkdir -p "$TEMP_DIR/bin"
cat > "$TEMP_DIR/bin/pacman" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
cat > "$TEMP_DIR/bin/quickshell" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
cat > "$TEMP_DIR/bin/paru" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$ARGS_CAPTURE"
STUB
cat > "$TEMP_DIR/bin/yay" <<'STUB'
#!/usr/bin/env bash
printf 'yay must not be preferred over paru\n' >&2
exit 1
STUB
chmod +x "$TEMP_DIR/bin/"*

ARGS_CAPTURE="$TEMP_DIR/args" PATH="$TEMP_DIR/bin:$PATH" \
    bash "$REPO_ROOT/scripts/rebuild-quickshell.sh"
[[ "$(< "$TEMP_DIR/args")" == $'-S\n--rebuild\nquickshell' ]]

printf 'Quickshell rebuild helper checks passed.\n'
