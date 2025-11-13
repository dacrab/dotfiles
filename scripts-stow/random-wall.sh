#!/usr/bin/env bash
set -euo pipefail

# Resolve Pictures dir via xdg-user-dir when available; fallback to $HOME/Pictures
resolve_pictures_dir() {
  if command -v xdg-user-dir >/dev/null 2>&1; then
    xdg-user-dir PICTURES || true
  fi
}

PICTURES_DIR="$(resolve_pictures_dir)"
PICTURES_DIR=${PICTURES_DIR:-"$HOME/Pictures"}

# Allow override via $WALLPAPER_DIR; default to "$PICTURES_DIR/wallpapers" (recurses all subdirs)
WALLPAPER_DIR=${WALLPAPER_DIR:-"$PICTURES_DIR/wallpapers/nord-background"}

# State file to avoid immediate repeats
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/random-wall"
LAST_FILE="$STATE_DIR/last_wallpaper"
mkdir -p "$STATE_DIR"

# Build candidate list (common image types), recursively; ignore non-regular files
mapfile -t CANDIDATES < <(find "$WALLPAPER_DIR" -type f \
  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) | sort)

if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
  echo "No images found in: $WALLPAPER_DIR" >&2
  exit 1
fi

# Optionally avoid repeating the last wallpaper (when >1 candidate)
if [[ -f "$LAST_FILE" && ${#CANDIDATES[@]} -gt 1 ]]; then
  LAST=$(<"$LAST_FILE")
  # Filter out LAST from CANDIDATES
  mapfile -t FILTERED < <(printf '%s\n' "${CANDIDATES[@]}" | grep -Fvx -- "$LAST" || true)
  if [[ ${#FILTERED[@]} -gt 0 ]]; then
    CANDIDATES=(${FILTERED[@]})
  fi
fi

# Pick uniformly at random
if command -v shuf >/dev/null 2>&1; then
  PIC=$(printf '%s\n' "${CANDIDATES[@]}" | shuf -n 1)
else
  # Fallback: use /dev/urandom to choose an index
  count=${#CANDIDATES[@]}
  idx=$(( $(od -An -N4 -tu4 /dev/urandom | tr -d ' ') % count ))
  PIC=${CANDIDATES[$idx]}
fi

# Apply via gsettings (GNOME); noop if gsettings is not available
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.background picture-uri "file://$PIC"
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$PIC" || true
fi

# Persist selection
printf '%s' "$PIC" > "$LAST_FILE"
echo "Set wallpaper: $PIC"
