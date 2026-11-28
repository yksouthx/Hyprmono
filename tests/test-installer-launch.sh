#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/bin"
cat > "$TEMP_DIR/bin/kitty" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$TERMINAL_CAPTURE"
STUB
chmod +x "$TEMP_DIR/bin/kitty"

# ---- terminal wrapper: argument forwarding (works as any user) ----
TERMINAL_CAPTURE="$TEMP_DIR/terminal-args" \
    PATH="$TEMP_DIR/bin:$PATH" \
    bash "$REPO_ROOT/scripts/run-installer-terminal" \
    "$REPO_ROOT/scripts/install.sh" --terminal --minimal

[[ "$(sed -n '1p' "$TEMP_DIR/terminal-args")" == "--" ]]
[[ "$(sed -n '2p' "$TEMP_DIR/terminal-args")" == "bash" ]]
[[ "$(sed -n '3p' "$TEMP_DIR/terminal-args")" == "$REPO_ROOT/scripts/install.sh" ]]
[[ "$(sed -n '4p' "$TEMP_DIR/terminal-args")" == "--terminal" ]]
[[ "$(sed -n '5p' "$TEMP_DIR/terminal-args")" == "--minimal" ]]

# ---- terminal wrapper: the installer's exit status is propagated even when the
# terminal emulator itself exits 0, and the window is told to stay open ----
cat > "$TEMP_DIR/bin/kitty" <<'STUB'
#!/usr/bin/env bash
shift                      # drop "--", run the command like a real terminal would
"$@" || true               # emulators often report 0 regardless of the child
STUB
cat > "$TEMP_DIR/fake-installer.sh" <<'STUB'
#!/usr/bin/env bash
trap 'printf "%s\n" "$?" > "$HYPRMONO_STATUS_FILE"' EXIT
[[ "${HYPRMONO_PAUSE_ON_EXIT:-}" == 1 ]] || exit 99
exit "${FAKE_STATUS:-0}"
STUB
chmod +x "$TEMP_DIR/bin/kitty"
status=0
FAKE_STATUS=7 PATH="$TEMP_DIR/bin:$PATH" \
    bash "$REPO_ROOT/scripts/run-installer-terminal" "$TEMP_DIR/fake-installer.sh" || status=$?
[[ "$status" -eq 7 ]]
FAKE_STATUS=0 PATH="$TEMP_DIR/bin:$PATH" \
    bash "$REPO_ROOT/scripts/run-installer-terminal" "$TEMP_DIR/fake-installer.sh"
if bash "$REPO_ROOT/scripts/run-installer-terminal" "$TEMP_DIR/does-not-exist.sh" 2>/dev/null; then
    echo "a missing installer script must be an error" >&2
    exit 1
fi

# ---- Caffyne replaces the legacy graphical shell installer ----
if [[ $EUID -eq 0 ]]; then
    echo "SKIP: Caffyne GUI dispatch checks need a non-root user"
    exit 0
fi

TERM_CAPTURE="$TEMP_DIR/installer-terminal-args" \
    PATH="$TEMP_DIR/bin:$PATH" \
    WAYLAND_DISPLAY=wayland-test \
    timeout 5 "$REPO_ROOT/install.sh" </dev/null >/dev/null 2>&1 || true
[[ ! -e "$TEMP_DIR/installer-terminal-args" ]]

printf 'Caffyne replacement and terminal wrapper checks passed.\n'
