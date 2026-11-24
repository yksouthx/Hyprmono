#!/usr/bin/env bash

set -Eeuo pipefail

readonly DEFAULT_CONFIG_DIR="$HOME/.config"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$DEFAULT_CONFIG_DIR}"
readonly LOCAL_SHARE="$HOME/.local/share"
readonly LOCAL_BIN="${HOME}/.local/bin"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/Hyprmono/migration-backups"
readonly LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/Hyprmono"
CONFIG_ROOTS=("$DEFAULT_CONFIG_DIR")
SHARE_ROOTS=("$LOCAL_SHARE")
if [[ "$CONFIG_DIR" != "$DEFAULT_CONFIG_DIR" ]]; then
    CONFIG_ROOTS+=("$CONFIG_DIR")
fi
if [[ -n "${XDG_DATA_HOME:-}" && "$XDG_DATA_HOME" != "$LOCAL_SHARE" ]]; then
    SHARE_ROOTS+=("$XDG_DATA_HOME")
fi

DRY_RUN=0
ROLLBACK_DIR=""
ITEM_PATHS=()
ITEM_TYPES=()
ITEM_LABELS=()
PACKAGE_CANDIDATES=()
PROTECTED_PACKAGES=()

log() {
    local message="$*"
    printf '[migrate] %s\n' "$message"
    if (( ! DRY_RUN )); then
        mkdir -p "$LOG_DIR"
        printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >> "$LOG_DIR/migration.log"
    fi
}

usage() {
    cat <<'EOF'
Usage: migrate.sh [--dry-run] [--rollback BACKUP_DIR]

Scan for known duplicate desktop-shell components. Nothing is removed unless
the user approves each item. --dry-run only reports candidates.

Restore a migration backup with --rollback and its exact backup directory.
EOF
}

