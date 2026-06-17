#!/usr/bin/env bash
set -euo pipefail

BASE="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/random-wall"
mkdir -p "$STATE"

get_dir() {
  local arg="${1:-}"
  if [[ -n "$arg" ]]; then
    [[ -d "$arg" ]] && { echo "$arg"; return; }
    [[ -d "$BASE/$arg" ]] && { echo "$BASE/$arg"; return; }
    echo "no such dir: $arg" >&2; exit 1
  fi
  if [[ -t 0 ]]; then
    local folders=()
    while IFS= read -r -d '' d; do folders+=("$(basename "$d")"); done < <(find "$BASE" -mindepth 1 -maxdepth 1 -type d -not -name '.git' -print0 | sort -z)
    for i in "${!folders[@]}"; do printf "  %d) %s\n" $((i+1)) "${folders[$i]}"; done >&2
    echo "  0) All" >&2
    local choice
    while read -rp "Pick [0-${#folders[@]}]: " choice; do
      [[ "$choice" == "0" ]] && { echo "$BASE" > "$STATE/active_folder"; echo "$BASE"; return; }
      [[ "$choice" =~ ^[0-9]+$ && choice -ge 1 && choice -le ${#folders[@]} ]] && { local s="$BASE/${folders[$((choice-1))]}"; echo "$s" > "$STATE/active_folder"; echo "$s"; return; }
    done
  fi
  cat "$STATE/active_folder" 2>/dev/null || echo "$BASE/nord"
}

DIR=$(get_dir "${1:-}")
[[ ! -d "$DIR" ]] && echo "no wallpapers dir" >&2 && exit 1

mapfile -d '' ALL < <(find "$DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 | sort -z)
((${#ALL[@]} == 0)) && echo "no images in $DIR" >&2 && exit 1

LAST=$(cat "$STATE/last" 2>/dev/null || "")
POOL=()
for img in "${ALL[@]}"; do [[ "$img" != "$LAST" ]] && POOL+=("$img"); done
((${#POOL[@]} == 0)) && POOL=("${ALL[@]}")

PICK="${POOL[$((RANDOM % ${#POOL[@]}))]}"

set_wall() {
  local wallpaper="$1"

  if pgrep -x Hyprland &>/dev/null || [[ "${XDG_CURRENT_DESKTOP:-}" == *Hyprland* ]]; then
    hyprctl monitors | awk '/^Monitor/{gsub(/[":]/,"",$2); print $2}' | while read -r m; do
      hyprctl hyprpaper wallpaper "$m,$wallpaper,cover" 2>/dev/null || true
    done
    printf 'splash = false\n\nwallpaper {\n    monitor =\n    path = %s\n    fit_mode = cover\n}\n' "$wallpaper" > "$HOME/.config/hypr/hyprpaper.conf"
    return
  fi

  if pgrep -x niri &>/dev/null || [[ "${XDG_CURRENT_DESKTOP:-}" == *niri* ]]; then
    pkill swaybg 2>/dev/null || true
    swaybg -i "$wallpaper" -m fill &
    disown
    return
  fi

  local option
  option=$(gsettings get org.gnome.desktop.background picture-options)
  gsettings set org.gnome.desktop.background picture-uri "file://$wallpaper"
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$wallpaper"
  gsettings set org.gnome.desktop.background picture-options "scaled"
  gsettings set org.gnome.desktop.background picture-options "$option"
}

set_wall "$PICK"
printf '%s' "$PICK" > "$STATE/last"
