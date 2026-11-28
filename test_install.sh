#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="$HOME/.local/bin"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/Hyprmono"
LOG_DIR="$HOME/.cache/Hyprmono"
SNAPSHOT_DIR=""
TEST_LOG=""
ROLLBACK_NEEDED=0
HYPRLAND_RELOADED=0
declare -a NEW_DIRECTORIES=()
declare -a CONFIG_TARGETS=()
declare -a SNAPSHOT_PATHS=()

usage() {
    cat <<'EOF'
Usage: ./test_install.sh

Deploy HyprMono's minimal configuration without installing packages, migrating
the repository, or cleaning other desktop components. Then reload Hyprland,
check its configuration errors, and smoke-test Caffyne Shell. Any failure restores
the exact pre-test files and reloads the restored Hyprland configuration.

Requires an active Hyprland Wayland session and an installed Caffyne Shell.
Test output is written to a new, private log file on your Desktop.
EOF
}

start_test_log() {
    local desktop configured
    desktop="$HOME/Desktop"
    if command -v xdg-user-dir >/dev/null 2>&1; then
        configured=$(xdg-user-dir DESKTOP 2>/dev/null || true)
        if [[ "$configured" == "$HOME"/* ]]; then
            desktop="$configured"
        fi
    fi
    mkdir -p -- "$desktop"
    TEST_LOG=$(mktemp "$desktop/hyprmono-test-install-$(date '+%Y%m%d-%H%M%S')-XXXXXX.log")
    chmod 600 "$TEST_LOG"
    exec > >(tee -a "$TEST_LOG") 2>&1
    printf 'Test log: %s\n' "$TEST_LOG"
}

say_error() {
    printf 'test_install: %s\n' "$*" >&2
}

fail() {
    say_error "$*"
    exit 1
}

collect_config_targets() {
    local dir name
    for dir in "$REPO_ROOT"/config/*/; do
        [[ -d "$dir" ]] || continue
        name=$(basename "${dir%/}")
        case "$name" in
            Hyprland) CONFIG_TARGETS+=(hypr) ;;
            fastfetch) ;;
            *) CONFIG_TARGETS+=("$name") ;;
        esac
    done
}

track_missing_directories() {
    local dir="$1" existing
    while [[ "$dir" != "$HOME" && "$dir" != "/" ]]; do
        if [[ ! -d "$dir" ]]; then
            local already_tracked=0
            for existing in "${NEW_DIRECTORIES[@]}"; do
                [[ "$existing" == "$dir" ]] && already_tracked=1
            done
            (( already_tracked )) || NEW_DIRECTORIES+=("$dir")
        fi
        dir=$(dirname "$dir")
    done
}

snapshot_path() {
    local path="$1"
    local item="$SNAPSHOT_DIR/items/${#SNAPSHOT_PATHS[@]}"
    local present=0

    [[ -e "$path" || -L "$path" ]] && present=1
    SNAPSHOT_PATHS+=("$path")
    printf '%s\0%s\0' "$path" "$present" >> "$SNAPSHOT_DIR/manifest"
    if (( present )); then
        cp -a -- "$path" "$item"
    fi
}

