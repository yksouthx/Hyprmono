#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT

lua_bin=""
for candidate in lua5.4 lua5.3 lua luajit; do
    if command -v "$candidate" >/dev/null 2>&1; then
        lua_bin="$candidate"
        break
    fi
done
if [[ -z "$lua_bin" ]]; then
    echo "SKIP: no Lua interpreter installed (install lua5.4 to run this test)"
    exit 0
fi

config_dir="$REPO_ROOT/config/Hyprland/hypr"

# Every Lua file must at least parse.
while IFS= read -r file; do
    LUA_FILE="$file" "$lua_bin" -e 'local f, err = loadfile(os.getenv("LUA_FILE")); if not f then io.stderr:write(err .. "\n"); os.exit(1) end'
done < <(find "$config_dir" -name '*.lua')

TEMP_HOME="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_HOME"' EXIT
HOME="$TEMP_HOME" XDG_CONFIG_HOME="$TEMP_HOME/.config" \
    "$lua_bin" "$REPO_ROOT/tests/lua/stub-hl.lua" "$config_dir"

# Each profile must load too.
mkdir -p "$TEMP_HOME/.config/hypr"
for profile in low-resource balanced full-visual; do
    printf '%s\n' "$profile" > "$TEMP_HOME/.config/hypr/profile"
    HOME="$TEMP_HOME" XDG_CONFIG_HOME="$TEMP_HOME/.config" \
        "$lua_bin" "$REPO_ROOT/tests/lua/stub-hl.lua" "$config_dir" >/dev/null
done

printf 'Hyprland Lua config checks passed.\n'
