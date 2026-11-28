# HyprMono Caffyne bar and media widget

Caffyne Shell provides the bar, MPRIS media applet, workspace controls, system
tray, clock, network, volume, brightness, energy and settings applets. HyprMono
adds a floating top-bar visual system and a custom media widget.

The `Dash` control opens Caffyne's application menu and shell dashboard.
`Mod+R` opens the same Dash; its applet, search, and controls replace the
separate Rofi menu and Waybar bar. Their existing configuration and package
files can be reviewed and removed through `hyprmono migrate`, which backs up
files and requires confirmation for each candidate.

The media widget:

- follows the latest active MPRIS player
- shows artist/title metadata
- starts CAVA only while playback is active
- renders a 12-band raw ASCII spectrum
- stops CAVA and reduces to a static icon when playback pauses

The shipped bar config includes the `Media` applet. The Caffyne installer also
adds it to existing bar layouts when missing, without replacing their other
applets. Spotify's MPRIS metadata is shown by the same applet.

Spotify windows open on Niri's persistent named `Music` workspace. Use
`Mod+M` to focus it. Niri has named workspaces rather than Hyprland-style
hidden special workspaces, so `Music` remains part of Niri's normal workspace
model.

The CAVA profile is stored at `~/.config/caffyne-shell/cava.conf`. The bar CSS
override is stored at `~/.config/caffyne-shell/style/hyprmono.css`.

The same configured bar includes Caffyne's active-window title, process/CPU
indicator and a HyprMono RAM meter. The HyprMono wallpaper is copied into
`~/.config/caffyne-shell/wallpapers/hyprmono.webp` and selected in Caffyne's
`config/config.json`.

The Dash uses a dark translucent scrim, rounded application tiles, and
high-contrast hover states from `assets/caffyne-shell/hyprmono.css`.