take_snapshot() {
    local target script font_file
    track_missing_directories "$STATE_DIR"
    track_missing_directories "$LOCAL_BIN"
    track_missing_directories "$LOG_DIR"
    track_missing_directories "$HOME/.local/share/fonts"
    mkdir -p "$STATE_DIR"
    SNAPSHOT_DIR=$(mktemp -d "$STATE_DIR/test-install.XXXXXXXX")
    mkdir -p "$SNAPSHOT_DIR/items"
    : > "$SNAPSHOT_DIR/manifest"

    collect_config_targets
    snapshot_path "$CONFIG_DIR/caffyne-shell"
    for target in "${CONFIG_TARGETS[@]}"; do
        snapshot_path "$CONFIG_DIR/$target"
    done

    for script in "$REPO_ROOT"/scripts/*.sh; do
        [[ -f "$script" ]] || continue
        case "$(basename "$script")" in
            install.sh|watch-quality.sh) continue ;;
        esac
        snapshot_path "$LOCAL_BIN/$(basename "$script")"
    done
    snapshot_path "$LOCAL_BIN/hyprmono"

    snapshot_path "$LOG_DIR/deployed-targets"
    snapshot_path "$LOG_DIR/original-backup"
    snapshot_path "$LOG_DIR/install.log"

    for font_file in "$REPO_ROOT"/assets/fonts/*.otf "$REPO_ROOT"/assets/fonts/*.ttf; do
        [[ -f "$font_file" ]] || continue
        snapshot_path "$HOME/.local/share/fonts/$(basename "$font_file")"
    done
    if compgen -G "$REPO_ROOT/assets/fonts/*" >/dev/null; then
        snapshot_path "${XDG_CACHE_HOME:-$HOME/.cache}/fontconfig"
    fi

}

remove_created_config_backup() {
    local backup
    [[ -s "$SNAPSHOT_DIR/created-config-backup" ]] || return 0
    backup=$(< "$SNAPSHOT_DIR/created-config-backup")
    if [[ "$backup" == "$HOME"/.config-backup-* && -d "$backup" ]]; then
        rm -rf -- "$backup"
    else
        say_error "refusing to remove unexpected installer backup path: $backup"
        return 1
    fi
}

remove_created_directories() {
    local i dir
    for ((i = ${#NEW_DIRECTORIES[@]} - 1; i >= 0; i--)); do
        dir="${NEW_DIRECTORIES[$i]}"
        if [[ -d "$dir" ]] && ! rmdir -- "$dir" 2>/dev/null; then
            printf 'test_install: leaving non-empty directory created during test: %s\n' \
                "$dir" >&2
        fi
    done
}

restore_snapshot() {
    local failed=0 path present item i
    local -a entries=()
    mapfile -d '' -t entries < "$SNAPSHOT_DIR/manifest"
    if (( ${#entries[@]} % 2 != 0 )); then
        say_error "snapshot manifest is incomplete: $SNAPSHOT_DIR"
        return 1
    fi

    for ((i = ${#entries[@]} - 2; i >= 0; i -= 2)); do
        path="${entries[$i]}"
        present="${entries[$((i + 1))]}"
        item="$SNAPSHOT_DIR/items/$((i / 2))"
        if [[ "$present" != 0 && "$present" != 1 ]]; then
            say_error "snapshot manifest has an invalid entry for $path"
            failed=1
            continue
        fi
        if ! rm -rf -- "$path"; then
            say_error "could not remove changed path: $path"
            failed=1
            continue
        fi
        if [[ "$present" == 1 ]]; then
            if ! mkdir -p -- "$(dirname "$path")" || ! cp -a -- "$item" "$path"; then
                say_error "could not restore path: $path"
                failed=1
            fi
        fi
    done

    if ! remove_created_config_backup; then
        say_error "could not remove the backup created by this test"
        failed=1
    fi
    if (( HYPRLAND_RELOADED )) && command -v hyprctl >/dev/null 2>&1; then
        if ! hyprctl reload; then
            say_error "restored files, but Hyprland could not reload its previous configuration"
            failed=1
        fi
    fi
    if compgen -G "$REPO_ROOT/assets/fonts/*" >/dev/null \
        && command -v fc-cache >/dev/null 2>&1; then
        if ! fc-cache -f; then
            say_error "restored font files, but could not refresh the font cache"
            failed=1
        fi
    fi
    return "$failed"
}

on_exit() {
    local status=$?
    trap - EXIT
    if (( status != 0 && ROLLBACK_NEEDED )); then
        printf 'test_install: restoring pre-test files...\n' >&2
        if restore_snapshot; then
            printf 'test_install: rollback completed.\n' >&2
            rm -rf -- "$SNAPSHOT_DIR"
            remove_created_directories
        else
            printf 'test_install: rollback was incomplete; snapshot retained at %s\n' \
                "$SNAPSHOT_DIR" >&2
            status=1
        fi
    elif [[ -n "$SNAPSHOT_DIR" ]]; then
        rm -rf -- "$SNAPSHOT_DIR"
        remove_created_directories
    fi
    exit "$status"
}
trap on_exit EXIT

check_hyprland() {
    local errors normalized
    HYPRLAND_RELOADED=1
    if ! hyprctl reload; then
        fail "Hyprland reload failed."
    fi
    if ! errors=$(hyprctl configerrors 2>&1); then
        printf '%s\n' "$errors" >&2
        fail "could not query Hyprland configuration errors."
    fi
    normalized="${errors,,}"
    if [[ "$normalized" == *"no config errors"* \
        || "$normalized" == *"no configuration errors"* \
        || "$normalized" == *"no errors"* \
        || "$normalized" == *"0 errors"* ]]; then
        printf 'Hyprland configuration check passed.\n'
    elif [[ "$normalized" == *"error"* || "$normalized" == *"invalid"* \
        || "$normalized" == *"failed"* ]]; then
        printf '%s\n' "$errors" >&2
        fail "Hyprland reported configuration errors."
    else
        printf 'Hyprland configuration check passed.\n'
    fi
}

check_caffyne_shell() {
    local caffyne_start="$CONFIG_DIR/caffyne-shell/start.sh"
    local caffyne_main="$CONFIG_DIR/caffyne-shell/main.py"
    local output="$SNAPSHOT_DIR/caffyne-shell.log"
    local status=0

    [[ -x "$caffyne_start" || -r "$caffyne_main" ]] ||
        fail "Caffyne Shell entry point is missing: $caffyne_start"
    printf 'Starting a Caffyne Shell smoke test (up to 6 seconds)...\n'
    XDG_CACHE_HOME="$SNAPSHOT_DIR/caffyne-cache" \
        XDG_DATA_HOME="$SNAPSHOT_DIR/caffyne-data" \
        XDG_STATE_HOME="$SNAPSHOT_DIR/caffyne-state" \
        timeout --signal=TERM --kill-after=2s 6s \
        "$caffyne_start" >"$output" 2>&1 || status=$?

    if [[ -s "$output" ]]; then
        printf '%s\n' '--- Caffyne Shell smoke-test output ---'
        cat "$output"
        printf '%s\n' '--- End Caffyne Shell output ---'
    fi
    if grep -Eiq \
        '(^|[[:space:]])(Error|Traceback|ModuleNotFoundError|ImportError|SyntaxError):|Python.*(error|failed)|cannot import|module .*not found|(^|[[:space:]])error([:[:space:]]|$)' \
        "$output"; then
        fail "Caffyne Shell logged a startup or Python error."
    fi
    if (( status != 0 && status != 124 )); then
        fail "Caffyne Shell smoke test exited with status $status."
    fi
    printf 'Caffyne Shell smoke test passed.\n'
}

main() {
    if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
        usage
        return 0
    fi
    start_test_log
    (( $# == 0 )) || {
        usage >&2
        return 2
    }
    (( EUID != 0 )) || fail "do not run this script as root."
    [[ -n "${WAYLAND_DISPLAY:-}" ]] || fail "no Wayland session detected."
    command -v hyprctl >/dev/null 2>&1 || fail "hyprctl is not installed."
    command -v timeout >/dev/null 2>&1 || fail "timeout is required."
    [[ -x "$CONFIG_DIR/caffyne-shell/start.sh" || -r "$CONFIG_DIR/caffyne-shell/main.py" ]] ||
        fail "Caffyne Shell is not installed."
    hyprctl -j monitors >/dev/null 2>&1 || fail "could not connect to the active Hyprland instance."

    take_snapshot
    ROLLBACK_NEEDED=1
    printf 'Snapshot saved; installing minimal HyprMono configuration without package changes.\n'
    if ! HYPRMONO_BACKUP_DIR_FILE="$SNAPSHOT_DIR/created-config-backup" \
        bash "$REPO_ROOT/scripts/install.sh" \
        --terminal --minimal --skip-deps --no-cleanup --no-migrate --yes; then
        fail "installer failed."
    fi

    check_hyprland
    check_caffyne_shell

    ROLLBACK_NEEDED=0
    printf 'Installation smoke test passed. HyprMono remains installed.\n'
}

main "$@"
