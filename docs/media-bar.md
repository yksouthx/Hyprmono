# HyprMono bar and media dashboard

The project-owned Quickshell UI lives in `config/hyprmono/`:

- `shell.qml` selects the active MPRIS player and coordinates panels.
- `Bar.qml` provides workspaces, active-window text, media, clock, RAM/load
  status, tray icons and the quick-audio-settings entry point.
- `MediaPill.qml` shows cover art and track information, expands on hover,
  exposes playback shortcuts and a thin progress line.
- `MediaDashboard.qml` provides artwork, album/artist details, seek, playback,
  previous/next, shuffle, repeat and player-volume controls.
- `QuickSettings.qml` adjusts the PipeWire default output with `wpctl`.

The bar reads RAM and load status asynchronously from `/proc` through
Quickshell's file I/O, refreshing every 10 seconds without spawning a shell
process.

The MPRIS position timer runs only during playback. CAVA is opt-in: set
`cavaVisualizerEnabled` to `true` in `shell.qml` and install CAVA to use the
audio-reactive display. With it disabled, the pill uses a static indicator and
does not start a CAVA process.

[Lyne Dots](https://github.com/caioax/lyne-dots) is the visual reference for
the compact media pill and three-part layout. Its repository is licensed under
GPL-3.0. This implementation was written for HyprMono and does not include
Lyne Dots source code or assets; therefore no Lyne Dots asset licenses are
being relied upon.
