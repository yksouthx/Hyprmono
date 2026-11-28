# HyprMono Caffyne bar and media widget

Caffyne Shell provides the bar, MPRIS media applet, workspace controls, system
tray, clock, network, volume, brightness, energy and settings applets. HyprMono
adds a floating top-bar visual system and a custom media widget.

The media widget:

- follows the latest active MPRIS player
- shows artist/title metadata
- starts CAVA only while playback is active
- renders a 12-band raw ASCII spectrum
- stops CAVA and reduces to a static icon when playback pauses

The CAVA profile is stored at `~/.config/caffyne-shell/cava.conf`. The bar CSS
override is stored at `~/.config/caffyne-shell/style/hyprmono.css`.

The same configured bar includes Caffyne's active-window title, process/CPU
indicator and a HyprMono RAM meter. The HyprMono wallpaper is copied into
`~/.config/caffyne-shell/wallpapers/hyprmono.webp` and selected in Caffyne's
`config/config.json`.
