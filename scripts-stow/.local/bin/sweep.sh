#!/usr/bin/env bash
# sweep - clear caches and junk (safe only).
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"

clean() { [[ -e "$1" ]] && rm -rf "$1"; }

# package manager caches
has apt    && sudo apt-get clean
has dnf    && sudo dnf clean all -q
has pacman && sudo pacman -Sc --noconfirm
has zypper && sudo zypper clean -a
has brew   && brew cleanup -s

# stale snap revisions
if has snap; then
  while read -r name rev rest; do
    [[ "$rest" == *disabled* ]] && sudo snap remove "$name" --revision="$rev"
  done < <(snap list --all 2>/dev/null)
fi

# logs and trash
has journalctl && sudo journalctl --vacuum-time=3d
has trash-empty && trash-empty -f 7
clean "$CACHE/thumbnails"

# language/runtime caches
has npm    && npm cache clean --force
has pnpm   && pnpm store prune
has yarn   && yarn cache clean
has bun    && bun pm cache rm
has pip3   && pip3 cache purge
has uv     && uv cache clean
has go     && go clean -cache
has poetry && poetry cache clear . --all --no-interaction
has cargo  && cargo cache --autoclean
clean "$HOME/.npm/_npx"

# flatpak
if has flatpak; then
  flatpak uninstall --unused -y
  for c in ~/.var/app/*/cache; do clean "$c"; done
fi

# tool caches
for d in node-gyp deno biome gopls typescript prisma; do clean "$CACHE/$d"; done

# editor caches
for e in Code Cursor Windsurf VSCodium; do
  [[ -d "$CONFIG/$e" ]] || continue
  for c in CachedData Cache GPUCache "Code Cache"; do clean "$CONFIG/$e/$c"; done
done

# chromium-based app cache (profile data kept)
for c in "$CACHE/net.imput.helium" \
         "$CONFIG/net.imput.helium/Default/Cache" \
         "$CONFIG/net.imput.helium/Default/Code Cache" \
         "$CONFIG/net.imput.helium/Default/GPUCache" \
         "$CONFIG/net.imput.helium/Default/Service Worker/CacheStorage"; do
  clean "$c"
done

# transient state
clean "$STATE/less"

echo "sweep done"