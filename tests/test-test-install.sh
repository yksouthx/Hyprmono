#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

if [[ $EUID -eq 0 ]]; then
    echo "SKIP: test_install.sh refuses to run as root"
    exit 0
fi

mkdir -p "$TEMP_DIR/bin" "$TEMP_DIR/home/.config/hypr" \
    "$TEMP_DIR/home/.config/hyprmono" "$TEMP_DIR/home/.local/bin"
cat > "$TEMP_DIR/bin/hyprctl" <<'STUB'
#!/usr/bin/env bash
case "$1" in
    -j) printf '[]\n' ;;
    reload) exit 0 ;;
    configerrors)
        if [[ "${HYPRCTL_ERRORS:-0}" == 1 ]]; then
            printf 'Config error: intentional smoke-test failure\n'
        else
            printf 'No config errors\n'
        fi
        ;;
    *) exit 0 ;;
esac
STUB
cat > "$TEMP_DIR/bin/quickshell" <<'STUB'
#!/usr/bin/env bash
if [[ "${QS_QT_MISMATCH:-0}" == 1 ]]; then
    printf 'Quickshell was built against Qt 6.12.0 but the system has updated to Qt 6.12.1 without rebuilding the package.\n' >&2
    exit 0
fi
if [[ "${QS_MISSING_RESOURCE:-0}" == 1 ]]; then
    printf 'WARN scene: QML QQuickImage at @Wallpaper.qml[23:5]: Cannot open: qrc:/qs-blackhole\n' >&2
    exit 0
fi
if [[ "${QS_ERROR:-0}" == 1 ]]; then
    printf 'Error: intentional smoke-test failure\n' >&2
    exit 1
fi
exit 0
STUB
cat > "$TEMP_DIR/bin/pacman" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
cat > "$TEMP_DIR/bin/sudo" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
cat > "$TEMP_DIR/bin/paru" <<'STUB'
#!/usr/bin/env bash
touch "$PARU_CALLED"
STUB
chmod +x "$TEMP_DIR/bin/"*

export HOME="$TEMP_DIR/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
export WAYLAND_DISPLAY=wayland-test
export TERM=xterm
export PATH="$TEMP_DIR/bin:$PATH"
mkdir -p "$HOME/.cache/Hyprmono"
printf 'personal config\n' > "$HOME/.config/hypr/hyprland.conf"
printf 'pre-existing shell config\n' > "$HOME/.config/hyprmono/shell.qml"
printf 'my helper\n' > "$HOME/.local/bin/my-helper"
printf 'pre-existing shell helper\n' > "$HOME/.local/bin/start-shell.sh"
printf 'existing install log\n' > "$HOME/.cache/Hyprmono/install.log"

if HYPRCTL_ERRORS=1 "$REPO_ROOT/test_install.sh" >"$TEMP_DIR/hyprland-error.out" 2>&1; then
    cat "$TEMP_DIR/hyprland-error.out" >&2
    echo "test_install.sh should fail on the Hyprland configuration error" >&2
    exit 1
fi
grep -q 'Hyprland reported configuration errors' "$TEMP_DIR/hyprland-error.out"
grep -q 'rollback completed' "$TEMP_DIR/hyprland-error.out"
[[ "$(< "$HOME/.config/hypr/hyprland.conf")" == "personal config" ]]
[[ "$(< "$HOME/.config/hyprmono/shell.qml")" == "pre-existing shell config" ]]
[[ "$(< "$HOME/.local/bin/start-shell.sh")" == "pre-existing shell helper" ]]
[[ ! -e "$HOME/.cache/Hyprmono/deployed-targets" ]]
[[ ! -e "$HOME/.cache/Hyprmono/original-backup" ]]
[[ ! -e "$XDG_STATE_HOME/Hyprmono" ]]

if QS_MISSING_RESOURCE=1 "$REPO_ROOT/test_install.sh" >"$TEMP_DIR/missing-resource.out" 2>&1; then
    cat "$TEMP_DIR/missing-resource.out" >&2
    echo "test_install.sh should reject a Quickshell blackholed resource" >&2
    exit 1
fi
grep -q 'Quickshell logged a startup or QML error' "$TEMP_DIR/missing-resource.out"
grep -q 'rollback completed' "$TEMP_DIR/missing-resource.out"
[[ "$(< "$HOME/.config/hyprmono/shell.qml")" == "pre-existing shell config" ]]
[[ ! -e "$XDG_STATE_HOME/Hyprmono" ]]

if QS_ERROR=1 "$REPO_ROOT/test_install.sh" >"$TEMP_DIR/quickshell-error.out" 2>&1; then
    cat "$TEMP_DIR/quickshell-error.out" >&2
    echo "test_install.sh should fail on the Quickshell error" >&2
    exit 1
fi
grep -q 'Quickshell logged a startup or QML error' "$TEMP_DIR/quickshell-error.out"
grep -q 'rollback completed' "$TEMP_DIR/quickshell-error.out"
[[ "$(< "$HOME/.config/hypr/hyprland.conf")" == "personal config" ]]
[[ "$(< "$HOME/.config/hyprmono/shell.qml")" == "pre-existing shell config" ]]
[[ "$(< "$HOME/.local/bin/start-shell.sh")" == "pre-existing shell helper" ]]
[[ "$(< "$HOME/.local/bin/my-helper")" == "my helper" ]]
[[ "$(< "$HOME/.cache/Hyprmono/install.log")" == "existing install log" ]]
[[ ! -e "$HOME/.cache/Hyprmono/deployed-targets" ]]
[[ ! -e "$HOME/.cache/Hyprmono/original-backup" ]]
[[ -z "$(find "$HOME" -maxdepth 1 -type d -name '.config-backup-*' -print -quit)" ]]
[[ ! -e "$XDG_STATE_HOME/Hyprmono" ]]

if ! QS_QT_MISMATCH=1 PARU_CALLED="$TEMP_DIR/paru-called" \
    "$REPO_ROOT/test_install.sh" >"$TEMP_DIR/success.out" 2>&1; then
    cat "$TEMP_DIR/success.out" >&2
    echo "test_install.sh should tolerate a Qt mismatch warning" >&2
    exit 1
fi
grep -q 'Quickshell was built against Qt 6.12.0' "$TEMP_DIR/success.out"
grep -q 'Quickshell smoke test passed' "$TEMP_DIR/success.out"
[[ ! -e "$TEMP_DIR/paru-called" ]]
[[ -r "$HOME/.config/hyprmono/shell.qml" ]]
[[ "$(< "$HOME/.config/hyprmono/shell.qml")" != "pre-existing shell config" ]]
[[ -x "$HOME/.local/bin/start-shell.sh" ]]
[[ "$(< "$HOME/.local/bin/my-helper")" == "my helper" ]]
mapfile -t desktop_logs < <(find "$HOME/Desktop" -maxdepth 1 -type f \
    -name 'hyprmono-test-install-*.log' -print)
[[ "${#desktop_logs[@]}" -eq 4 ]]
grep -q 'Quickshell was built against Qt 6.12.0' "$HOME"/Desktop/hyprmono-test-install-*.log
grep -q 'Cannot open: qrc:/qs-blackhole' "$HOME"/Desktop/hyprmono-test-install-*.log
for log_file in "${desktop_logs[@]}"; do
    [[ "$(stat -c '%a' "$log_file")" == 600 ]]
done
printf 'test_install.sh rollback and success checks passed.\n'
