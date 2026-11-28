#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

make_caffyne_fixture() {
    local root="$1"
    mkdir -p "$root/bar_widgets" "$root/config"
    cat > "$root/bar_widgets/__init__.py" <<'EOF'
from .base import BaseButton, StatButton, ProgressButton
    "DashButton",
EOF
    cat > "$root/bar.py" <<'EOF'
from bar_widgets import CalculatorButton, SessionButton, KeyboardButton, SystemTray, Dock, BrightnessButton, DashButton
    "Dash":          DashButton,
EOF
    cat > "$root/config/config.json" <<'EOF'
{
  "bars": {
    "configs": [
      {
        "bars": [
          {"left": ["Dash"], "center": [], "right": []}
        ]
      }
    ]
  },
  "wallpaper": {"path": "old-wallpaper"}
}
EOF
}

default_root="$TEMP_DIR/default"
make_caffyne_fixture "$default_root"
CAFFYNE_ROOT="$default_root" python3 "$REPO_ROOT/assets/caffyne-shell/patch_shell.py"
python3 - "$default_root/config/config.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    config = json.load(file)

placements = config["desktop_canvas"]["placements"]["0"]
assert [entry["key"] for entry in placements] == ["Clock", "Calendar", "Processes"]
assert [entry["ax"] for entry in placements] == ["left", "left", "right"]
assert all(entry["dx"] == 0 for entry in placements)
assert "Media" in config["bars"]["configs"][0]["bars"][0]["left"]
PY

custom_root="$TEMP_DIR/custom"
make_caffyne_fixture "$custom_root"
python3 - "$custom_root/config/config.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as file:
    config = json.load(file)
config["desktop_canvas"] = {
    "placements": {
        "0": [{"key": "Weather", "ax": "right", "dx": 0, "ry": 0.1}]
    }
}
with open(path, "w", encoding="utf-8") as file:
    json.dump(config, file)
PY
CAFFYNE_ROOT="$custom_root" python3 "$REPO_ROOT/assets/caffyne-shell/patch_shell.py"
python3 - "$custom_root/config/config.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    config = json.load(file)

keys = [entry["key"] for entry in config["desktop_canvas"]["placements"]["0"]]
assert keys == ["Weather", "Processes"]
PY

python3 - "$custom_root/config/config.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as file:
    config = json.load(file)
config["desktop_canvas"]["placements"]["0"] = [
    entry for entry in config["desktop_canvas"]["placements"]["0"]
    if entry["key"] != "Processes"
]
with open(path, "w", encoding="utf-8") as file:
    json.dump(config, file)
PY
CAFFYNE_ROOT="$custom_root" python3 "$REPO_ROOT/assets/caffyne-shell/patch_shell.py"
python3 - "$custom_root/config/config.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    config = json.load(file)

keys = [entry["key"] for entry in config["desktop_canvas"]["placements"]["0"]]
assert keys == ["Weather"]
PY

empty_root="$TEMP_DIR/empty"
make_caffyne_fixture "$empty_root"
python3 - "$empty_root/config/config.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as file:
    config = json.load(file)
config["desktop_canvas"] = {"placements": {"0": []}}
with open(path, "w", encoding="utf-8") as file:
    json.dump(config, file)
PY
CAFFYNE_ROOT="$empty_root" python3 "$REPO_ROOT/assets/caffyne-shell/patch_shell.py"
python3 - "$empty_root/config/config.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    config = json.load(file)

assert [entry["key"] for entry in config["desktop_canvas"]["placements"]["0"]] == ["Processes"]
PY

python3 - "$empty_root/config/config.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as file:
    config = json.load(file)
config["desktop_canvas"]["placements"]["0"] = []
with open(path, "w", encoding="utf-8") as file:
    json.dump(config, file)
PY
CAFFYNE_ROOT="$empty_root" python3 "$REPO_ROOT/assets/caffyne-shell/patch_shell.py"
python3 - "$empty_root/config/config.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    config = json.load(file)

assert config["desktop_canvas"]["placements"] == {"0": []}
PY

printf 'Caffyne desktop widget defaults and user settings passed.\n'
