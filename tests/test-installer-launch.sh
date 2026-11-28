#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

[[ -s "$REPO_ROOT/config/installer/assets/wall.webp" ]]
grep -q 'source: Qt.resolvedUrl("assets/wall.webp")' \
    "$REPO_ROOT/config/installer/Installer.qml"

mkdir -p "$TEMP_DIR/bin"
cat > "$TEMP_DIR/bin/quickshell" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$QS_CAPTURE"
exit "${QS_EXIT:-0}"
STUB
cat > "$TEMP_DIR/bin/kitty" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$TERMINAL_CAPTURE"
STUB
chmod +x "$TEMP_DIR/bin/quickshell" "$TEMP_DIR/bin/kitty"

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

# ---- GUI dispatch (the installer itself refuses to run as root) ----
if [[ $EUID -eq 0 ]]; then
    echo "SKIP: GUI dispatch checks need a non-root user"
    exit 0
fi

QS_CAPTURE="$TEMP_DIR/quickshell-args" \
    PATH="$TEMP_DIR/bin:$PATH" \
    WAYLAND_DISPLAY=wayland-test \
    "$REPO_ROOT/install.sh"

[[ "$(sed -n '1p' "$TEMP_DIR/quickshell-args")" == "-p" ]]
[[ "$(sed -n '2p' "$TEMP_DIR/quickshell-args")" == "$REPO_ROOT/config/installer/Installer.qml" ]]

# If the QML installer cannot start, the terminal installer must take over
# instead of the installer simply disappearing.
printf '#!/bin/sh\nexit 1\n' > "$TEMP_DIR/bin/pacman"
printf '#!/bin/sh\ncase "$1" in -v|-n) exit 0;; esac\nexec "$@"\n' > "$TEMP_DIR/bin/sudo"
chmod +x "$TEMP_DIR/bin/pacman" "$TEMP_DIR/bin/sudo"
HOME_FOR_FALLBACK="$TEMP_DIR/fallback-home"
mkdir -p "$HOME_FOR_FALLBACK"
QS_CAPTURE="$TEMP_DIR/quickshell-args-2" QS_EXIT=1 \
    HOME="$HOME_FOR_FALLBACK" PATH="$TEMP_DIR/bin:$PATH" WAYLAND_DISPLAY=wayland-test \
    "$REPO_ROOT/install.sh" --yes </dev/null >"$TEMP_DIR/fallback.out" 2>&1 || true
# (with arguments the GUI branch is skipped; the no-argument case is covered below)
QS_CAPTURE="$TEMP_DIR/quickshell-args-3" QS_EXIT=1 \
    HOME="$HOME_FOR_FALLBACK" PATH="$TEMP_DIR/bin:$PATH" WAYLAND_DISPLAY=wayland-test \
    timeout 60 "$REPO_ROOT/install.sh" </dev/null >"$TEMP_DIR/fallback-gui.out" 2>&1 || true
grep -q 'graphical installer failed to start' "$TEMP_DIR/fallback-gui.out"

printf 'Installer GUI dispatch, fallback and terminal wrapper checks passed.\n'
