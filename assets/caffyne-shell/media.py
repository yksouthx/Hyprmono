import os
import subprocess

from gi.repository import GLib
from fabric.widgets.box import Box
from fabric.widgets.eventbox import EventBox
from fabric.widgets.label import Label
from services.player import PlayerService
from services.singletons import player_manager, edit_mode
from snippets import Icon, ScrollingLabel


class MediaPlayer(Box):
    def __init__(self, name: str, service: PlayerService):
        self.name = name
        self.service = service
        self.label = ScrollingLabel(
            v_align="center",
            style_classes=["bar-media-label"],
            label=name,
            max_width=188,
            pixels_per_second=90,
        )
        self.cava_bars = [
            Box(style_classes=["cava-bar"], size=(2, 4))
            for _ in range(12)
        ]
        self.cava = Box(
            orientation="h",
            spacing=2,
            v_align="center",
            style_classes=["bar-cava"],
            children=self.cava_bars,
        )
        self.process = None
        self.io_watch = None

        super().__init__(
            spacing=7,
            style_classes=["bar-media"],
            children=[
                Icon(icon_name="music-notes-duotone", icon_size=16),
                EventBox(child=self.label),
                self.cava,
            ],
        )

        service.connect("meta-change", self._on_meta_change)
        service.connect("play", lambda *_: self._set_playing(True))
        service.connect("pause", lambda *_: self._set_playing(False))
        self._on_meta_change(service, service._player.props.metadata, service._player)
        self._set_playing(self._is_playing())

    def _is_playing(self):
        status = getattr(self.service.status, "value_name", "")
        return status == "PLAYERCTL_PLAYBACK_STATUS_PLAYING"

    def _on_meta_change(self, _service, metadata, _player):
        keys = metadata.keys()
        artist = metadata["xesam:artist"][0] if "xesam:artist" in keys else ""
        title = metadata["xesam:title"] if "xesam:title" in keys else ""
        self.label.set_label(f"{title} - {artist}" if title and artist else title or artist or self.name)

    def _set_playing(self, playing):
        if playing:
            self._start_cava()
        else:
            self._stop_cava()

    def _start_cava(self):
        if self.process is not None:
            return
        cava = os.path.expanduser("~/.config/caffyne-shell/cava.conf")
        try:
            self.process = subprocess.Popen(
                ["cava", "-p", cava],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            self.io_watch = GLib.io_add_watch(
                self.process.stdout.fileno(),
                GLib.IO_IN | GLib.IO_HUP,
                self._read_cava,
            )
        except (FileNotFoundError, OSError):
            self.process = None

    def _read_cava(self, _source, _condition):
        line = self.process.stdout.readline().strip()
        if not line:
            return True
        values = [int(value) for value in line.split(";") if value.isdigit()]
        if values:
            for index, bar in enumerate(self.cava_bars):
                value = values[index] if index < len(values) else 0
                height = max(4, min(18, round(value * 18 / 100)))
                bar.set_size_request(2, height)
        return True

    def _stop_cava(self):
        if self.io_watch is not None:
            GLib.source_remove(self.io_watch)
            self.io_watch = None
        if self.process is not None:
            self.process.terminate()
            self.process = None
        for bar in self.cava_bars:
            bar.set_size_request(2, 4)


class Media(Box):
    def __init__(self, monitor_id: int, vertical: bool, variant, **kwargs):
        self._players = {}
        self._player_order = []
        self.placeholder = Box(
            spacing=4,
            style_classes=["bar-button", "bar-media-placeholder"],
            children=[Icon(icon_name="music-notes-duotone", icon_size=16)],
        )
        super().__init__(
            spacing=4,
            children=[self.placeholder],
            style_classes=["bar-media"],
            **kwargs,
        )
        self.connect("realize", self._on_realize)

    def _on_realize(self, *_):
        player_manager.connect("new-player", lambda _, name, service: self._add_player(name, service))
        player_manager.connect("player-vanish", lambda _, name: self._remove_player(name))
        edit_mode.connect("notify::edit-mode", lambda *_: self._update_visibility())
        for name, service in player_manager.get_all_services().items():
            self._add_player(name, service)
        GLib.idle_add(self._update_visibility)

    def _add_player(self, name, service):
        if name in self._players:
            return
        widget = MediaPlayer(name, service)
        widget.show_all()
        self._players[name] = widget
        self._player_order.append(name)
        self.add(widget)
        self._show_latest()
        self._update_visibility()

    def _remove_player(self, name):
        if name not in self._players:
            return
        widget = self._players.pop(name)
        self._player_order.remove(name)
        self.remove(widget)
        self._show_latest()
        self._update_visibility()

    def _show_latest(self):
        if self._player_order:
            latest = self._player_order[-1]
            for name, widget in self._players.items():
                widget.set_visible(name == latest)

    def _update_visibility(self):
        has_players = bool(self._players)
        self.placeholder.set_visible(not has_players and not edit_mode.edit_mode)
