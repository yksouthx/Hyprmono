-- HyprMono Hyprland configuration
--
-- This is the current Lua configuration format documented by Hyprland.
-- Keep personal changes in custom/*.lua; those modules are loaded last.
-- https://wiki.hypr.land/configuring/

local colours = require("./modules/colours")

------------------
---- MONITORS ----
------------------

-- A generic fallback is safer than assuming a particular laptop connector.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

---------------------
---- ENVIRONMENT ----
---------------------

hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("HYPRCURSOR_SIZE", "32")
hl.env("XCURSOR_SIZE", "32")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
-- Caelestia's lightweight shell profile.
hl.env("qsConfig", "ii")

-----------------------
----- PERMISSIONS -----
-----------------------

hl.config({
    ecosystem = {
        enforce_permissions = true,
    },
})
hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        gaps_workspaces = 50,
        border_size = 1,
        col = {
            active_border = colours.primary,
            inactive_border = colours.inactive_border,
        },
        resize_on_border = true,
        no_focus_fallback = true,
        allow_tearing = false,
        layout = "dwindle",
        snap = {
            enabled = true,
            window_gap = 4,
            monitor_gap = 5,
            respect_gaps = true,
        },
    },

    decoration = {
        rounding = 18,
        rounding_power = 2.5,
        active_opacity = 1.0,
        inactive_opacity = 0.92,
        dim_inactive = true,
        dim_strength = 0.05,
        dim_special = 0.2,
        blur = {
            enabled = true,
            xray = true,
            special = false,
            new_optimizations = true,
            size = 10,
            passes = 3,
            brightness = 1.0,
            noise = 0.05,
            contrast = 0.89,
            vibrancy = 0.5,
            vibrancy_darkness = 0.5,
            popups = false,
            popups_ignorealpha = 0.6,
        },
        shadow = {
            enabled = true,
            range = 20,
            offset = "0 2",
            render_power = 4,
            color = "rgba(00000020)",
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false,
    },

    master = {
        new_status = "master",
    },

    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        numlock_by_default = true,
        repeat_delay = 250,
        repeat_rate = 35,
        follow_mouse = 1,
        off_window_axis_events = 2,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor = 0.7,
        },
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        allow_session_lock_restore = true,
        focus_on_activate = true,
    },

    binds = {
        scroll_event_delay = 0,
        hide_special_on_workspace_change = true,
    },

    cursor = {
        zoom_factor = 1.0,
        zoom_rigid = false,
        zoom_disable_aa = true,
        hotspot_padding = 1,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})

-------------------
---- ANIMATIONS ----
-------------------

hl.curve("expressiveFastSpatial", { type = "bezier", points = {{0.42, 1.67}, {0.21, 0.90}} })
hl.curve("expressiveSlowSpatial", { type = "bezier", points = {{0.39, 1.29}, {0.35, 0.98}} })
hl.curve("emphasizedDecel", { type = "bezier", points = {{0.05, 0.70}, {0.10, 1.00}} })
hl.curve("emphasizedAccel", { type = "bezier", points = {{0.30, 0.00}, {0.80, 0.15}} })
hl.curve("standardDecel", { type = "bezier", points = {{0.00, 0.00}, {0.00, 1.00}} })
hl.curve("menuDecel", { type = "bezier", points = {{0.10, 1.00}, {0.00, 1.00}} })
hl.curve("menuAccel", { type = "bezier", points = {{0.52, 0.03}, {0.72, 0.08}} })
hl.curve("stall", { type = "bezier", points = {{1.00, -0.10}, {0.70, 0.85}} })

hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "emphasizedDecel", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "emphasizedDecel", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "emphasizedDecel" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "emphasizedDecel" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "emphasizedDecel" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.7, bezier = "emphasizedDecel", style = "popin 93%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.4, bezier = "menuAccel", style = "popin 94%" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 0.5, bezier = "menuDecel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.7, bezier = "stall" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "menuDecel", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 2.8, bezier = "emphasizedDecel", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1.2, bezier = "emphasizedAccel", style = "slidevert" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 3, bezier = "standardDecel" })

----------------
---- GESTURES ----
----------------

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "swipe", action = "move" })
hl.gesture({ fingers = 3, direction = "pinch", action = "fullscreen" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

---------------------
---- AUTOSTART -------
---------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("$HOME/.local/bin/start-caelestia.sh")
end)

---------------------
---- PROGRAMS -------
---------------------

local terminal = "$HOME/.local/bin/launch_terminal.sh"
local file_manager = "$HOME/.local/bin/launch_first_available.sh 'nautilus' 'nemo' 'thunar' 'kitty -1 fish -c yazi'"
local browser = "$HOME/.local/bin/launch_first_available.sh 'google-chrome-stable' 'zen-browser' 'firefox' 'brave' 'chromium' 'microsoft-edge-stable' 'opera' 'librewolf'"
local text_editor = "$HOME/.local/bin/launch_first_available.sh 'kate' 'gnome-text-editor' 'emacs'"
local menu = "fuzzel --show drun"

---------------------
---- KEYBINDINGS ----
---------------------

local main_mod = "SUPER"
hl.bind(main_mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(main_mod .. " + E", hl.dsp.exec_cmd(file_manager))
hl.bind(main_mod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(main_mod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(main_mod .. " + T", hl.dsp.exec_cmd(text_editor))
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind(main_mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(main_mod .. " + P", hl.dsp.window.pseudo())
hl.bind(main_mod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))

hl.bind(main_mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(main_mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(main_mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(main_mod .. " + down", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(main_mod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(main_mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

local media_binds = {
    { "XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", true },
    { "XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", true },
    { "XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", true },
    { "XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", true },
    { "XF86MonBrightnessUp", "brightnessctl -e4 -n2 set 5%+", true },
    { "XF86MonBrightnessDown", "brightnessctl -e4 -n2 set 5%-", true },
    { "XF86AudioNext", "playerctl next", false },
    { "XF86AudioPause", "playerctl play-pause", false },
    { "XF86AudioPlay", "playerctl play-pause", false },
    { "XF86AudioPrev", "playerctl previous", false },
}
for _, bind in ipairs(media_binds) do
    hl.bind(bind[1], hl.dsp.exec_cmd(bind[2]), { locked = true, repeating = bind[3] })
end

-------------------------------
---- WINDOWS AND WORKSPACES --
-------------------------------

hl.window_rule({
    name = "no-gaps-tiled-video-workspaces",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 3,
    rounding = 0,
})
hl.window_rule({
    name = "no-gaps-tiled-fullscreen-workspace",
    match = { float = false, workspace = "f[1]" },
    border_size = 3,
    rounding = 0,
})
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})
hl.window_rule({
    name = "fix-xwayland-drag-focus",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

--------------------------
---- CUSTOM OVERRIDES ----
--------------------------

-- These modules are intentionally loaded last so users can override defaults.
require("./custom/env")
require("./custom/variables")
require("./custom/general")
require("./custom/rules")
require("./custom/keybinds")
require("./custom/execs")
