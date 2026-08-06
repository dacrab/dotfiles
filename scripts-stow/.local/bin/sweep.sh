#!/usr/bin/env bash
# ============================================
# sweep — system-wide cache & junk cleanup.
# Runs safe cleanup for every tool that's installed.
# ============================================
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

# Delete $1 if present and larger than 100 KB, printing freed space as $2.
clean() {
  [[ -e "$1" ]] || return
  local kb
  kb=$(du -sk "$1" 2>/dev/null | cut -f1) || return
  ((kb < 100)) && return
  rm -rf "$1" 2>/dev/null || return
  if ((kb >= 1048576)); then echo "  $2 ($((kb / 1048576))G)"
  elif ((kb >= 1024)); then echo "  $2 ($((kb / 1024))M)"
  else echo "  $2 (${kb}K)"
  fi
}

# ----- XDG base dirs -----
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"

has sudo && sudo -v

# ============================================
# System package cleanup
# ============================================
has apt    && sudo apt autoremove --purge -y
has dnf    && sudo dnf clean all -q && sudo dnf autoremove -y -q
has pacman && sudo pacman -Qdtq | xargs -r sudo pacman -Rns
has zypper && sudo zypper clean -a
has brew   && brew cleanup -s
has snap   && snap list --all | awk '/disabled/{print $1, $3}' | while read -r n r; do sudo snap remove "$n" --revision="$r"; done

# ============================================
# System logs & trash
# ============================================
has journalctl  && sudo journalctl --vacuum-time=3d 2>&1 | tail -1
has trash-empty && trash-empty -f 7 || clean "$DATA/Trash" Trash
clean "$CACHE/thumbnails" thumbnails

# ============================================
# Containers
# ============================================
if has docker; then
  docker system prune -f 2>/dev/null
  docker builder prune -af 2>/dev/null
fi

has podman && podman system prune -f

# ============================================
# Language caches
# ============================================
has npm  && npm cache clean --force 2>/dev/null
has pnpm && pnpm store prune
has yarn && yarn cache clean
has bun  && bun pm cache rm 2>/dev/null
has pip3 && pip3 cache purge
has pip  && pip cache purge
has uv   && uv cache clean
has go   && go clean -modcache && go clean -cache

if has cargo; then
  cargo cache --autoclean 2>/dev/null || {
    clean "$HOME/.cargo/registry/cache" cargo-registry
    clean "$HOME/.cargo/registry/src" cargo-src
    clean "$HOME/.cargo/git/db" cargo-git
    clean "$HOME/.cargo/git/checkouts" cargo-checkouts
  }
fi

has poetry  && poetry cache clear . --all --no-interaction
has flatpak && flatpak uninstall --unused -y

# ============================================
# Tool caches
# ============================================
for d in node-gyp deno biome gopls typescript prisma; do
  clean "$CACHE/$d" "$d"
done

# ============================================
# Editor caches
# ============================================
for e in Code Cursor Windsurf VSCodium; do
  [[ -d "$CONFIG/$e" ]] || continue
  for c in CachedData Cache GPUCache "Code Cache"; do
    clean "$CONFIG/$e/$c" "$e/$c"
  done
done

# ============================================
# State dirs
# ============================================
for d in less vimundo nvim/undo nvim/swap nvim/shada; do
  clean "$STATE/$d" "$d"
done
