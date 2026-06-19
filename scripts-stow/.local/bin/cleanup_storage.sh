#!/usr/bin/env bash
set -uo pipefail

has() { command -v "$1" &>/dev/null; }
q() { "$@" &>/dev/null; }

clean() {
  local path=$1 label=${2:-$1}
  [[ -e "$path" ]] || return
  local kb=$(du -sk "$path" 2>/dev/null | cut -f1)
  ((kb < 100)) && return
  local size
  if ((kb >= 1048576)); then size="$((kb / 1048576))G"
  elif ((kb >= 1024)); then size="$((kb / 1024))M"
  else size="${kb}K"
  fi
  rm -rf "$path" 2>/dev/null && echo "  ✓ $label ($size)"
}

echo "=== cleanup ==="
sudo -v

has dnf && q sudo dnf clean all -q && q sudo dnf autoremove -y -q
has journalctl && sudo journalctl --vacuum-time=3d | tail -1
has trash-empty && trash-empty 7 2>/dev/null || clean "$HOME/.local/share/Trash" Trash
clean "$HOME/.cache/thumbnails" Thumbnails

has docker && docker info &>/dev/null && docker system prune -f
has podman && podman system prune -f

has npm && npm cache clean --force
has pnpm && pnpm store prune
has bun && bun pm cache rm
has pip3 && pip3 cache purge
has uv && uv cache clean
has go && { go clean -modcache; go clean -cache; }
has cargo && (cargo cache --autoclean 2>/dev/null || { clean "$HOME/.cargo/registry/cache" "Cargo registry"; clean "$HOME/.cargo/git/db" "Cargo git db"; })
clean "$HOME/.gradle/caches" Gradle

for t in node-gyp ms-playwright deno biome goimports gopls typescript prisma aws; do clean "$HOME/.cache/$t" "$t"; done

for e in Code Cursor Windsurf VSCodium; do
  [[ -d "$HOME/.config/$e" ]] && for c in CachedData Cache GPUCache "Code Cache"; do clean "$HOME/.config/$e/$c" "$e $c"; done
done

for s in less vimundo "nvim/undo" "nvim/swap" "nvim/shada" bash; do clean "$HOME/.local/state/$s" "state: $s"; done

[[ -d "$HOME/.virtualenvs" ]] && for v in "$HOME/.virtualenvs"/*/; do [[ -f "$v/pyvenv.cfg" ]] || clean "$v" "Orphan venv"; done

has flatpak && flatpak uninstall --unused -y

echo "✓ done"
