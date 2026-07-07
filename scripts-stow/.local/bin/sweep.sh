#!/usr/bin/env bash
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

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
  echo "  $l ($h)"
}

echo "===== System Sweep ====="
START=$(date +%s)

sudo -v

if has apt; then sudo apt autoremove --purge -y; fi
if has dnf; then sudo dnf clean all -q --setopt=tsflags=nodocs && sudo dnf autoremove -y -q; fi
if has pacman; then
  sudo pacman -Qdtq | xargs -r sudo pacman -Rns
fi
if has zypper; then sudo zypper clean -a; fi
if has brew; then brew cleanup -s; fi
if has snap; then
  snap list --all | awk '/disabled/{print $1, $3}' | while read -r n r; do
    sudo snap remove "$n" --revision="$r"
  done
fi

if has journalctl; then
  sudo journalctl --vacuum-time=3d 2>&1 | tail -1
fi

if has trash-empty; then trash-empty -f 7; else clean "$HOME/.local/share/Trash" Trash; fi
clean "$HOME/.cache/thumbnails" thumbnails

if [[ -S /var/run/docker.sock ]]; then
  docker system prune -f
  docker builder prune -af
fi

if has podman; then podman system prune -f; fi

if has npm; then npm cache clean --force; fi
if has pnpm; then pnpm store prune; fi
if has yarn; then yarn cache clean; fi
if has bun; then bun pm cache rm; fi
if has pip3; then pip3 cache purge; fi
if has pip; then pip cache purge; fi
if has uv; then uv cache clean; fi
if has go; then go clean -modcache && go clean -cache; fi
if has rustup; then rustup clean; fi
if has cargo; then
  cargo cache --autoclean || {
    clean "$HOME/.cargo/registry/cache" cargo-registry
    clean "$HOME/.cargo/git/db" cargo-git
  }
fi
if has poetry; then poetry cache clear --all --no-interaction; fi
clean "$HOME/.gradle/caches" gradle

for d in node-gyp ms-playwright deno biome goimports gopls typescript prisma aws; do
  clean "$HOME/.cache/$d" "$d"
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

if [[ -d "$HOME/.virtualenvs" ]]; then
  for v in "$HOME/.virtualenvs"/*/; do
    [[ -f "$v/pyvenv.cfg" ]] && continue
    clean "$v" "$(basename "$v")"
  done
fi

has flatpak && flatpak uninstall --unused -y

echo "===== Done ($(( $(date +%s) - START ))s) ====="
