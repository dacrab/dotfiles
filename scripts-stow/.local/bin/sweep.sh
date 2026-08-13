#!/usr/bin/env bash
# ============================================
# sweep — system-wide cache & junk cleanup.
# Runs safe cleanup for every tool that's installed.
# All defaults are overridable via environment.
# ============================================
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

# ----- Tunables (override via env) -----
SWEEP_MIN_KB="${SWEEP_MIN_KB:-100}"            # skip paths smaller than this (KB)
SWEEP_JOURNAL_DAYS="${SWEEP_JOURNAL_DAYS:-3}"  # vacuum journal logs older than N days
SWEEP_TRASH_DAYS="${SWEEP_TRASH_DAYS:-7}"      # empty trash older than N days
read -ra SWEEP_TOOL_CACHES  <<< "${SWEEP_TOOL_CACHES:-node-gyp deno biome gopls typescript prisma}"
read -ra SWEEP_EDITORS      <<< "${SWEEP_EDITORS:-Code Cursor Windsurf VSCodium}"
read -ra SWEEP_STATE_DIRS   <<< "${SWEEP_STATE_DIRS:-less vimundo nvim/undo nvim/swap nvim/shada}"

# Fall back to the default when a numeric tunable isn't a positive integer.
num() { [[ "${!1}" =~ ^[0-9]+$ ]] || printf -v "$1" '%s' "$2"; }
num SWEEP_MIN_KB 100
num SWEEP_JOURNAL_DAYS 3
num SWEEP_TRASH_DAYS 7

# ----- XDG base dirs -----
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"

# Delete $1 if present and larger than $SWEEP_MIN_KB, printing freed space as $2.
clean() {
  [[ -e "$1" ]] || return
  local kb=0
  read -r kb _ < <(du -sk "$1" 2>/dev/null) || return
  ((kb < SWEEP_MIN_KB)) && return
  rm -rf "$1" 2>/dev/null || return
  if ((kb >= 1048576)); then printf '  %s (%dG)\n' "$2" $((kb / 1048576))
  elif ((kb >= 1024));  then printf '  %s (%dM)\n' "$2" $((kb / 1024))
  else                       printf '  %s (%dK)\n' "$2" "$kb"
  fi
}

has sudo && sudo -v

# ----- System package managers -----
has apt    && sudo apt autoremove --purge -y
has dnf    && sudo dnf clean all -q && sudo dnf autoremove -y -q
if has pacman; then
  mapfile -t orphans < <(sudo pacman -Qdtq 2>/dev/null)
  ((${#orphans[@]})) && sudo pacman -Rns --noconfirm "${orphans[@]}"
fi
has zypper && sudo zypper clean -a
has brew   && brew cleanup -s

if has snap; then
  while read -r name rev rest; do
    [[ "$rest" == *disabled* ]] && sudo snap remove "$name" --revision="$rev"
  done < <(snap list --all 2>/dev/null)
fi

# ----- System logs & trash -----
if has journalctl; then
  out=$(sudo journalctl --vacuum-time="${SWEEP_JOURNAL_DAYS}d" 2>&1)
  [[ -n "$out" ]] && echo "${out##*$'\n'}"
fi
if has trash-empty; then
  trash-empty -f "$SWEEP_TRASH_DAYS" || clean "$DATA/Trash" Trash
else
  clean "$DATA/Trash" Trash
fi
clean "$CACHE/thumbnails" thumbnails

# ----- Containers -----
if has docker; then
  docker system prune -f 2>/dev/null
  docker builder prune -af 2>/dev/null
fi
has podman && podman system prune -f 2>/dev/null

# ----- Language caches -----
has npm  && npm cache clean --force 2>/dev/null
has pnpm && pnpm store prune
has yarn && yarn cache clean
has bun  && bun pm cache rm 2>/dev/null
if has pip3; then pip3 cache purge; elif has pip; then pip cache purge; fi
has uv   && uv cache clean
has go   && go clean -modcache -cache

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

# ----- Tool caches -----
for d in "${SWEEP_TOOL_CACHES[@]}"; do
  clean "$CACHE/$d" "$d"
done

# ----- Editor caches -----
for e in "${SWEEP_EDITORS[@]}"; do
  [[ -d "$CONFIG/$e" ]] || continue
  for c in CachedData Cache GPUCache "Code Cache"; do
    clean "$CONFIG/$e/$c" "$e/$c"
  done
done

# ----- State dirs -----
for d in "${SWEEP_STATE_DIRS[@]}"; do
  clean "$STATE/$d" "$d"
done