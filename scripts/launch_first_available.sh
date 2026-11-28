#!/usr/bin/env bash
# Launch the first available command from the provided list.
# Usage: launch_first_available.sh 'cmd1 --args' 'cmd2' ...
# Each argument is split on whitespace (no shell quoting or expansion).
set -u

for cmd in "$@"; do
    [[ -n "$cmd" ]] || continue
    read -r -a argv <<< "$cmd"
    command -v "${argv[0]}" >/dev/null 2>&1 || continue
    "${argv[@]}" &
    disown "$!" 2>/dev/null || true
    exit 0
done

echo "launch_first_available: no suitable command found in: $*" >&2
exit 1
