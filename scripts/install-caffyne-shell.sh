#!/usr/bin/env bash
# Clone or update Caffyne Shell and prepare its Python environment.
set -Eeuo pipefail

readonly CAFFYNE_REPO="${CAFFYNE_REPO:-https://github.com/caffyne-org/caffyne-shell.git}"
readonly INSTALL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/caffyne-shell"
readonly OVERRIDE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../assets/caffyne-shell" && pwd)"
readonly HYPRMONO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$(dirname "$INSTALL_DIR")"

if [[ -d "$INSTALL_DIR/.git" ]]; then
    git -C "$INSTALL_DIR" fetch --quiet origin
    git -C "$INSTALL_DIR" reset --quiet --hard origin/main
else
    rm -rf -- "$INSTALL_DIR"
    git clone --quiet "$CAFFYNE_REPO" "$INSTALL_DIR"
fi

python3 -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/python" -m pip install --upgrade pip --quiet
"$INSTALL_DIR/venv/bin/python" -m pip install -r "$INSTALL_DIR/requirements.txt" --quiet

if [[ -f "$INSTALL_DIR/snippets/blur/lib/Makefile" ]]; then
    make -C "$INSTALL_DIR/snippets/blur/lib"
fi
if [[ -f "$INSTALL_DIR/snippets/hacktk/lib/Makefile" ]]; then
    make -C "$INSTALL_DIR/snippets/hacktk/lib"
fi

# HyprMono design overrides.
mkdir -p "$INSTALL_DIR/style" "$INSTALL_DIR/config"
\cp -f "$OVERRIDE_DIR/cava.conf" "$INSTALL_DIR/cava.conf"
\cp -f "$OVERRIDE_DIR/hyprmono.css" "$INSTALL_DIR/style/hyprmono.css"
\cp -f "$OVERRIDE_DIR/media.py" "$INSTALL_DIR/bar_widgets/media.py"
\cp -f "$OVERRIDE_DIR/ram.py" "$INSTALL_DIR/bar_widgets/ram.py"
if [[ ! -s "$INSTALL_DIR/config/config.json" ]]; then
    \cp -f "$OVERRIDE_DIR/config.json" "$INSTALL_DIR/config/config.json"
    sed -i "s#__HYPRMONO_WALLPAPER__#$INSTALL_DIR/wallpapers/hyprmono.webp#" "$INSTALL_DIR/config/config.json"
fi
\mkdir -p "$INSTALL_DIR/wallpapers"
\cp -f "$HYPRMONO_ROOT/assets/wall.webp" "$INSTALL_DIR/wallpapers/hyprmono.webp"

OVERRIDE_DIR="$OVERRIDE_DIR" CAFFYNE_ROOT="$INSTALL_DIR" python3 "$OVERRIDE_DIR/patch_shell.py"

if ! grep -q '@import "hyprmono.css";' "$INSTALL_DIR/style/style.css"; then
    printf '\n@import "hyprmono.css";\n' >> "$INSTALL_DIR/style/style.css"
fi
