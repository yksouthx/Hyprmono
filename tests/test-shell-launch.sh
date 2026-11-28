#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
trap 'rm -rf -- "$TEMP_DIR"' EXIT

grep -q '^bars = 12$' "$REPO_ROOT/assets/caffyne-shell/cava.conf"
grep -q 'bar-cava' "$REPO_ROOT/assets/caffyne-shell/hyprmono.css"
grep -q 'border-radius: 999px' "$REPO_ROOT/assets/caffyne-shell/hyprmono.css"
grep -q '_read_cava' "$REPO_ROOT/assets/caffyne-shell/media.py"
grep -q '"Focused"' "$REPO_ROOT/assets/caffyne-shell/config.json"
grep -q '"Processes"' "$REPO_ROOT/assets/caffyne-shell/config.json"
grep -q '"RAM"' "$REPO_ROOT/assets/caffyne-shell/config.json"
grep -q '"Media"' "$REPO_ROOT/assets/caffyne-shell/config.json"
! grep -q '"widget": "Launcher"' "$REPO_ROOT/assets/caffyne-shell/config.json"
grep -q '__HYPRMONO_WALLPAPER__' "$REPO_ROOT/assets/caffyne-shell/config.json"
grep -q '^\.dash-grid {' "$REPO_ROOT/assets/caffyne-shell/hyprmono.css"
grep -q '^\.dash-launcher-app:hover,' "$REPO_ROOT/assets/caffyne-shell/hyprmono.css"

patch_root="$TEMP_DIR/caffyne"
mkdir -p "$patch_root/bar_widgets" "$patch_root/config" "$patch_root/wallpapers"
printf 'from .base import BaseButton, StatButton, ProgressButton\n    "DashButton",\n' \
    > "$patch_root/bar_widgets/__init__.py"
printf '    CalculatorButton, SessionButton, KeyboardButton, SystemTray, Dock, BrightnessButton, DashButton\n    "Dash":          DashButton,\n' \
    > "$patch_root/bar.py"
cat > "$patch_root/config/config.json" <<'EOF'
{
  "custom-setting": "preserved",
  "bars": {
    "configs": [
      {
        "bars": [
          {"left": ["Dash"], "center": ["Clock"], "right": ["Tray"]},
          {"left": [{"widget": "Media", "variant": "icon"}]}
        ]
      }
    ]
  }
}
EOF

CAFFYNE_ROOT="$patch_root" python3 "$REPO_ROOT/assets/caffyne-shell/patch_shell.py"
CAFFYNE_ROOT="$patch_root" python3 "$REPO_ROOT/assets/caffyne-shell/patch_shell.py"
python3 - "$patch_root/config/config.json" "$patch_root/wallpapers/hyprmono.webp" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as config_file:
    config = json.load(config_file)
bars = config["bars"]["configs"][0]["bars"]
assert bars[0]["left"] == ["Dash", "Media"]
assert bars[1]["left"] == [{"widget": "Media", "variant": "icon"}]
assert config["custom-setting"] == "preserved"
assert config["wallpaper"]["path"] == sys.argv[2]
PY

mkdir -p "$TEMP_DIR/bin" "$TEMP_DIR/config/caffyne-shell"
cat > "$TEMP_DIR/config/caffyne-shell/start.sh" <<'EOF'
#!/usr/bin/env bash
printf 'caffyne shell started\n' > "$CAPTURE"
EOF
chmod +x "$TEMP_DIR/config/caffyne-shell/start.sh"

HOME="$TEMP_DIR" \
XDG_CONFIG_HOME="$TEMP_DIR/config" \
PATH="$TEMP_DIR/bin:$PATH" \
CAPTURE="$TEMP_DIR/launch.out" \
    bash "$REPO_ROOT/scripts/start-shell.sh"

rm "$TEMP_DIR/config/caffyne-shell/start.sh"
HOME="$TEMP_DIR" \
XDG_CONFIG_HOME="$TEMP_DIR/config" \
PATH="$TEMP_DIR/bin:$PATH" \
CAPTURE="$TEMP_DIR/no-shell.out" \
    bash "$REPO_ROOT/scripts/start-shell.sh"

grep -q '^caffyne shell started$' "$TEMP_DIR/launch.out"
[[ ! -e "$TEMP_DIR/no-shell.out" ]]

printf 'Caffyne Shell startup passed.\n'
