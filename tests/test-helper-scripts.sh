#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

stub() { # stub NAME EXIT_CODE  (records its argv to $TEMP_DIR/calls)
    local dir="$1" name="$2" code="${3:-0}"
    mkdir -p "$dir"
    printf '#!/bin/sh\necho "%s $*" >> "$CALLS"\nexit %s\n' "$name" "$code" > "$dir/$name"
    chmod +x "$dir/$name"
}

# Keep the real system tools (bash, grep, sed, ...) but nothing that launches a UI.
BASE_PATH="/usr/bin:/bin"
export CALLS="$TEMP_DIR/calls"

# ---------- lock-screen.sh ----------
bin="$TEMP_DIR/lock-hyprlock"
stub "$bin" hyprlock
: > "$CALLS"
PATH="$bin:$BASE_PATH" HOME="$TEMP_DIR/home" bash "$REPO_ROOT/scripts/lock-screen.sh"
grep -q '^hyprlock' "$CALLS"

bin="$TEMP_DIR/lock-with-config"
stub "$bin" hyprlock
: > "$CALLS"
PATH="$bin:$BASE_PATH" HOME="$TEMP_DIR/home" bash "$REPO_ROOT/scripts/lock-screen.sh" || true
grep -q '^hyprlock' "$CALLS"

bin="$TEMP_DIR/lock-nothing"
mkdir -p "$bin"
if PATH="$bin:$BASE_PATH" HOME="$TEMP_DIR/home" bash "$REPO_ROOT/scripts/lock-screen.sh" 2>/dev/null; then
    echo "lock-screen.sh must fail when hyprlock is missing" >&2
    exit 1
fi

# ---------- launch-menu.sh ----------
bin="$TEMP_DIR/menu-fuzzel"
stub "$bin" fuzzel
: > "$CALLS"
PATH="$bin:$BASE_PATH" bash "$REPO_ROOT/scripts/launch-menu.sh"
grep -q '^fuzzel' "$CALLS"

bin="$TEMP_DIR/menu-wofi"
stub "$bin" wofi
: > "$CALLS"
PATH="$bin:$BASE_PATH" bash "$REPO_ROOT/scripts/launch-menu.sh"
grep -q '^wofi --show drun' "$CALLS"

bin="$TEMP_DIR/menu-none"
mkdir -p "$bin"
if PATH="$bin:$BASE_PATH" bash "$REPO_ROOT/scripts/launch-menu.sh" 2>"$TEMP_DIR/menu-none.err"; then
    echo "launch-menu.sh must fail when no launcher exists" >&2
    exit 1
fi
grep -q 'No application launcher found' "$TEMP_DIR/menu-none.err"

# ---------- launch_first_available.sh (no eval, first available wins) ----------
bin="$TEMP_DIR/first"
stub "$bin" second-tool
: > "$CALLS"
PATH="$bin:$BASE_PATH" bash "$REPO_ROOT/scripts/launch_first_available.sh" "missing-tool --x" "second-tool --flag value"
sleep 0.3
grep -q '^second-tool --flag value' "$CALLS"
if PATH="$bin:$BASE_PATH" bash "$REPO_ROOT/scripts/launch_first_available.sh" "nope1" "nope2" 2>/dev/null; then
    echo "launch_first_available.sh must fail when nothing is available" >&2
    exit 1
fi
# Shell metacharacters must not be interpreted.
: > "$CALLS"
if PATH="$bin:$BASE_PATH" bash "$REPO_ROOT/scripts/launch_first_available.sh" 'second-tool; touch '"$TEMP_DIR"'/pwned' 2>/dev/null; then
    echo "a command containing shell metacharacters must not be launched" >&2
    exit 1
fi
sleep 0.3
[[ ! -e "$TEMP_DIR/pwned" ]]

# ---------- start-session-services.sh ----------
bin="$TEMP_DIR/session"
mkdir -p "$bin"
bash "$REPO_ROOT/scripts/start-session-services.sh"   # must be a harmless no-op with no agent installed

run_services() { # run_services BIN_DIR CONFIG_HOME
    : > "$CALLS"
    PATH="$1:$BASE_PATH" XDG_CONFIG_HOME="$2" bash "$REPO_ROOT/scripts/start-session-services.sh"
    sleep 0.4
}
services_bin="$TEMP_DIR/services-bin"
stub "$services_bin" fnott
stub "$services_bin" nm-applet
printf '#!/bin/sh\nexit 0\n' > "$services_bin/busctl"       # no owner of the notification name
chmod +x "$services_bin/busctl"

with_shell="$TEMP_DIR/cfg-with-shell"
mkdir -p "$with_shell/caffyne-shell"
printf '#!/bin/sh\nexit 0\n' > "$with_shell/caffyne-shell/start.sh"
chmod +x "$with_shell/caffyne-shell/start.sh"
without_shell="$TEMP_DIR/cfg-without-shell"
mkdir -p "$without_shell"

# Project shell present: fnott and the tray applet start.
run_services "$services_bin" "$with_shell"
grep -q '^fnott' "$CALLS"
grep -q '^nm-applet --indicator' "$CALLS"

# Caffyne absent: skip project-shell notification and network helpers.
run_services "$services_bin" "$without_shell"
! grep -q '^fnott' "$CALLS"
! grep -q '^nm-applet' "$CALLS"

# Another daemon already owns org.freedesktop.Notifications: fnott must not start.
owned_bin="$TEMP_DIR/services-owned"
stub "$owned_bin" fnott
printf '#!/bin/sh\nprintf "org.freedesktop.Notifications 1234 mako user :1.5 x\\n"\n' > "$owned_bin/busctl"
chmod +x "$owned_bin/busctl"
run_services "$owned_bin" "$with_shell"
! grep -q '^fnott' "$CALLS"

printf 'Helper script checks passed.\n'
