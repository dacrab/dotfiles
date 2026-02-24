#!/usr/bin/env bash
# random-wall.sh — pick a random wallpaper
# Usage: no args = interactive picker (saves choice); arg = folder name or path
DEFAULT_FOLDER="nord"

set -euo pipefail

BASE="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/random-wall"
mkdir -p "$STATE"

get_dir() {
    local arg="${1:-}"

    if [[ -n "$arg" ]]; then
        [[ -d "$arg" ]] && { echo "$arg"; return; }
        [[ -d "$BASE/$arg" ]] && { echo "$BASE/$arg"; return; }
        echo "Error: '$arg' not found." >&2; exit 1
    fi

    if [[ -t 0 ]]; then
        local -a folders=()
        while IFS= read -r -d '' d; do
            folders+=("$(basename "$d")")
        done < <(find "$BASE" -mindepth 1 -maxdepth 1 -type d -not -name '.git' -print0 | sort -z)

        local i=1
        for f in "${folders[@]}"; do printf "  %d) %s\n" "$i" "$f" >&2; ((i++)); done
        printf "  0) All\n\n" >&2

        local choice
        while true; do
            read -rp "Choose [0-${#folders[@]}]: " choice
            [[ "$choice" == "0" ]] && { printf '%s' "$BASE" > "$STATE/active_folder"; echo "$BASE"; return; }
            [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#folders[@]} )) && {
                printf '%s' "$BASE/${folders[$((choice-1))]}" > "$STATE/active_folder"
                echo "$BASE/${folders[$((choice-1))]}"; return
            }
            echo "Invalid." >&2
        done
    fi

    [[ -f "$STATE/active_folder" ]] && echo "$(<"$STATE/active_folder")" || echo "$BASE/$DEFAULT_FOLDER"
}

set_wall() {
    if pgrep -x niri >/dev/null 2>&1 || [[ "${XDG_CURRENT_DESKTOP:-}" == *niri* ]]; then
        pkill swaybg 2>/dev/null || true; swaybg -i "$1" -m fill & disown; return
    fi
    gsettings set org.gnome.desktop.background picture-uri      "file://$1"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$1"
}

DIR=$(get_dir "${1:-}")

mapfile -d '' ALL < <(find "$DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) \
    -print0 | sort -z)

[[ ${#ALL[@]} -eq 0 ]] && { echo "No images in: $DIR" >&2; exit 1; }

LAST=""; [[ -f "$STATE/last" ]] && LAST=$(<"$STATE/last")

POOL=()
for img in "${ALL[@]}"; do [[ "$img" != "$LAST" ]] && POOL+=("$img"); done
[[ ${#POOL[@]} -eq 0 ]] && POOL=("${ALL[@]}")

PICK="${POOL[$(( RANDOM % ${#POOL[@]} ))]}"
set_wall "$PICK"
printf '%s' "$PICK" > "$STATE/last"
