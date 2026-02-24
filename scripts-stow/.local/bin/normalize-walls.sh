#!/usr/bin/env bash
# normalize-walls.sh — downscale wallpapers exceeding 4K, skip everything else
set -euo pipefail

MAX_W=3840
MAX_H=2160
BASE="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"

count=0 skipped=0

while IFS= read -r -d '' img; do
    read -r w h < <(magick identify -format "%w %h" "$img" 2>/dev/null)
    if (( w > MAX_W || h > MAX_H )); then
        echo "Resizing: $(basename "$img") (${w}x${h})"
        magick "$img" -resize "${MAX_W}x${MAX_H}>" "$img"
        (( count++ ))
    else
        (( skipped++ ))
    fi
done < <(find "$BASE" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0)

echo "Done — resized: $count, skipped (already ≤4K): $skipped"
