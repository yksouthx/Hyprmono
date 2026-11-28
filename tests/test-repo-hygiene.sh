#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
cd "$REPO_ROOT"

# Every script must parse.
while IFS= read -r file; do
    bash -n "$file"
done < <(find install.sh test_install.sh scripts tests -type f \( -name '*.sh' -o -name run-installer-terminal \))

# Scripts the installer runs directly must be executable in git.
if git rev-parse --git-dir >/dev/null 2>&1; then
    while IFS= read -r file; do
        mode=$(git ls-files -s -- "$file" | awk '{print $1}')
        if [[ -n "$mode" && "$mode" != 100755 ]]; then
            echo "not executable in git: $file ($mode)" >&2
            exit 1
        fi
    done < <(find install.sh test_install.sh scripts -type f \( -name '*.sh' -o -name run-installer-terminal \))
fi

# Nothing may depend on HyDE's hyde-shell runner.
if grep -rIn 'hyde-shell\|HYDE_' config install.sh scripts/*.sh 2>/dev/null \
    | grep -v 'scripts/\(install\|uninstall\|migrate\)\.sh'; then
    echo "found a dependency on hyde-shell" >&2
    exit 1
fi

# The launcher was renamed; no live reference to the old name may remain.
if grep -rIn 'start-caelestia' config install.sh scripts/hyprmono.sh scripts/start-*.sh tests 2>/dev/null \
    | grep -v 'tests/test-repo-hygiene.sh'; then
    echo "stale reference to start-caelestia.sh" >&2
    exit 1
fi

# The linter must be clean at warning level when it is available.
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -S warning install.sh test_install.sh scripts/* tests/*.sh
else
    echo "note: shellcheck not installed, skipped"
fi

printf 'Repository hygiene checks passed.\n'
