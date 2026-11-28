import os
import json
from pathlib import Path


root = Path(os.environ["CAFFYNE_ROOT"])
desktop_widget_migration = root / ".hyprmono-desktop-widgets-v1"
DEFAULT_DESKTOP_PLACEMENTS = {
    "0": [
        {"key": "Clock", "ax": "left", "dx": 0, "ry": 0.02},
        {"key": "Calendar", "ax": "left", "dx": 0, "ry": 0.26},
        {"key": "Processes", "ax": "right", "dx": 0, "ry": 0.02},
    ]
}
DEFAULT_RESOURCE_PLACEMENT = {
    "key": "Processes",
    "ax": "right",
    "dx": 0,
    "ry": 0.02,
}

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

        if not desktop_widget_migration.exists():
            desktop_canvas = data.setdefault("desktop_canvas", {})
            if not isinstance(desktop_canvas, dict):
                raise TypeError("desktop_canvas must be an object")
            placements = desktop_canvas.get("placements")
            if placements is None or placements == {}:
                desktop_canvas["placements"] = DEFAULT_DESKTOP_PLACEMENTS
            elif not isinstance(placements, dict):
                raise TypeError("desktop_canvas.placements must be an object")
            else:
                if any(not isinstance(entries, list) for entries in placements.values()):
                    raise TypeError("each desktop_canvas placement must be a list")
                has_resource_widget = any(
                    isinstance(entry, dict) and entry.get("key") == "Processes"
                    for entries in placements.values()
                    for entry in entries
                )
                if not has_resource_widget:
                    primary = placements.setdefault("0", [])
                    if not isinstance(primary, list):
                        raise TypeError("primary desktop_canvas placement must be a list")
                    primary.append(DEFAULT_RESOURCE_PLACEMENT)
    except (KeyError, TypeError) as error:
        raise SystemExit(f"Could not update Caffyne applets in {config_file}: {error}") from error

    try:
        if "wallpaper" not in data:
            data["wallpaper"] = {}
        data["wallpaper"]["path"] = str(wallpaper)
        config_file.write_text(json.dumps(data, indent=2) + "\n")
    except (OSError, TypeError) as error:
        raise SystemExit(f"Could not update Caffyne config {config_file}: {error}") from error

    if not desktop_widget_migration.exists():
        try:
            desktop_widget_migration.write_text("1\n", encoding="utf-8")
        except OSError as error:
            raise SystemExit(
                f"Could not record desktop widget defaults in {desktop_widget_migration}: {error}"
            ) from error
