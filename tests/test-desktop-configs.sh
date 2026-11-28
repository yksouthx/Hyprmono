#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT

if ! command -v python3 >/dev/null 2>&1; then
    echo "SKIP: python3 is required to validate the fnott/fuzzel configs"
    exit 0
fi

# Keys are checked against fnott.ini(5) and fuzzel.ini(5). An unknown key makes
# the daemon complain (or refuse to start), so new keys must be added here on purpose.
python3 - "$REPO_ROOT" <<'PYEOF'
import re
import sys

root = sys.argv[1]
errors = []

def parse(path):
    """Return {section: {key: value}}; the unnamed top section is called 'main'."""
    sections, current = {"main": {}}, "main"
    for number, raw in enumerate(open(path), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        header = re.fullmatch(r"\[([a-z-]+)\]", line)
        if header:
            current = header.group(1)
            sections.setdefault(current, {})
            continue
        if "=" not in line:
            errors.append(f"{path}:{number}: not a key=value line: {line!r}")
            continue
        key, value = (part.strip() for part in line.split("=", 1))
        sections[current][key] = value
    return sections

def check(path, allowed, color_keys, color_sections=None):
    sections = parse(path)
    for section, items in sections.items():
        if section not in allowed:
            errors.append(f"{path}: unknown section [{section}]")
            continue
        for key, value in items.items():
            if key not in allowed[section]:
                errors.append(f"{path}: unknown key '{key}' in [{section}]")
            in_color_section = color_sections is None or section in color_sections
            if key in color_keys and in_color_section and not re.fullmatch(r"[0-9a-fA-F]{8}", value):
                errors.append(f"{path}: '{key}={value}' is not an RRGGBBAA color")

fnott_keys = set("""output min-width max-width max-height anchor stacking-order
edge-margin-vertical edge-margin-horizontal notification-margin icon-theme max-icon-size
selection-helper selection-helper-uses-null-separator play-sound scaling-filter dpi-aware
layer background border-color border-radius border-size padding-vertical padding-horizontal
title-font title-color title-format summary-font summary-color summary-format body-font
body-color body-format progress-bar-height progress-color progress-style max-timeout
default-timeout idle-timeout sound-file""".split())
check(f"{root}/config/fnott/fnott.ini",
      {"main": fnott_keys, "low": fnott_keys, "normal": fnott_keys, "critical": fnott_keys},
      {"background", "border-color", "title-color", "summary-color", "body-color", "progress-color"})

check(f"{root}/config/fuzzel/fuzzel.ini",
      {
          "main": set("""font prompt lines width horizontal-pad vertical-pad inner-pad
                         icons-enabled layer terminal anchor""".split()),
          "colors": set("""background text prompt match selection selection-text
                          selection-match border""".split()),
          "border": {"width", "radius"},
      },
      {"background", "text", "prompt", "match", "selection", "selection-text",
       "selection-match", "border"},
      color_sections={"colors"})

if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
PYEOF

printf 'fnott and fuzzel config checks passed.\n'
