#!/usr/bin/env bash

set -u

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

section() {
    printf '\n== %s ==\n' "$1"
}

show_command() {
    local name="$1" path
    if path=$(command -v "$name" 2>/dev/null); then
        printf '  %-24s %s\n' "$name" "$path"
    else
        printf '  %-24s missing\n' "$name"
    fi
}

show_path() {
    local label="$1" path="$2"
    if [[ -e "$path" ]]; then
        printf '  %-24s present (%s)\n' "$label" "$path"
    else
        printf '  %-24s missing (%s)\n' "$label" "$path"
    fi
}

list_entries() {
    local label="$1" directory="$2" pattern="$3" entry found=0
    printf '  %s:\n' "$label"
    if [[ -d "$directory" ]]; then
        while IFS= read -r entry; do
            [[ -f "$entry" ]] || continue
            printf '    %s\n' "${entry##*/}"
            found=1
        done < <(compgen -G "$directory/$pattern" || true)
    fi
    if (( ! found )); then
        printf '    none found\n'
    fi
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    printf 'Usage: hyprmono diagnostics\n\nRead-only snapshot of desktop configuration, tools, processes, and user services.\n'
    exit 0
fi

if (( $# > 0 )); then
    printf 'desktop-diagnostics: unexpected argument: %s\n' "$1" >&2
    exit 2
fi

section "Operating system"
if [[ -r /etc/os-release ]]; then
    awk -F= '/^(PRETTY_NAME|ID|VERSION_ID)=/ { print "  " $0 }' /etc/os-release
else
    printf '  /etc/os-release unavailable\n'
fi

section "Session environment"
printf '  XDG_SESSION_TYPE=%s\n' "${XDG_SESSION_TYPE:-<unset>}"
printf '  XDG_CURRENT_DESKTOP=%s\n' "${XDG_CURRENT_DESKTOP:-<unset>}"
printf '  XDG_SESSION_DESKTOP=%s\n' "${XDG_SESSION_DESKTOP:-<unset>}"
printf '  WAYLAND_DISPLAY=%s\n' "${WAYLAND_DISPLAY:-<unset>}"
printf '  DISPLAY=%s\n' "${DISPLAY:-<unset>}"

section "Desktop configuration"
show_path "Niri config" "$config_home/niri/config.kdl"
show_path "Caffyne start script" "$config_home/caffyne-shell/start.sh"
show_path "Caffyne main module" "$config_home/caffyne-shell/main.py"
show_path "Portal preferences" "$config_home/xdg-desktop-portal/niri-portals.conf"
show_path "User autostart directory" "$config_home/autostart"
show_path "User systemd directory" "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
list_entries "Autostart entries" "$config_home/autostart" '*.desktop'
list_entries "User service unit files" "$config_home/systemd/user" '*.service'

section "Relevant executables"
for name in \
    niri caffyne-shell fabric-cli swayidle swaylock fnott mako dunst \
    xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk \
    xdg-desktop-portal-wlr pipewire wireplumber wpctl \
    awww swww kanshi wlsunset grim slurp wl-copy wl-paste cliphist \
    fuzzel nm-applet nmcli bluetoothctl powerprofilesctl upower \
    brightnessctl playerctl
do
    show_command "$name"
done

section "Installed desktop-related packages"
package_pattern='(^|[-])(niri|caffyne|fabric|swayidle|swaylock|awww|swww|kanshi|wlsunset|grim|slurp|cliphist|wl-clipboard|fnott|mako|dunst|xdg-desktop-portal|pipewire|wireplumber|networkmanager|network-manager|bluez|polkit|brightnessctl|playerctl|power-profiles|fuzzel)'
if command -v pacman >/dev/null 2>&1; then
    if package_output=$(pacman -Q 2>&1); then
        matches=$(grep -Ei "$package_pattern" <<<"$package_output" || true)
        if [[ -n "$matches" ]]; then
            printf '%s\n' "$matches"
        else
            printf '  No matching packages reported by pacman.\n'
        fi
    else
        printf '  pacman query failed: %s\n' "$package_output"
    fi
elif command -v dpkg-query >/dev/null 2>&1; then
    if package_output=$(dpkg-query -W -f='${binary:Package}\t${Version}\n' 2>&1); then
        matches=$(grep -Ei "$package_pattern" <<<"$package_output" || true)
        if [[ -n "$matches" ]]; then
            printf '%s\n' "$matches"
        else
            printf '  No matching packages reported by dpkg-query.\n'
        fi
    else
        printf '  dpkg-query failed: %s\n' "$package_output"
    fi
elif command -v rpm >/dev/null 2>&1; then
    if package_output=$(rpm -qa --qf '%{NAME}\t%{VERSION}-%{RELEASE}\n' 2>&1); then
        matches=$(grep -Ei "$package_pattern" <<<"$package_output" || true)
        if [[ -n "$matches" ]]; then
            printf '%s\n' "$matches"
        else
            printf '  No matching packages reported by rpm.\n'
        fi
    else
        printf '  rpm query failed: %s\n' "$package_output"
    fi
else
    printf '  No supported package query tool found.\n'
fi

section "Matching processes (names only)"
if command -v ps >/dev/null 2>&1; then
    if process_snapshot=$(ps -eo comm=,args= 2>&1); then
        process_names=$(awk '
            {
                process = tolower($1)
                label = ""
                if (process ~ /^(niri|caffyne|fabric|fnott|mako|dunst|swayidle|swaylock|awww|swww|kanshi|wlsunset|cliphist|wl-paste|nm-applet|networkmanager|bluetoothd|power-profiles-daemon|pipewire(-.*)?|wireplumber|xdg-desktop-portal.*)$/) {
                    label = process
                } else if (process ~ /^python[0-9.]*$/ && tolower($0) ~ /(caffyne-shell|\/main\.py)/) {
                    label = "caffyne-runtime"
                }
                if (label != "") count[label]++
            }
            END {
                for (label in count) printf "  %3d %s\n", count[label], label
            }' <<<"$process_snapshot")
        if [[ -n "$process_names" ]]; then
            printf '%s\n' "$process_names" | sort -k2
        else
            printf '  No matching processes found.\n'
        fi
    else
        printf '  Process query failed: %s\n' "$process_snapshot"
    fi
else
    printf '  ps is unavailable.\n'
fi

section "User services"
if command -v systemctl >/dev/null 2>&1; then
    if service_output=$(systemctl --user list-units --type=service --all --no-pager --no-legend 2>&1); then
        matches=$(grep -Ei 'niri|caffyne|portal|pipewire|wireplumber|fnott|mako|dunst|swayidle|swaylock|awww|swww|kanshi|wlsunset|cliphist|networkmanager|bluetooth' <<<"$service_output" || true)
        if [[ -n "$matches" ]]; then
            printf '%s\n' "$matches"
        else
            printf '  No matching user services found.\n'
        fi
    else
        printf '  User service query failed: %s\n' "$service_output"
    fi
else
    printf '  systemctl is unavailable.\n'
fi

section "Notification bus owner"
if command -v busctl >/dev/null 2>&1; then
    if bus_output=$(busctl --user list --no-pager 2>&1); then
        notification_owner=$(awk '$1 == "org.freedesktop.Notifications" { print }' <<<"$bus_output")
        if [[ -n "$notification_owner" ]]; then
            printf '  %s\n' "$notification_owner"
        else
            printf '  No notification service owner reported.\n'
        fi
    else
        printf '  User bus query failed: %s\n' "$bus_output"
    fi
else
    printf '  busctl is unavailable.\n'
fi

section "Niri outputs"
if command -v niri >/dev/null 2>&1 && [[ -n "${NIRI_SOCKET:-}" ]]; then
    niri msg outputs 2>&1 || printf '  Unable to query outputs from the active Niri session.\n'
else
    printf '  No active Niri IPC socket detected.\n'
fi

printf '\nDiagnostics are read-only; command output may include local device and package names.\n'
