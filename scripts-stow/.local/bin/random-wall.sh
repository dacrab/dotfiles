#!/usr/bin/env bash
# ============================================
# random-wall — set a random wallpaper.
#   random-wall          pick from active folder
#   random-wall <dir>    pick from <dir> (path or name under $WALLPAPER_DIR)
# Works with Hyprland (hyprpaper), Niri (swaybg), and GNOME.
# ============================================
set -uo pipefail

BASE="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/random-wall"
mkdir -p "$STATE"

get_dir() {
  local arg="${1:-}"
  if [[ -n "$arg" ]]; then
    [[ -d "$arg" ]] && { echo "$arg"; return; }
    [[ -d "$BASE/$arg" ]] && { echo "$BASE/$arg"; return; }
    exit 1
  fi
  cat "$STATE/active_folder" 2>/dev/null || echo "$BASE/nord"
}

DIR=$(get_dir "${1:-}")
[[ ! -d "$DIR" ]] && echo "no wallpapers dir" >&2 && exit 1

# ----- Pick a random image, avoiding the last one -----
mapfile -d '' ALL < <(find "$DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 | sort -z)
((${#ALL[@]} == 0)) && echo "no images in $DIR" >&2 && exit 1

LAST=$(cat "$STATE/last" 2>/dev/null || true)
POOL=()
for img in "${ALL[@]}"; do [[ "$img" != "$LAST" ]] && POOL+=("$img"); done
((${#POOL[@]} == 0)) && POOL=("${ALL[@]}")

PICK="${POOL[$((RANDOM % ${#POOL[@]}))]}"

# ----- Apply the wallpaper per compositor -----
set_wall() {
  local wallpaper="$1"

  # Hyprland (via hyprpaper IPC)
  if pgrep -x Hyprland || [[ "${XDG_CURRENT_DESKTOP:-}" == *Hyprland* ]]; then
    for _ in {1..10}; do
      hyprctl hyprpaper list >/dev/null 2>&1 && break
      sleep 0.3
    done
    hyprctl hyprpaper preload "$wallpaper"
    hyprctl monitors | awk '/^Monitor/{gsub(/[":]/,"",$2); print $2}' | while read -r m; do
      hyprctl hyprpaper wallpaper "$m,$wallpaper"
    done
    hyprctl hyprpaper unload unused
    return
  fi

  # Niri (via swaybg)
  if pgrep -x niri || [[ "${XDG_CURRENT_DESKTOP:-}" == *niri* ]]; then
    pkill swaybg || true
    swaybg -i "$wallpaper" -m fill &
    disown
    return
  fi

  # GNOME fallback (gsettings)
  local option
  option=$(gsettings get org.gnome.desktop.background picture-options)
  gsettings set org.gnome.desktop.background picture-uri "file://$wallpaper"
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$wallpaper"
  gsettings set org.gnome.desktop.background picture-options "scaled"
  gsettings set org.gnome.desktop.background picture-options "$option"
}

set_wall "$PICK"
printf '%s' "$PICK" > "$STATE/last"
