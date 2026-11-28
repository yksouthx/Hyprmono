#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT

qmllint_bin=""
for candidate in qmllint qmllint6 qmllint-qt6 /usr/lib/qt6/bin/qmllint; do
    if command -v "$candidate" >/dev/null 2>&1; then
        qmllint_bin="$candidate"
        break
    fi
done
if [[ -z "$qmllint_bin" ]]; then
    echo "SKIP: qmllint is not installed"
    exit 0
fi

# Quickshell's QML modules are not available to qmllint, so "failed to import"
# warnings are expected. Only syntax errors (file:line:col: message) are failures.
pattern='^(Error: )?[^[:space:]]+\.qml:[0-9]+:[0-9]+: '
status=0
for file in "$REPO_ROOT"/config/quickshell/*.qml "$REPO_ROOT"/config/installer/*.qml; do
    output=$("$qmllint_bin" "$file" 2>&1 || true)
    if grep -qE "$pattern" <<< "$output"; then
        printf 'SYNTAX ERROR in %s\n%s\n' "${file#"$REPO_ROOT"/}" "$(grep -E "$pattern" <<< "$output")" >&2
        status=1
    fi
done
[[ "$status" -eq 0 ]]

# Nothing may nest a Process inside another Process (it has no default property,
# so the whole window would fail to load).
if python3 - "$REPO_ROOT" <<'PYEOF'
import re, sys, glob
bad = []
for path in glob.glob(sys.argv[1] + "/config/quickshell/*.qml"):
    depth_stack = []
    for number, line in enumerate(open(path), 1):
        indent = len(line) - len(line.lstrip())
        stripped = line.strip()
        while depth_stack and indent <= depth_stack[-1][0] and stripped and not stripped.startswith("}"):
            depth_stack.pop()
        if re.match(r"Process\s*\{", stripped):
            if any(kind == "Process" for _, kind in depth_stack):
                bad.append(f"{path}:{number}")
            depth_stack.append((indent, "Process"))
        elif re.match(r"[A-Z][A-Za-z0-9_.]*\s*\{", stripped):
            depth_stack.append((indent, "other"))
sys.exit(1 if bad else 0)
PYEOF
then :; else
    echo "A Process is nested inside another Process" >&2
    exit 1
fi

printf 'QML syntax checks passed.\n'
