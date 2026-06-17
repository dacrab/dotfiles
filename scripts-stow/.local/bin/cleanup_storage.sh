#!/usr/bin/env bash
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

clean() {
  local p=$1 l=${2:-$1}
  [[ -e "$p" ]] || return
  local s=$(du -sk "$p" 2>/dev/null | cut -f1)
  ((s < 100)) && return
  rm -rf "$p" 2>/dev/null && echo "  ✓ $l ($((s/1024))M)"
}

echo "=== cleanup ==="
sudo -v

has dnf && { sudo dnf clean all -q; sudo dnf autoremove -y -q; }
has journalctl && sudo journalctl --vacuum-time=3d
has trash-empty && (yes | trash-empty 7 2>/dev/null) || clean "$HOME/.local/share/Trash" Trash
clean "$HOME/.cache/thumbnails" Thumbnails

has docker && docker ps &>/dev/null && docker system prune -f
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
