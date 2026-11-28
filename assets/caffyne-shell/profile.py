import os
import subprocess
from fabric.widgets.label import Label
from snippets import Icon

from .button import QSButton


class VisualProfileButton(QSButton):
    PROFILES = ("low-resource", "balanced", "full-visual")

    def __init__(self):
        super().__init__(
            icon=Icon(icon_name="sliders-horizontal-duotone", pixel_size=16),
            label=Label(label=f"Visual: {self._current()}"),
            on_activate=lambda _: self._cycle(),
            on_deactivate=lambda _: self._cycle(),
        )
        self.label = self._label
        setattr(self, "active", self._current() != "low-resource")

    def _profile_file(self):
        return os.path.expanduser("~/.config/hypr/profile")

    def _current(self):
        try:
            with open(self._profile_file(), "r", encoding="utf-8") as profile_file:
                profile = profile_file.readline().strip()
            if profile in self.PROFILES:
                return profile
        except OSError:
            pass
        return "full-visual"

    def _cycle(self):
        current = self._current()
        next_profile = self.PROFILES[(self.PROFILES.index(current) + 1) % len(self.PROFILES)]
        os.makedirs(os.path.dirname(self._profile_file()), exist_ok=True)
        temporary = self._profile_file() + ".tmp"
        with open(temporary, "w", encoding="utf-8") as profile_file:
            profile_file.write(next_profile)
        os.replace(temporary, self._profile_file())
        subprocess.run(["hyprctl", "reload"], check=False)
        self.label.set_label(f"Visual: {next_profile}")
        setattr(self, "active", next_profile != "low-resource")
