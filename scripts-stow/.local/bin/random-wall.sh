#!/usr/bin/env bash
# random-wall.sh — pick a random wallpaper
# Usage: no args = interactive picker (saves choice); arg = folder name or path
set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
DEFAULT_FOLDER="nord"
BASE="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/random-wall"

mkdir -p "$STATE"

# ── Resolve wallpaper directory ───────────────────────────────────────────────
get_dir() {
  local arg="${1:-}"

  # If an argument was given, resolve it as a path or subfolder name
  if [[ -n "$arg" ]]; then
    if [[ -d "$arg" ]]; then
      echo "$arg"
      return
    elif [[ -d "$BASE/$arg" ]]; then
      echo "$BASE/$arg"
      return
    else
      echo "Error: '$arg' not found as a path or subfolder of $BASE" >&2
      exit 1
    fi
  fi

  # Interactive mode: show folder menu when stdin is a terminal
  if [[ -t 0 ]]; then
    local -a folders=()
    while IFS= read -r -d '' dir; do
      folders+=("$(basename "$dir")")
    done < <(find "$BASE" -mindepth 1 -maxdepth 1 -type d -not -name '.git' -print0 | sort -z)

    local i=1
    for folder in "${folders[@]}"; do
      printf "  %d) %s\n" "$i" "$folder" >&2
      ((i++))
    done
    printf "  0) All\n\n" >&2

    local choice
    while true; do
      read -rp "Choose [0-${#folders[@]}]: " choice

      if [[ "$choice" == "0" ]]; then
        printf '%s' "$BASE" > "$STATE/active_folder"
        echo "$BASE"
        return
      fi

      if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#folders[@]})); then
        local selected="$BASE/${folders[$((choice - 1))]}"
        printf '%s' "$selected" > "$STATE/active_folder"
        echo "$selected"
        return
      fi

      echo "Invalid choice, try again." >&2
    done
  fi

  # Non-interactive: restore last chosen folder or fall back to default
  if [[ -f "$STATE/active_folder" ]]; then
    echo "$(<"$STATE/active_folder")"
  else
    echo "$BASE/$DEFAULT_FOLDER"
  fi
}

# ── Apply wallpaper ───────────────────────────────────────────────────────────
set_wall() {
  local wallpaper="$1"

  # Hyprland + hyprpaper
  if pgrep -x Hyprland >/dev/null 2>&1 || [[ "${XDG_CURRENT_DESKTOP:-}" == *Hyprland* ]]; then
    local m
    while IFS= read -r m; do
      hyprctl hyprpaper wallpaper "$m,$wallpaper,cover" 2>/dev/null || true
    done < <(hyprctl monitors | awk '/^Monitor /{gsub(/[":]/,"", $2); print $2}')
    # Persist for next boot
    local conf="$HOME/.config/hypr/hyprpaper.conf"
    printf 'splash = false\n\nwallpaper {\n    monitor =\n    path = %s\n    fit_mode = cover\n}\n' "$wallpaper" > "$conf"
    return
  fi

  # Niri + swaybg
  if pgrep -x niri >/dev/null 2>&1 || [[ "${XDG_CURRENT_DESKTOP:-}" == *niri* ]]; then
    pkill swaybg 2>/dev/null || true
    swaybg -i "$wallpaper" -m fill &
    disown
    return
  fi

  # GNOME
  local current_option
  current_option=$(gsettings get org.gnome.desktop.background picture-options)
  
  gsettings set org.gnome.desktop.background picture-uri      "file://$wallpaper"
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$wallpaper"
  gsettings set org.gnome.desktop.background picture-options "scaled"
  gsettings set org.gnome.desktop.background picture-options "$current_option"
}

# ── Main ──────────────────────────────────────────────────────────────────────
DIR=$(get_dir "${1:-}")

# Collect all supported image files
mapfile -d '' ALL < <(
  find "$DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
       -o -iname '*.webp' -o -iname '*.bmp' \) \
    -print0 | sort -z
)

if [[ ${#ALL[@]} -eq 0 ]]; then
  echo "No images found in: $DIR" >&2
  exit 1
fi

# Avoid repeating the last wallpaper if possible
LAST=""
[[ -f "$STATE/last" ]] && LAST=$(<"$STATE/last")

POOL=()
for img in "${ALL[@]}"; do
  [[ "$img" != "$LAST" ]] && POOL+=("$img")
done

# If all images were filtered (only one image exists), allow repeat
[[ ${#POOL[@]} -eq 0 ]] && POOL=("${ALL[@]}")

PICK="${POOL[$(( RANDOM % ${#POOL[@]} ))]}"

set_wall "$PICK"
printf '%s' "$PICK" > "$STATE/last"
