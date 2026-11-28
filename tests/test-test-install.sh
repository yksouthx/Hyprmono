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

mkdir -p "$TEMP_DIR/bin" "$TEMP_DIR/home/.config/niri" \
    "$TEMP_DIR/home/.config/hyprmono" "$TEMP_DIR/home/.local/bin"
cat > "$TEMP_DIR/bin/niri" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == msg && "$2" == outputs ]]; then
    printf '[]\n'
    exit 0
fi
if [[ "$1" == msg && "$2" == action && "$3" == load-config-file ]]; then
    if [[ "${NIRI_ERRORS:-0}" == 1 && ! -e "$NIRI_FAIL_MARKER" ]]; then
        touch "$NIRI_FAIL_MARKER"
        printf 'Config error: intentional smoke-test failure\n' >&2
        exit 1
    fi
    exit 0
fi
exit 2
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
export NIRI_FAIL_MARKER="$TEMP_DIR/niri-failed-once"
mkdir -p "$HOME/.config/caffyne-shell"
cat > "$HOME/.config/caffyne-shell/start.sh" <<'STUB'
#!/usr/bin/env bash
if [[ "${CAFFYNE_ERROR:-0}" == 1 ]]; then
    printf 'Python Error: intentional smoke-test failure\n' >&2
    exit 1
fi
exit 0
STUB
chmod +x "$HOME/.config/caffyne-shell/start.sh"
mkdir -p "$HOME/.cache/Hyprmono"
printf 'personal config\n' > "$HOME/.config/niri/config.kdl"
printf 'my helper\n' > "$HOME/.local/bin/my-helper"
printf 'pre-existing shell helper\n' > "$HOME/.local/bin/start-shell.sh"
printf 'existing install log\n' > "$HOME/.cache/Hyprmono/install.log"

if NIRI_ERRORS=1 "$REPO_ROOT/test_install.sh" >"$TEMP_DIR/niri-error.out" 2>&1; then
    cat "$TEMP_DIR/niri-error.out" >&2
    echo "test_install.sh should fail on a Niri configuration error" >&2
    exit 1
fi
grep -q 'Niri failed to load the deployed configuration' "$TEMP_DIR/niri-error.out"
grep -q 'rollback completed' "$TEMP_DIR/niri-error.out"
[[ "$(< "$HOME/.config/niri/config.kdl")" == "personal config" ]]
[[ "$(< "$HOME/.local/bin/start-shell.sh")" == "pre-existing shell helper" ]]
[[ ! -e "$HOME/.cache/Hyprmono/deployed-targets" ]]
[[ ! -e "$HOME/.cache/Hyprmono/original-backup" ]]
[[ ! -e "$XDG_STATE_HOME/Hyprmono" ]]

if CAFFYNE_ERROR=1 "$REPO_ROOT/test_install.sh" >"$TEMP_DIR/caffyne-error.out" 2>&1; then
    cat "$TEMP_DIR/caffyne-error.out" >&2
    echo "test_install.sh should reject a Caffyne startup error" >&2
    exit 1
fi
grep -q 'Caffyne Shell logged a startup or Python error' "$TEMP_DIR/caffyne-error.out"
grep -q 'rollback completed' "$TEMP_DIR/caffyne-error.out"
[[ ! -e "$XDG_STATE_HOME/Hyprmono" ]]

[[ "$(< "$HOME/.config/niri/config.kdl")" == "personal config" ]]
[[ "$(< "$HOME/.local/bin/start-shell.sh")" == "pre-existing shell helper" ]]
[[ "$(< "$HOME/.local/bin/my-helper")" == "my helper" ]]
[[ "$(< "$HOME/.cache/Hyprmono/install.log")" == "existing install log" ]]
[[ ! -e "$HOME/.cache/Hyprmono/deployed-targets" ]]
[[ ! -e "$HOME/.cache/Hyprmono/original-backup" ]]
[[ -z "$(find "$HOME" -maxdepth 1 -type d -name '.config-backup-*' -print -quit)" ]]
[[ ! -e "$XDG_STATE_HOME/Hyprmono" ]]

if ! "$REPO_ROOT/test_install.sh" >"$TEMP_DIR/success.out" 2>&1; then
    cat "$TEMP_DIR/success.out" >&2
    echo "test_install.sh should complete the Caffyne smoke test" >&2
    exit 1
fi
grep -q 'Caffyne Shell smoke test passed' "$TEMP_DIR/success.out"
[[ -x "$HOME/.local/bin/start-shell.sh" ]]
[[ "$(< "$HOME/.local/bin/my-helper")" == "my helper" ]]
mapfile -t desktop_logs < <(find "$HOME/Desktop" -maxdepth 1 -type f \
    -name 'hyprmono-test-install-*.log' -print)
[[ "${#desktop_logs[@]}" -eq 3 ]]
for log_file in "${desktop_logs[@]}"; do
    [[ "$(stat -c '%a' "$log_file")" == 600 ]]
done
printf 'test_install.sh rollback and success checks passed.\n'
