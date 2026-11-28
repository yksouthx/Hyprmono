#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/bin" "$TEMP_DIR/config/hypr"
printf '#!/bin/sh\necho "hyprctl $*" >> "$TEMP_DIR/hyprctl.log"\nexit 0\n' > "$TEMP_DIR/bin/hyprctl"
chmod +x "$TEMP_DIR/bin/hyprctl"
export PATH="$TEMP_DIR/bin:$PATH" TEMP_DIR HOME="$TEMP_DIR" XDG_CONFIG_HOME="$TEMP_DIR/config"

run() { bash "$REPO_ROOT/scripts/profile.sh" "$@"; }

# Default is full-visual when nothing has been configured.
run show | grep -q 'profile: full-visual'

for profile in low-resource balanced full-visual; do
    run "$profile" >/dev/null
    [[ "$(< "$TEMP_DIR/config/hypr/profile")" == "$profile" ]]
    run show | grep -q "profile: $profile"
done
grep -q 'hyprctl reload' "$TEMP_DIR/hyprctl.log"

# Invalid input fails without touching the saved profile.
before="$(< "$TEMP_DIR/config/hypr/profile")"
if run nonsense >/dev/null 2>&1; then
    echo "an invalid profile name must be rejected" >&2
    exit 1
fi
[[ "$(< "$TEMP_DIR/config/hypr/profile")" == "$before" ]]

# A corrupt profile file falls back to the default instead of crashing.
printf 'garbage\n' > "$TEMP_DIR/config/hypr/profile"
run show | grep -q 'profile: full-visual'

printf 'Profile command checks passed.\n'
