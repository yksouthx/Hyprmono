from gi.repository import GLib

from .base import BaseButton
from snippets import Icon


class RAMIndicatorButton(BaseButton):
    def __init__(self, monitor_id, vertical, variant=None, **kwargs):
        super().__init__(
            icon=Icon(icon_name="memory-duotone", icon_size=16),
            label="0%",
            variant=variant or "icon+label",
            **kwargs,
        )
        self.add_style_class("ram")
        self._update()
        GLib.timeout_add_seconds(10, self._update)

    def _update(self):
        used_percent = 0
        try:
            values = {}
            with open("/proc/meminfo", "r", encoding="utf-8") as meminfo:
                for line in meminfo:
                    key, value = line.split(":", 1)
                    values[key] = int(value.strip().split()[0])
            total = values.get("MemTotal", 0)
            available = values.get("MemAvailable", values.get("MemFree", 0))
            if total:
                used_percent = round((total - available) * 100 / total)
        except (OSError, ValueError):
            pass
        self._update_label(f"{used_percent}%")
        return True
