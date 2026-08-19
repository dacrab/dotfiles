#!/usr/bin/env bash
# random-wall - set a random wallpaper via hyprpaper IPC.
#   random-wall          pick from the default folder
#   random-wall <dir>    pick from <dir> (path or name under $WALLPAPER_DIR)
set -uo pipefail

BASE="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
WALL_EXT="${WALL_EXT:-jpg jpeg png webp}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/random-wall"
mkdir -p "$STATE"

DIR="${1:-$BASE/nord}"
[[ -d "$DIR" ]] || DIR="$BASE/${1:-nord}"
[[ -d "$DIR" ]] || { echo "no wallpapers dir: $DIR" >&2; exit 1; }

read -ra exts <<< "${WALL_EXT}"
exp=()
for ext in "${exts[@]}"; do
  ((${#exp[@]})) && exp+=(-o)
  exp+=(-iname "*.$ext")
done
mapfile -d '' ALL < <(find "$DIR" -type f \( "${exp[@]}" \) -print0)
((${#ALL[@]} == 0)) && { echo "no images in $DIR" >&2; exit 1; }

LAST=$(cat "$STATE/last" 2>/dev/null || true)
POOL=()
for img in "${ALL[@]}"; do [[ "$img" != "$LAST" ]] && POOL+=("$img"); done
((${#POOL[@]} == 0)) && POOL=("${ALL[@]}")

PICK="${POOL[$((RANDOM % ${#POOL[@]}))]}"

# wait for the hyprpaper socket, then set via IPC
runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
for _ in {1..50}; do
  sock=$(find "$runtime/hypr" -maxdepth 2 -name .hyprpaper.sock -print -quit 2>/dev/null)
  [[ -n "$sock" ]] && break
  sleep 0.1
done

mapfile -t mons < <(hyprctl monitors | awk '/^Monitor /{print $2}')
for mon in "${mons[@]}"; do
  hyprctl hyprpaper wallpaper "$mon,$PICK"
done
printf '%s' "$PICK" > "$STATE/last"