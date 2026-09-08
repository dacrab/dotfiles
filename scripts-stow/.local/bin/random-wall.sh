#!/usr/bin/env bash
# random-wall - set a random wallpaper (different one each login).
#   random-wall          pick from the default folder
#   random-wall <dir>    pick from <dir> (path or name under $WALLPAPER_DIR)
#   random-wall --autostart  login mode: skips when another session (e.g.
#                          Hyprland's hyprland.lua) already runs this script
# Works on Hyprland (hyprpaper), GNOME (gsettings), Sway/wlroots (swaybg),
# XFCE (xfconf-query), and MATE/Cinnamon (gsettings via dconf).
# Autostarted by ~/.config/autostart/random-wall.desktop on GNOME & others.
set -uo pipefail

AUTO=0
if [[ "${1:-}" == --autostart ]]; then
  AUTO=1
  shift
fi

# --autostart mode: exit quietly if Hyprland is up (it autostarts this
# script itself, and double-running would race hyprpaper IPC)
if [[ "$AUTO" == 1 ]] && pgrep -x Hyprland &>/dev/null; then
  exit 0
fi

BASE="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
WALL_EXT="${WALL_EXT:-jpg jpeg png webp}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/random-wall"
mkdir -p "$STATE"

DIR="${1:-$BASE/nord}"
[[ -d "$DIR" ]] || DIR="$BASE/${1:-nord}"
[[ -d "$DIR" ]] || {
  echo "no wallpapers dir: $DIR" >&2
  exit 1
}

read -ra exts <<<"${WALL_EXT}"
exp=()
for ext in "${exts[@]}"; do
  ((${#exp[@]})) && exp+=(-o)
  exp+=(-iname "*.$ext")
done
mapfile -d '' ALL < <(find "$DIR" -type f \( "${exp[@]}" \) -print0)
((${#ALL[@]} == 0)) && {
  echo "no images in $DIR" >&2
  exit 1
}

# pick a different wallpaper than last time (when possible)
LAST=$(cat "$STATE/last" 2>/dev/null || true)
POOL=()
for img in "${ALL[@]}"; do [[ "$img" != "$LAST" ]] && POOL+=("$img"); done
((${#POOL[@]} == 0)) && POOL=("${ALL[@]}")

PICK="${POOL[$((RANDOM % ${#POOL[@]}))]}"

# ---- Hyprland (hyprpaper IPC) --------------------------------------------
set_hyprland() {
  local runtime sock mon
  runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  for _ in {1..50}; do
    sock=$(find "$runtime/hypr" -maxdepth 2 -name .hyprpaper.sock -print -quit 2>/dev/null)
    [[ -n "$sock" ]] && break
    sleep 0.1
  done
  while read -r mon; do
    hyprctl hyprpaper wallpaper "$mon,$1"
  done < <(hyprctl monitors | awk '/^Monitor /{print $2}')
}

# ---- GNOME / Cinnamon (gsettings/dconf) -----------------------------------
# usage: set_gsettings <schema>.background <image>
set_gsettings() {
  local schema=$1 img=$2 option
  option=$(gsettings get "$schema" picture-options 2>/dev/null)
  gsettings set "$schema" picture-uri "file://$img"
  gsettings set "$schema" picture-uri-dark "file://$img"
  gsettings set "$schema" picture-options "scaled"
  [[ -n "$option" && "$option" != "scaled" ]] &&
    gsettings set "$schema" picture-options "$option"
}

# ---- MATE (plain paths, no file:// URIs) ----------------------------------
set_mate() {
  gsettings set org.mate.background picture-filename "$1"
}

# ---- XFCE ---------------------------------------------------------------
set_xfce() {
  local screens rprops=()
  screens=$(xfconf-query -c xfce4-desktop -p /backdrop/screens -l 2>/dev/null)
  while read -r scr; do
    rprops+=("$(xfconf-query -c xfce4-desktop -p "$scr" -l 2>/dev/null | grep last-image | head -1)")
  done <<<"$screens"
  for p in "${rprops[@]}"; do
    [[ -n "$p" ]] && xfconf-query -c xfce4-desktop -p "$p" -s "$1"
  done
  # keep the preview in sync
  xfconf-query -c xfce4-desktop -p /backdrop/single-image -s "$1" &>/dev/null
}

# ---- Sway / other wlroots compositors (swaybg) ---------------------------
set_swaybg() {
  pkill -x swaybg &>/dev/null
  sleep 0.2
  nohup swaybg -m fill -i "$1" &>/dev/null &
}

detect_desktop() {
  case "${XDG_CURRENT_DESKTOP:-}" in
  *Hyprland*) echo hyprland ;;
  *GNOME*) echo gnome ;; # GNOME and Budgie (both use org.gnome.desktop)
  *Cinnamon*) echo cinnamon ;;
  *MATE*) echo mate ;;
  *XFCE*) echo xfce ;;
  *sway* | *wlroots*) echo sway ;;
  *) # fall back to what's running
    if pgrep -x Hyprland &>/dev/null; then
      echo hyprland
    elif pgrep -x gnome-shell &>/dev/null; then
      echo gnome
    elif pgrep -x sway &>/dev/null; then
      echo sway
    elif pgrep -x xfce4-session &>/dev/null; then
      echo xfce
    else echo ""; fi ;;
  esac
}

DESKTOP=$(detect_desktop)
case "$DESKTOP" in
hyprland) set_hyprland "$PICK" ;;
gnome) set_gsettings org.gnome.desktop.background "$PICK" ;;
cinnamon) set_gsettings org.cinnamon.desktop.background "$PICK" ;;
mate) set_mate "$PICK" ;;
xfce) set_xfce "$PICK" ;;
sway) set_swaybg "$PICK" ;;
*)
  echo "unsupported desktop" >&2
  exit 1
  ;;
esac

printf '%s' "$PICK" >"$STATE/last"
