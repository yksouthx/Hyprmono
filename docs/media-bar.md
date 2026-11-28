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

## Desktop widgets and lock screen

The primary output starts with Caffyne's Clock, Calendar, and Processes
widgets. Processes displays CPU load, memory use, and CPU temperature when the
hardware exposes it. Open the Dash with `Mod+R`, switch to **Applets**, and drag
an applet onto the desktop to add it. Drag placed widgets to move them;
right-click one to remove it. Caffyne saves placements in
`~/.config/caffyne-shell/config/config.json`.

`Mod+Alt+L` uses Caffyne's native session-lock screen, with the blurred
wallpaper, clock, and password prompt. Caffyne's idle service uses that same
native lock screen directly. If it is unavailable or fails when invoked through
the HyprMono lock helper, the helper falls back to `swaylock`.
