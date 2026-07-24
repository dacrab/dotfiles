#!/usr/bin/env bash
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

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

echo "===== System Sweep ====="
START=$(date +%s)

sudo -v
has apt    && sudo apt autoremove --purge -y
has dnf    && sudo dnf clean all -q && sudo dnf autoremove -y -q
has pacman && sudo pacman -Qdtq | xargs -r sudo pacman -Rns
has zypper && sudo zypper clean -a
has brew   && brew cleanup -s
has snap   && snap list --all | awk '/disabled/{print $1, $3}' | while read -r n r; do sudo snap remove "$n" --revision="$r"; done

has journalctl && sudo journalctl --vacuum-time=3d 2>&1 | tail -1
has trash-empty && trash-empty -f 7 || clean "$HOME/.local/share/Trash" Trash
clean "$HOME/.cache/thumbnails" thumbnails

[[ -S /var/run/docker.sock ]] && docker system prune -f && docker builder prune -af
has podman    && podman system prune -f

has npm       && npm cache clean --force
has pnpm      && pnpm store prune
has yarn      && yarn cache clean
has bun       && bun pm cache rm 2>/dev/null
has pip3      && pip3 cache purge
has pip       && pip cache purge
has uv        && uv cache clean
has go        && go clean -modcache && go clean -cache
has cargo     && cargo cache --autoclean 2>/dev/null || true
has poetry    && poetry cache clear . --all --no-interaction
has flatpak   && flatpak uninstall --unused -y

for d in node-gyp deno biome gopls typescript prisma; do
  has "${d%%-*}" && clean "$HOME/.cache/$d" "$d"
done

for e in Code Cursor Windsurf VSCodium; do
  [[ -d "$HOME/.config/$e" ]] || continue
  for c in CachedData Cache GPUCache "Code Cache"; do
    clean "$HOME/.config/$e/$c" "$e/$c"
  done
done

for d in less vimundo nvim/undo nvim/swap nvim/shada; do
  clean "$HOME/.local/state/$d" "$d"
done

echo "===== Done ($(( $(date +%s) - START ))s) ====="
