#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly WATCH_PATHS=("$REPO_ROOT/config" "$REPO_ROOT/scripts" "$REPO_ROOT/tests")

usage() {
    cat <<'EOF'
Usage: scripts/watch-quality.sh [--once]

Run shell syntax checks and the project test suite, then watch source files
for changes. When shfmt is installed, changed shell scripts are formatted
automatically. Lint and test failures are reported; they are not rewritten.

Options:
  --once   Run checks once and exit
  --help   Show this help
EOF
}

run_checks() {
    local failed=0
    local file

    printf '\n== Shell syntax ==\n'
    for file in "$REPO_ROOT"/scripts/*.sh "$REPO_ROOT"/tests/*.sh \
        "$REPO_ROOT"/scripts/run-installer-terminal; do
        [[ -f "$file" ]] || continue
        if bash -n "$file"; then
            printf '[ OK ] %s\n' "${file#"$REPO_ROOT"/}"
        else
            failed=1
        fi
    done

    if command -v shellcheck >/dev/null 2>&1; then
        printf '\n== ShellCheck ==\n'
        if ! shellcheck "$REPO_ROOT"/scripts/*.sh "$REPO_ROOT"/tests/*.sh \
            "$REPO_ROOT"/scripts/run-installer-terminal; then
            failed=1
        fi
    else
        printf '\n[INFO] ShellCheck is not installed; skipping optional lint.\n'
    fi

    if command -v qmllint >/dev/null 2>&1; then
        printf '\n== QML lint ==\n'
        if ! qmllint "$REPO_ROOT"/config/quickshell/*.qml \
            "$REPO_ROOT"/config/installer/*.qml; then
            failed=1
        fi
    else
        printf '\n[INFO] qmllint is not installed; skipping optional QML lint.\n'
    fi

    printf '\n== Tests ==\n'
    for file in "$REPO_ROOT"/tests/test-*.sh; do
        [[ -f "$file" ]] || continue
        printf '\n[RUN] %s\n' "${file#"$REPO_ROOT"/}"
        if ! bash "$file"; then
            failed=1
        fi
    done

    if (( failed == 0 )); then
        printf '\n[ OK ] All available checks passed.\n'
    else
        printf '\n[FAIL] One or more checks failed. Review the output above.\n' >&2
    fi
    return "$failed"
}

format_changed_shell_files() {
    local file

    for file in "$@"; do
        case "$file" in
            *.sh|*/run-installer-terminal)
                [[ -f "$file" ]] || continue
                if command -v shfmt >/dev/null 2>&1; then
                    if ! shfmt -d -ln bash "$file" >/dev/null; then
                        printf '[FIX] Formatting %s with shfmt\n' \
                            "${file#"$REPO_ROOT"/}"
                        shfmt -w -ln bash "$file" || return 1
                    fi
                fi
                ;;
        esac
    done
}

case "${1:-}" in
    --help|-h)
        usage
        exit 0
        ;;
    --once)
        if run_checks; then
            exit 0
        else
            exit 1
        fi
        ;;
    "")
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

if ! command -v inotifywait >/dev/null 2>&1; then
    printf 'inotifywait is required for live watching (install inotify-tools).\n' >&2
    exit 127
fi

run_checks || true
printf '\nWatching config/, scripts/, and tests/ for changes. Press Ctrl-C to stop.\n'

inotifywait --monitor --quiet --recursive \
    --event close_write,moved_to,create,delete \
    --format '%w%f' "${WATCH_PATHS[@]}" |
    while IFS= read -r changed_file; do
        changed_files=("$changed_file")
        sleep 0.3
        while IFS= read -r -t 0.1 queued_file; do
            changed_files+=("$queued_file")
        done

        if ! format_changed_shell_files "${changed_files[@]}"; then
            printf '[FAIL] Could not format a changed shell script.\n' >&2
        fi
        run_checks || true
    done
