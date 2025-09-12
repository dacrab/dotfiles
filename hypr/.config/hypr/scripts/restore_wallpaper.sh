#!/bin/bash

# Function to wait for hyprpaper to be ready
wait_for_hyprpaper() {
    local max_attempts=20
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if hyprctl hyprpaper listactive >/dev/null 2>&1; then
            echo "hyprpaper is ready" >&2
            return 0
        fi
        attempt=$((attempt + 1))
        echo "Waiting for hyprpaper... (attempt $attempt/$max_attempts)" >&2
        sleep 0.5
    done
    
    echo "Timeout waiting for hyprpaper" >&2
    return 1
}

# Wait for hyprpaper to be fully initialized
if ! wait_for_hyprpaper; then
    echo "hyprpaper not ready, exiting" >&2
    exit 1
fi

# File to store the last wallpaper
LAST_WP_FILE="$HOME/.config/hypr/configs/last_wallpaper"

# Check if last wallpaper file exists
if [ -f "$LAST_WP_FILE" ]; then
    LAST_WP=$(cat "$LAST_WP_FILE")
    echo "Restoring last wallpaper: $LAST_WP"
    
    # Check if the wallpaper file exists
    if [ -f "$LAST_WP" ]; then
        # Preload the last wallpaper
        hyprctl hyprpaper preload "$LAST_WP" >/dev/null 2>&1
        
        # Get the monitor name dynamically
        MONITOR=$(hyprctl monitors | grep "Monitor" | head -n1 | cut -d' ' -f2 | tr -d '"')
        
        # If we couldn't get a monitor name, use HDMI-A-1 as fallback
        if [ -z "$MONITOR" ]; then
            MONITOR="HDMI-A-1"
        fi
        
        # Set the wallpaper with multiple attempts
        attempts=0
        max_attempts=5
        while [ $attempts -lt $max_attempts ]; do
            if hyprctl hyprpaper wallpaper "$MONITOR,$LAST_WP" >/dev/null 2>&1; then
                echo "Wallpaper restored successfully"
                exit 0
            fi
            attempts=$((attempts + 1))
            echo "Attempt $attempts to set wallpaper failed, retrying..." >&2
            sleep 0.5
        done
        
        echo "Failed to set wallpaper after $max_attempts attempts" >&2
        exit 1
    else
        echo "Last wallpaper file does not exist, skipping"
    fi
else
    echo "No last wallpaper file found"
fi