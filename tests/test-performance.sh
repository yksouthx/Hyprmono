#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
hyprland_pid=""
caffyne_pid=""

cleanup() {
    [[ -z "$hyprland_pid" ]] || kill "$hyprland_pid" 2>/dev/null || true
    [[ -z "$caffyne_pid" ]] || kill "$caffyne_pid" 2>/dev/null || true
    [[ -z "$hyprland_pid" ]] || wait "$hyprland_pid" 2>/dev/null || true
    [[ -z "$caffyne_pid" ]] || wait "$caffyne_pid" 2>/dev/null || true
    rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT

bash -c 'exec -a Hyprland bash -c "while :; do :; done"' &
hyprland_pid=$!
bash -c 'exec -a caffyne-shell bash -c "while :; do :; done"' &
caffyne_pid=$!

XDG_STATE_HOME="$TEMP_DIR/state" bash "$REPO_ROOT/scripts/performance.sh" \
    --seconds 1 --record > "$TEMP_DIR/record.out"
grep -q '^Hyprland:.*CPU.*resident memory' "$TEMP_DIR/record.out"
grep -q '^Caffyne Shell:.*CPU.*resident memory' "$TEMP_DIR/record.out"
test -s "$TEMP_DIR/state/Hyprmono/performance-baseline.tsv"

XDG_STATE_HOME="$TEMP_DIR/state" bash "$REPO_ROOT/scripts/performance.sh" \
    --seconds 1 --compare > "$TEMP_DIR/compare.out"
grep -q '^Comparison with baseline recorded' "$TEMP_DIR/compare.out"

printf '%s\t1\t0\t0\t0\t0\n' "$(date --iso-8601=seconds)" \
    > "$TEMP_DIR/state/Hyprmono/performance-baseline.tsv"
if XDG_STATE_HOME="$TEMP_DIR/state" bash "$REPO_ROOT/scripts/performance.sh" \
    --seconds 1 --fail-regression 500 > "$TEMP_DIR/regression.out" 2>&1; then
    printf 'A known resource regression unexpectedly passed.\n' >&2
    exit 1
fi
grep -q 'Resource regression exceeded the configured 500% tolerance.' "$TEMP_DIR/regression.out"

if bash "$REPO_ROOT/scripts/performance.sh" --seconds 0 > /dev/null 2>&1; then
    printf 'Invalid sample duration unexpectedly succeeded.\n' >&2
    exit 1
else
    [[ "$?" -eq 2 ]]
fi

printf 'Performance sampling and baseline comparison passed.\n'
