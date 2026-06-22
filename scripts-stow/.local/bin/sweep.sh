#!/usr/bin/env bash
set -uo pipefail

exists() { command -v "$1" &>/dev/null; }

clean() {
  local p=$1 l=${2:-$1}
  [[ -e "$p" ]] || return
  local kb
  kb=$(du -sk "$p" 2>/dev/null | cut -f1) || return
  ((kb < 100)) && return
  rm -rf "$p" 2>/dev/null || return
  local h
  if ((kb >= 1048576)); then h="$((kb / 1048576))G"
  elif ((kb >= 1024)); then h="$((kb / 1024))M"
  else h="${kb}K"
  fi
  printf '  ✓ %-20s %s\n' "$l" "$h"
}

flush() {
  [[ -z "$1" ]] && return
  echo
  echo "  $2"
  echo "  ${2//?/─}"
  echo -n "$1"
}

sudo -v
echo "  Sweep"
echo "  ─────"

# ── package managers ──
echo
echo "  package managers"
echo "  ────────────────"

if exists apt;    then sudo apt autoremove --purge -y; fi
if exists dnf;    then sudo dnf clean all -q --setopt=tsflags=nodocs; sudo dnf autoremove -y -q; fi
if exists pacman; then pacman -Qdtq 2>/dev/null | xargs -r sudo pacman -Rns 2>/dev/null || true; fi
if exists zypper; then sudo zypper clean -a; fi
if exists brew;   then brew cleanup -s; fi
if exists snap;   then
  snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | while read -r n r; do
    sudo snap remove "$n" --revision="$r" 2>/dev/null
  done
fi

# ── system ──
echo
echo "  system"
echo "  ──────"

if exists journalctl; then sudo journalctl --vacuum-time=3d 2>&1 | tail -1; fi
if exists trash-empty; then trash-empty -f 7 2>/dev/null; else clean "$HOME/.local/share/Trash" Trash; fi
clean "$HOME/.cache/thumbnails" thumbnails

# ── containers ──
echo
echo "  containers"
echo "  ──────────"

if [[ -S /var/run/docker.sock ]]; then
  docker system prune -f
  docker builder prune -af
fi
if exists podman; then podman system prune -f; fi

# ── runtimes ──
echo
echo "  runtimes"
echo "  ────────"

if exists npm;    then npm cache clean --force; fi
if exists pnpm;   then pnpm store prune; fi
if exists yarn;   then yarn cache clean; fi
if exists bun;    then bun pm cache rm 2>/dev/null; fi
if exists pip3;   then pip3 cache purge; fi
if exists pip;    then pip cache purge; fi
if exists uv;     then uv cache clean; fi
if exists go;     then go clean -modcache; go clean -cache; fi
if exists rustup; then rustup clean 2>/dev/null; fi
if exists cargo;  then cargo cache --autoclean 2>/dev/null || { clean "$HOME/.cargo/registry/cache" cargo-registry; clean "$HOME/.cargo/git/db" cargo-git; }; fi
if exists poetry; then poetry cache clear --all -n 2>/dev/null || true; fi
clean "$HOME/.gradle/caches" gradle

# ── tool caches ──
out=""
for d in node-gyp ms-playwright deno biome goimports gopls typescript prisma aws; do
  out+="$(clean "$HOME/.cache/$d" "$d")"
done
flush "$out" "tool caches"

# ── editors ──
out=""
for e in Code Cursor Windsurf VSCodium; do
  [[ -d "$HOME/.config/$e" ]] || continue
  for c in CachedData Cache GPUCache "Code Cache"; do
    out+="$(clean "$HOME/.config/$e/$c" "$e/$c")"
  done
done
flush "$out" "editors"

# ── state ──
out=""
for d in less vimundo nvim/undo nvim/swap nvim/shada; do
  out+="$(clean "$HOME/.local/state/$d" "$d")"
done
flush "$out" "state"

# ── virtualenvs ──
out=""
if [[ -d "$HOME/.virtualenvs" ]]; then
  for v in "$HOME/.virtualenvs"/*/; do
    [[ -f "$v/pyvenv.cfg" ]] && continue
    out+="$(clean "$v" "$(basename "$v")")"
  done
fi
flush "$out" "virtualenvs"

# ── flatpak ──
if exists flatpak; then
  echo
  echo "  flatpak"
  echo "  ───────"
  flatpak uninstall --unused -y
fi

echo
echo "  done"
