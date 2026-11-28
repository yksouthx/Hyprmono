#!/usr/bin/env bash
# Start the small session helpers that neither Niri nor Caffyne Shell provide:
#   - a polkit authentication agent, so GUI privilege prompts work
#   - fnott, the notification daemon (project shell only)
# - nm-applet, whose menu is shown from the bar's system tray
set -u

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

start_once() {
    local name="$1"
    shift
    pgrep -x "$name" >/dev/null 2>&1 && return 0
    "$@" >/dev/null 2>&1 &
    disown "$!" 2>/dev/null || true
}

# True when some process already owns the freedesktop notification service.
notifications_owned() {
    command -v busctl >/dev/null 2>&1 || return 1
    busctl --user list --no-pager 2>/dev/null | awk '{print $1}' | grep -qx 'org.freedesktop.Notifications'
}

for candidate in \
    /usr/lib/polkit-kde-authentication-agent-1 \
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
    /usr/lib/mate-polkit/polkit-mate-authentication-agent-1; do
    if [[ -x "$candidate" ]]; then
        start_once "$(basename "$candidate")" "$candidate"
        break
    fi
done

if [[ -x "$config_home/caffyne-shell/start.sh" ]]; then
    if command -v fnott >/dev/null 2>&1 && ! notifications_owned; then
        start_once fnott fnott
    fi
    if command -v nm-applet >/dev/null 2>&1; then
        start_once nm-applet nm-applet --indicator
    fi
fi

exit 0
