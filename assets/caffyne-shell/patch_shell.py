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

profile_file = root / "windows" / "quick_settings" / "buttons" / "profile.py"
profile_file.write_text((Path(os.environ["OVERRIDE_DIR"]) / "profile.py").read_text())

profile_init = root / "windows" / "quick_settings" / "buttons" / "__init__.py"
text = profile_init.read_text()
if "VisualProfileButton" not in text:
    text = text.replace(
        "from .settings import SettingsButton\n",
        "from .settings import SettingsButton\nfrom .profile import VisualProfileButton\n",
    )
    text = text.replace(
        '    "SettingsButton"\n',
        '    "SettingsButton",\n    "VisualProfileButton"\n',
    )
profile_init.write_text(text)

quick_settings_file = root / "windows" / "quick_settings" / "quick_settings.py"
text = quick_settings_file.read_text()
if "VisualProfileButton" not in text:
    text = text.replace(
        "from .buttons import",
        "from .buttons import",
    )
    text = text.replace(
        "CaffieneButton, PowerModes",
        "CaffieneButton, PowerModes, VisualProfileButton",
    )
    text = text.replace(
        "                                    CaffieneButton(),",
        "                                    CaffieneButton(),\n                                    VisualProfileButton(),",
    )
quick_settings_file.write_text(text)

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
