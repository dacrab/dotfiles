#!/bin/bash

# Persistent Toggle eDP-1 display on/off
# Saves state and makes changes persistent across restarts

STATE_FILE="$HOME/.cache/hypr_edp_state"
CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"

# Create cache directory if it doesn't exist
mkdir -p "$(dirname "$STATE_FILE")"

# Function to update config file
update_config() {
    local monitor_line="$1"
    
    # Create backup
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
    
    # Update the eDP-1 monitor line in config
    sed -i "s/^monitor = eDP-1,.*/monitor = eDP-1,$monitor_line/" "$CONFIG_FILE"
}

# Check current state
if hyprctl monitors | grep -q "Monitor eDP-1"; then
    # eDP is currently enabled, disable it
    echo "disabled" > "$STATE_FILE"
    hyprctl keyword monitor "eDP-1,disable"
    update_config "disable"
    echo "📺 eDP-1 display disabled"
else
    # eDP is currently disabled, enable it
    echo "enabled" > "$STATE_FILE"
    hyprctl keyword monitor "eDP-1,1920x1080@60,1920x0,1"
    update_config "1920x1080@60,1920x0,1"
    echo "📺 eDP-1 display enabled"
fi
