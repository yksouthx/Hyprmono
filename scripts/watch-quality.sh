#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly WATCH_PATHS=("$REPO_ROOT/config" "$REPO_ROOT/scripts" "$REPO_ROOT/tests")
AUTO_FORMAT=0
RUN_ONCE=0

usage() {
    cat <<'EOF'
Usage: scripts/watch-quality.sh [--once] [--format]

Run shell syntax checks, optional linters and the project test suite, then
watch source files for changes. Lint and test failures are reported; they are
never rewritten.

Options:
  --once     Run checks once and exit
  --format   While watching, format changed shell scripts with shfmt (4 spaces).
             Off by default so saving a file never rewrites it unexpectedly.
  --help     Show this help
EOF
}

run_checks() {
    local failed=0
    local file

    printf '\n== Shell syntax ==\n'
    for file in "$REPO_ROOT"/test_install.sh "$REPO_ROOT"/scripts/*.sh \
        "$REPO_ROOT"/tests/*.sh "$REPO_ROOT"/scripts/run-installer-terminal; do
        [[ -f "$file" ]] || continue
        if bash -n "$file"; then
            printf '[ OK ] %s\n' "${file#"$REPO_ROOT"/}"
        else
            failed=1
        fi
    done

    if command -v shellcheck >/dev/null 2>&1; then
        printf '\n== ShellCheck ==\n'
        if ! shellcheck -S warning "$REPO_ROOT"/install.sh "$REPO_ROOT"/test_install.sh \
            "$REPO_ROOT"/scripts/*.sh \
            "$REPO_ROOT"/tests/*.sh "$REPO_ROOT"/scripts/run-installer-terminal; then
            failed=1
        fi
    else
        printf '\n[INFO] ShellCheck is not installed; skipping optional lint.\n'
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
                    if ! shfmt -d -i 4 -ci -ln bash "$file" >/dev/null; then
                        printf '[FIX] Formatting %s with shfmt\n' \
                            "${file#"$REPO_ROOT"/}"
                        shfmt -w -i 4 -ci -ln bash "$file" || return 1
                    fi
                fi
                ;;
        esac
    done
}

while (( $# > 0 )); do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --once)
            RUN_ONCE=1
            shift
            ;;
        --format)
            AUTO_FORMAT=1
            shift
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
done

if (( RUN_ONCE )); then
    if run_checks; then
        exit 0
    else
        exit 1
    fi
fi

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

        if (( AUTO_FORMAT )) && ! format_changed_shell_files "${changed_files[@]}"; then
            printf '[FAIL] Could not format a changed shell script.\n' >&2
        fi
        run_checks || true
    done
