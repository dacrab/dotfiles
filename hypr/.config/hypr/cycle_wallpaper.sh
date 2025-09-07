#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/Pictures/wallpapers/nord-background"

# File to store the last wallpaper
LAST_WP_FILE="$HOME/.config/hypr/last_wallpaper"

# Get list of image files
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.webp" \) | sort)

# Debug output
echo "Found ${#WALLPAPERS[@]} wallpapers" >&2

# Check if we found any wallpapers
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR" >&2
    exit 1
fi

# Get current wallpaper from hyprpaper
CURRENT_WP=$(hyprctl hyprpaper listactive 2>/dev/null | grep -o '/home.*' | head -n1)

# Debug output
echo "Current wallpaper: $CURRENT_WP" >&2

# If we couldn't get current wallpaper, try to load from saved file
if [ -z "$CURRENT_WP" ]; then
    if [ -f "$LAST_WP_FILE" ]; then
        CURRENT_WP=$(cat "$LAST_WP_FILE")
        echo "Loaded last wallpaper from file: $CURRENT_WP" >&2
    else
        CURRENT_WP="${WALLPAPERS[0]}"
        echo "Defaulting to first wallpaper: $CURRENT_WP" >&2
    fi
fi

# Find current wallpaper index
CURRENT_INDEX=-1
for i in "${!WALLPAPERS[@]}"; do
    if [ "${WALLPAPERS[i]}" = "$CURRENT_WP" ]; then
        CURRENT_INDEX=$i
        echo "Found current wallpaper at index: $CURRENT_INDEX" >&2
        break
    fi
done

# If not found, use first wallpaper
if [ $CURRENT_INDEX -eq -1 ]; then
    CURRENT_INDEX=0
    echo "Current wallpaper not in list, using first: ${WALLPAPERS[0]}" >&2
fi

# Calculate next wallpaper index with proper error handling
if [ ${#WALLPAPERS[@]} -gt 0 ]; then
    NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#WALLPAPERS[@]} ))
else
    echo "Error: No wallpapers available" >&2
    exit 1
fi

echo "Next index: $NEXT_INDEX" >&2

# Get next wallpaper path
NEXT_WP="${WALLPAPERS[$NEXT_INDEX]}"
echo "Next wallpaper: $NEXT_WP" >&2

# Save the next wallpaper to the last wallpaper file
echo "$NEXT_WP" > "$LAST_WP_FILE"

# Ensure the file was written successfully
if [ ! -f "$LAST_WP_FILE" ] || [ "$(cat "$LAST_WP_FILE")" != "$NEXT_WP" ]; then
    echo "Warning: Failed to save last wallpaper to $LAST_WP_FILE" >&2
fi

# Get the monitor name dynamically
MONITOR=$(hyprctl monitors | grep "Monitor" | head -n1 | cut -d' ' -f2 | tr -d '"')

# If we couldn't get a monitor name, use HDMI-A-1 as fallback
if [ -z "$MONITOR" ]; then
    MONITOR="HDMI-A-1"
fi

# Preload next wallpaper if not already loaded
echo "Preloading: $NEXT_WP" >&2
hyprctl hyprpaper preload "$NEXT_WP" >/dev/null 2>&1

# Set the wallpaper
echo "Setting wallpaper: $MONITOR,$NEXT_WP" >&2
hyprctl hyprpaper wallpaper "$MONITOR,$NEXT_WP" >/dev/null 2>&1

# Clean up unused wallpapers (optional)
# hyprctl hyprpaper unload all >/dev/null 2>&1