add_path_candidate() {
    local path="$1" label="$2" type="$3"
    case "$path" in
        "$HOME"/*) ;;
        *) return 0 ;;
    esac
    [[ -e "$path" || -L "$path" ]] || return 0
    ITEM_PATHS+=("$path")
    ITEM_LABELS+=("$label")
    ITEM_TYPES+=("$type")
}

scan_paths() {
    local name root
    for root in "${CONFIG_ROOTS[@]}"; do
        for name in waybar wofi rofi fuzzel hyprpanel; do
            add_path_candidate "$root/$name" \
                "$name configuration (a Quickshell launcher/bar can replace this)" config
        done
        for name in swaync dunst mako; do
            add_path_candidate "$root/$name" \
                "$name configuration (Quickshell provides the notification center)" config
        done
        for name in eww ags wlogout; do
            add_path_candidate "$root/$name" \
                "$name configuration (an existing desktop shell/widget layer)" config
        done
        add_path_candidate "$root/swaylock" \
            "swaylock configuration (Caelestia provides a lock screen; Hyprlock remains the fallback)" config
        add_path_candidate "$root/hypr/hyprpaper.conf" \
            "Hyprpaper config (Caelestia provides wallpaper management)" config
        add_path_candidate "$root/kde-material-you-colors" \
            "KDE Material You Colors config (Caelestia owns dynamic shell theming)" config
    done

    for root in "${SHARE_ROOTS[@]}"; do
        for name in waybar eww ags hyprpanel; do
            add_path_candidate "$root/$name" \
                "$name user data (an existing bar or desktop-shell component)" data
        done
    done

    for name in waybar wofi rofi fuzzel swaync dunst mako eww ags hyprpanel wlogout hyde hyde-shell.sh cpuinfo.sh gpuinfo.sh; do
        case "$name" in
            cpuinfo.sh|gpuinfo.sh)
                add_path_candidate "$LOCAL_BIN/$name" \
                    "$name helper (Caelestia's dashboard replaces the old bar metrics)" executable
                ;;
            *)
                add_path_candidate "$LOCAL_BIN/$name" \
                    "$name executable in ~/.local/bin (review before removing)" executable
                ;;
        esac
    done
}

scan_packages() {
    local pkg reverse
    local -a candidates=(waybar wofi rofi rofi-wayland fuzzel swaync swaynotificationcenter dunst mako eww aylurs-gtk-shell hyprpanel wlogout swaylock hyprpaper network-manager-applet kde-material-you-colors)

    command -v pacman >/dev/null 2>&1 || return 0
    for pkg in "${candidates[@]}"; do
        pacman -Qq "$pkg" >/dev/null 2>&1 || continue
        reverse=$(LC_ALL=C pacman -Qi "$pkg" 2>/dev/null |
            awk -F: '/^Required By[[:space:]]*:/ {sub(/^[[:space:]]+/, "", $2); print $2; exit}')
        if [[ -z "$reverse" || "$reverse" != "None" ]]; then
            PROTECTED_PACKAGES+=("$pkg (required by: ${reverse:-unknown; preserving})")
            continue
        fi
        PACKAGE_CANDIDATES+=("$pkg")
    done
}

package_reason() {
    case "$1" in
        waybar) printf '%s' "status bar replaced by the Quickshell shell" ;;
        wofi|rofi|rofi-wayland|fuzzel) printf '%s' "launcher alternative; Quickshell provides the default launcher" ;;
        swaync|swaynotificationcenter|dunst|mako) printf '%s' "notification daemon replaced by the Quickshell notification center" ;;
        eww|aylurs-gtk-shell|hyprpanel) printf '%s' "desktop-shell/widget alternative" ;;
        wlogout) printf '%s' "session menu alternative provided by the shell" ;;
        swaylock) printf '%s' "lock screen alternative; Caelestia provides the lock screen and Hyprlock is the fallback" ;;
        hyprpaper) printf '%s' "wallpaper daemon replaced by Caelestia's wallpaper manager" ;;
        network-manager-applet) printf '%s' "tray app replaced by Caelestia's network controls" ;;
        kde-material-you-colors) printf '%s' "theme daemon replaced by Caelestia's dynamic theming" ;;
        *) printf '%s' "known optional desktop-shell component" ;;
    esac
}

show_candidates() {
    local i type pkg
    local -a types=(config data executable)
    printf '\nKnown duplicate component files:\n'
    if (( ${#ITEM_PATHS[@]} == 0 )); then
        printf '  (none found)\n'
    else
        for type in "${types[@]}"; do
            case "$type" in
                config) printf '  Configurations:\n' ;;
                data) printf '  User data:\n' ;;
                executable) printf '  Local executables:\n' ;;
            esac
            for i in "${!ITEM_PATHS[@]}"; do
                [[ "${ITEM_TYPES[$i]}" == "$type" ]] || continue
                printf '    %s — %s\n' "${ITEM_PATHS[$i]}" "${ITEM_LABELS[$i]}"
            done
        done
    fi

    printf '\nInstalled package candidates (reverse-dependency-free):\n'
    if (( ${#PACKAGE_CANDIDATES[@]} == 0 )); then
        printf '  (none found)\n'
    else
        for pkg in "${PACKAGE_CANDIDATES[@]}"; do
            printf '  %s — %s\n' "$pkg" "$(package_reason "$pkg")"
        done
    fi

    if (( ${#PROTECTED_PACKAGES[@]} > 0 )); then
        printf '\nPackages preserved because they are shared or dependency data was unavailable:\n'
        printf '  %s\n' "${PROTECTED_PACKAGES[@]}"
    fi
}

ask_remove() {
    local prompt="$1" reply
    [[ -t 0 ]] || {
        log "No interactive terminal; keeping candidate: $prompt"
        return 1
    }
    printf '\nRemove %s? [y/N] ' "$prompt"
    IFS= read -r reply || return 1
    [[ "$reply" =~ ^[Yy]$ ]]
}

new_backup_dir() {
    local stamp candidate
    stamp=$(date '+%Y%m%d-%H%M%S')
    candidate="$STATE_DIR/$stamp"
    if [[ -e "$candidate" ]]; then
        candidate="$STATE_DIR/${stamp}-$$"
    fi
    mkdir -p "$candidate/items"
    : > "$candidate/manifest"
    printf '%s\n' "$candidate"
}

append_manifest() {
    printf '%s\0%s\0%s\0' "$1" "$2" "$3" >> "$BACKUP_DIR/manifest"
}

BACKUP_DIR=""
ensure_backup() {
    [[ -n "$BACKUP_DIR" ]] && return 0
    BACKUP_DIR=$(new_backup_dir)
    log "Created migration backup: $BACKUP_DIR"
}

remove_path() {
    local index="$1" path="${ITEM_PATHS[$1]}" backup_rel="items/$1"
    ensure_backup
    cp -a -- "$path" "$BACKUP_DIR/$backup_rel"
    append_manifest "${ITEM_TYPES[$index]}" "$path" "$backup_rel"
    if [[ -L "$path" || ! -d "$path" ]]; then
        rm -f -- "$path"
    else
        rm -rf -- "$path"
    fi
    log "Backed up and removed ${ITEM_TYPES[$index]}: $path"
}

process_candidates() {
    local i pkg
    for i in "${!ITEM_PATHS[@]}"; do
        if ask_remove "${ITEM_PATHS[$i]} — ${ITEM_LABELS[$i]}"; then
            remove_path "$i"
        else
            log "Kept ${ITEM_PATHS[$i]}"
        fi
    done

    for pkg in "${PACKAGE_CANDIDATES[@]}"; do
        if ! ask_remove "package $pkg (the package manager will show its transaction)"; then
            log "Kept package $pkg"
            continue
        fi
        ensure_backup
        if ! sudo pacman -R "$pkg"; then
            log "Package removal failed; kept package $pkg"
            continue
        fi
        append_manifest package "$pkg" -
        log "Removed package: $pkg"
    done

    if [[ -n "$BACKUP_DIR" && -s "$BACKUP_DIR/manifest" ]]; then
        log "Rollback is available with: $0 --rollback '$BACKUP_DIR'"
    else
        log "No items were removed."
    fi
}

rollback() {
    local resolved item_type original backup_rel i
    local -a records=() packages=()
    resolved=$(realpath -e -- "$ROLLBACK_DIR") || {
        printf 'Backup directory does not exist: %s\n' "$ROLLBACK_DIR" >&2
        exit 1
    }
    case "$resolved/" in
        "$(realpath -m -- "$STATE_DIR")/"*) ;;
        *)
            printf 'Refusing backup outside %s\n' "$STATE_DIR" >&2
            exit 1
            ;;
    esac
    [[ -f "$resolved/manifest" ]] || {
        printf 'Backup manifest is missing: %s\n' "$resolved" >&2
        exit 1
    }
    mapfile -d '' -t records < "$resolved/manifest"
    (( ${#records[@]} % 3 == 0 )) || {
        printf 'Backup manifest is incomplete; refusing rollback.\n' >&2
        exit 1
    }

    for ((i = 0; i < ${#records[@]}; i += 3)); do
        item_type=${records[$i]}
        original=${records[$((i + 1))]}
        backup_rel=${records[$((i + 2))]}
        if [[ "$item_type" == package ]]; then
            [[ "$original" =~ ^[a-zA-Z0-9@._+-]+$ && "$backup_rel" == - ]] || {
                printf 'Invalid package entry in backup manifest; refusing rollback.\n' >&2
                exit 1
            }
            continue
        fi
        [[ "$item_type" == config || "$item_type" == data || "$item_type" == executable ]] || {
            printf 'Invalid file category in backup manifest; refusing rollback.\n' >&2
            exit 1
        }
        case "$original" in
            "$HOME"/*) ;;
            *)
                printf 'Backup manifest path is outside the home directory; refusing rollback.\n' >&2
                exit 1
                ;;
        esac
        [[ "$backup_rel" =~ ^items/[0-9]+$ && ( -e "$resolved/$backup_rel" || -L "$resolved/$backup_rel" ) ]] || {
            printf 'Invalid or missing backup entry; refusing rollback.\n' >&2
            exit 1
        }
    done

    if (( DRY_RUN )); then
        for ((i = 0; i < ${#records[@]}; i += 3)); do
            item_type=${records[$i]}
            original=${records[$((i + 1))]}
            if [[ "$item_type" == package ]]; then
                printf 'Dry run: would offer to reinstall package %s.\n' "$original"
            elif [[ -e "$original" || -L "$original" ]]; then
                printf 'Dry run: would skip existing path %s.\n' "$original"
            else
                printf 'Dry run: would restore %s.\n' "$original"
            fi
        done
        printf 'Dry run: no files or packages were changed.\n'
        return
    fi

    for ((i = 0; i < ${#records[@]}; i += 3)); do
        item_type=${records[$i]}
        original=${records[$((i + 1))]}
        backup_rel=${records[$((i + 2))]}
        if [[ "$item_type" == package ]]; then
            packages+=("$original")
            continue
        fi
        if [[ -e "$original" || -L "$original" ]]; then
            log "Skipped restore because the path now exists: $original"
            continue
        fi
        mkdir -p -- "$(dirname "$original")"
        cp -a -- "$resolved/$backup_rel" "$original"
        log "Restored $item_type: $original"
    done

    if (( ${#packages[@]} > 0 )); then
        command -v pacman >/dev/null 2>&1 || {
            printf 'pacman is required to restore removed packages.\n' >&2
            exit 1
        }
        if [[ -t 0 ]]; then
            printf 'Reinstall removed packages: %s? [y/N] ' "${packages[*]}"
            local reply
            IFS= read -r reply || reply=""
            if [[ "$reply" =~ ^[Yy]$ ]]; then
                sudo pacman -S --needed "${packages[@]}"
                log "Reinstalled packages: ${packages[*]}"
            else
                log "Package restoration declined: ${packages[*]}"
            fi
        else
            log "Package restoration requires an interactive terminal; files were restored."
        fi
    fi
    log "Rollback complete for $resolved"
}

main() {
    while (( $# > 0 )); do
        case "$1" in
            --dry-run) DRY_RUN=1; shift ;;
            --rollback)
                [[ $# -ge 2 && -n "$2" ]] || { usage >&2; exit 2; }
                ROLLBACK_DIR="$2"
                shift 2
                ;;
            --help|-h) usage; return 0 ;;
            *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
        esac
    done

    if [[ -n "$ROLLBACK_DIR" ]]; then
        rollback
        return
    fi

    scan_paths
    scan_packages
    show_candidates

    if (( DRY_RUN )); then
        printf '\nDry run: no files or packages were changed.\n'
        return
    fi
    if (( ${#ITEM_PATHS[@]} == 0 && ${#PACKAGE_CANDIDATES[@]} == 0 )); then
        log "No recognized duplicate components found."
        return
    fi
    process_candidates
}

main "$@"
