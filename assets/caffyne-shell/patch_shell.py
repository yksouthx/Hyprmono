import os
import json
from pathlib import Path


root = Path(os.environ["CAFFYNE_ROOT"])

init_file = root / "bar_widgets" / "__init__.py"
text = init_file.read_text()
if "from .ram import RAMIndicatorButton" not in text:
    text = text.replace(
        "from .base import BaseButton, StatButton, ProgressButton\n",
        "from .base import BaseButton, StatButton, ProgressButton\n"
        "from .ram import RAMIndicatorButton\n",
    )
text = text.replace(
    '    "DashButton",\n',
    '    "DashButton",\n    "RAMIndicatorButton",\n',
)
init_file.write_text(text)

bar_file = root / "bar.py"
text = bar_file.read_text()
if "RAMIndicatorButton" not in text:
    text = text.replace(
        "    CalculatorButton, SessionButton, KeyboardButton, SystemTray, Dock, BrightnessButton, DashButton\n",
        "    CalculatorButton, SessionButton, KeyboardButton, SystemTray, Dock, BrightnessButton, DashButton,\n"
        "    RAMIndicatorButton\n",
    )
    text = text.replace(
        '    "Dash":          DashButton,\n',
        '    "Dash":          DashButton,\n    "RAM":           RAMIndicatorButton,\n',
    )
bar_file.write_text(text)

config_file = root / "config" / "config.json"
wallpaper = root / "wallpapers" / "hyprmono.webp"
if config_file.is_file():
    try:
        data = json.loads(config_file.read_text())
        if "wallpaper" not in data:
            data["wallpaper"] = {}
        data["wallpaper"]["path"] = str(wallpaper)
        config_file.write_text(json.dumps(data, indent=2) + "\n")
    except (json.JSONDecodeError, OSError):
        pass
