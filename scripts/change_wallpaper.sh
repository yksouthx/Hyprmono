#!/usr/bin/env bash
# change_wallpaper.sh
# Cycles through wallpapers in ~/.config/awww/wallpapers using awww.

WALLPAPER_DIR="$HOME/.config/awww/wallpapers"

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "Error: Wallpaper directory not found at $WALLPAPER_DIR"
    exit 1
fi

# Get a random wallpaper from the directory
RANDOM_WALL=$(find "$WALLPAPER_DIR" -type l -o -type f | shuf -n 1)

if [[ -z "$RANDOM_WALL" ]]; then
    echo "Error: No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Apply the wallpaper using awww
# awww uses 'awww img' just like swww did
"$HOME/.config/Vyle/scripts/swwwallswitch.sh" -i "$RANDOM_WALL"

# Support for Wallbash - triggers a theme update based on the new wallpaper
if command -v swwwallbash.sh &> /dev/null; then
    
fi
