#!/usr/bin/env bash

# ==============================================================================
#  Random Wallpaper Utility
#  Supports: GNOME (gsettings)
#  Usage: random-wall.sh [OPTIONAL_DIR]
# ==============================================================================

set -euo pipefail

# --- Configuration ---
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/random-wall"
LAST_FILE="$STATE_DIR/last_wallpaper"
mkdir -p "$STATE_DIR"

# --- Functions ---

get_wallpaper_dir() {
    local target="${1:-}"

    # 1. Use argument if provided
    if [[ -n "$target" && -d "$target" ]]; then
        echo "$target"
        return
    fi

    # 2. Use env var if set
    if [[ -n "${WALLPAPER_DIR:-}" && -d "$WALLPAPER_DIR" ]]; then
        echo "$WALLPAPER_DIR"
        return
    fi

    # 3. Smart Defaults
    local xdg_pics
    xdg_pics=$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")
    
    if [[ -d "$xdg_pics/Wallpapers" ]]; then
        echo "$xdg_pics/Wallpapers"
    elif [[ -d "$xdg_pics/wallpapers" ]]; then
        echo "$xdg_pics/wallpapers"
    else
        echo "$xdg_pics"
    fi
}

set_wallpaper() {
    local img="$1"
    local desktop="${XDG_CURRENT_DESKTOP:-}"

    echo "Setting wallpaper: $img"

    # GNOME / Unity / Pantheon
    if [[ "$desktop" == *"GNOME"* ]] || command -v gsettings >/dev/null 2>&1; then
        # Set for both light and dark modes
        gsettings set org.gnome.desktop.background picture-uri "file://$img"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$img"
        return 0
    fi

    echo "Error: No supported wallpaper backend detected for desktop '$desktop'." >&2
    return 1
}

# --- Main ---

TARGET_DIR=$(get_wallpaper_dir "${1:-}")

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory '$TARGET_DIR' does not exist." >&2
    exit 1
fi

# Find images (jpg, jpeg, png, webp, bmp)
# Using null delimiter for safe filename handling
# shellcheck disable=SC2034 # CANDIDATES is used in the loop/selection
mapfile -d '' CANDIDATES < <(find "$TARGET_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) -print0 | sort -z)

count=${#CANDIDATES[@]}

if [[ "$count" -eq 0 ]]; then
    echo "No images found in: $TARGET_DIR" >&2
    exit 1
fi

# Select Random
if [[ "$count" -eq 1 ]]; then
    SELECTED="${CANDIDATES[0]}"
else
    # Avoid repeating the last one
    if [[ -f "$LAST_FILE" ]]; then
        LAST_USED=$(<"$LAST_FILE")
    else
        LAST_USED=""
    fi

    # Max retries to find a new one
    for _ in {1..5}; do
        idx=$(( RANDOM % count ))
        SELECTED="${CANDIDATES[$idx]}"
        [[ "$SELECTED" != "$LAST_USED" ]] && break
    done
fi

set_wallpaper "$SELECTED"
printf '%s' "$SELECTED" > "$LAST_FILE"
