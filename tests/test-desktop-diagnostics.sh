#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/home/.config/niri" "$TEMP_DIR/home/.config/caffyne-shell" "$TEMP_DIR/bin"
touch "$TEMP_DIR/home/.config/niri/config.kdl"
cat > "$TEMP_DIR/bin/ps" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' \
    'python3 /home/example/.config/caffyne-shell/main.py --api-key argv-secret' \
    'niri --session'
EOF
cat > "$TEMP_DIR/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' \
    'fnott.service loaded active running fnott' \
    'mako.service loaded active running mako'
EOF
cat > "$TEMP_DIR/bin/busctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' \
    'NAME PID PROCESS USER CONNECTION' \
    'org.freedesktop.Notifications 1234 fnott user :1.5'
EOF
chmod +x "$TEMP_DIR/bin/ps" "$TEMP_DIR/bin/systemctl" "$TEMP_DIR/bin/busctl"

output="$(
    HOME="$TEMP_DIR/home" \
        XDG_CONFIG_HOME="$TEMP_DIR/home/.config" \
        XDG_CURRENT_DESKTOP=niri \
        WAYLAND_DISPLAY=wayland-test \
        DIAGNOSTICS_SECRET=must-not-be-printed \
        PATH="$TEMP_DIR/bin:$PATH" \
        bash "$REPO_ROOT/scripts/desktop-diagnostics.sh"
)"

grep -q '^== Session environment ==$' <<<"$output"
grep -q '^  XDG_CURRENT_DESKTOP=niri$' <<<"$output"
grep -q '^  WAYLAND_DISPLAY=wayland-test$' <<<"$output"
grep -q 'Niri config.*present' <<<"$output"
grep -q 'Caffyne start script.*missing' <<<"$output"
grep -q 'caffyne-runtime' <<<"$output"
grep -q 'fnott.service' <<<"$output"
grep -q 'mako.service' <<<"$output"
grep -q 'org.freedesktop.Notifications' <<<"$output"
! grep -Eq 'must-not-be-printed|argv-secret|api-key' <<<"$output"

cli_output="$(
    HOME="$TEMP_DIR/home" \
        XDG_CONFIG_HOME="$TEMP_DIR/home/.config" \
        bash "$REPO_ROOT/scripts/hyprmono.sh" diagnostics
)"
grep -q '^== Operating system ==$' <<<"$cli_output"

if bash "$REPO_ROOT/scripts/desktop-diagnostics.sh" unexpected >/dev/null 2>&1; then
    echo "desktop-diagnostics.sh must reject unexpected arguments" >&2
    exit 1
fi

help_output="$(bash "$REPO_ROOT/scripts/desktop-diagnostics.sh" --help)"
grep -q 'Read-only snapshot' <<<"$help_output"

printf 'Read-only desktop diagnostics checks passed.\n'
