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
    except (json.JSONDecodeError, OSError) as error:
        raise SystemExit(f"Could not read Caffyne config {config_file}: {error}") from error

    try:
        if not isinstance(data, dict):
            raise TypeError("top-level config must be an object")
        bars = data.get("bars")
        if not isinstance(bars, dict):
            raise TypeError("bars must be an object")
        bar_configs = bars.get("configs")
        if not isinstance(bar_configs, list):
            raise TypeError("bars.configs must be a list")
        for monitor_config in bar_configs:
            if (
                not isinstance(monitor_config, dict)
                or not isinstance(monitor_config.get("bars"), list)
            ):
                raise TypeError("each bars.configs entry must contain a bars list")
            for bar_config in monitor_config["bars"]:
                if not isinstance(bar_config, dict):
                    raise TypeError("each bar config must be an object")
                applet_lists = [
                    bar_config.setdefault("left", []),
                    bar_config.setdefault("center", []),
                    bar_config.setdefault("right", []),
                ]
                if not all(isinstance(applets, list) for applets in applet_lists):
                    raise TypeError("bar applet sections must be lists")
                has_media = any(
                    applet == "Media"
                    or (
                        isinstance(applet, dict)
                        and applet.get("widget") == "Media"
                    )
                    for applets in applet_lists
                    for applet in applets
                )
                if not has_media:
                    applet_lists[0].append("Media")
    except (KeyError, TypeError) as error:
        raise SystemExit(f"Could not add the Media applet to {config_file}: {error}") from error

    try:
        if "wallpaper" not in data:
            data["wallpaper"] = {}
        data["wallpaper"]["path"] = str(wallpaper)
        config_file.write_text(json.dumps(data, indent=2) + "\n")
    except (OSError, TypeError) as error:
        raise SystemExit(f"Could not update Caffyne config {config_file}: {error}") from error
