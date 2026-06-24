#!/usr/bin/env bash
set -uo pipefail

exists() { command -v "$1" &>/dev/null; }

section() {
  echo
  echo "  $1"
  echo "  ${1//?/─}"
}

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

run() {
  local cmd=$1; shift
  exists "$cmd" || return
  "$cmd" "$@"
}

sudo -v
echo "  Sweep"
echo "  ─────"

# ── package managers ──
section "package managers"
run apt    sudo apt autoremove --purge -y
run dnf    sudo dnf clean all -q --setopt=tsflags=nodocs && sudo dnf autoremove -y -q
run pacman sudo bash -c 'pacman -Qdtq 2>/dev/null | xargs -r sudo pacman -Rns 2>/dev/null || true'
run zypper sudo zypper clean -a
run brew   brew cleanup -s
if exists snap; then
  snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | while read -r n r; do
    sudo snap remove "$n" --revision="$r" 2>/dev/null
  done
fi

# ── system ──
section "system"
run journalctl sudo journalctl --vacuum-time=3d 2>&1 | tail -1
if exists trash-empty; then trash-empty -f 7 2>/dev/null; else clean "$HOME/.local/share/Trash" Trash; fi
clean "$HOME/.cache/thumbnails" thumbnails

# ── containers ──
section "containers"
if [[ -S /var/run/docker.sock ]]; then
  docker system prune -f
  docker builder prune -af
fi
run podman podman system prune -f

# ── runtimes ──
section "runtimes"
run npm    npm cache clean --force
run pnpm   pnpm store prune
run yarn   yarn cache clean
run bun    bun pm cache rm
run pip3   pip3 cache purge
run pip    pip cache purge
run uv     uv cache clean
run go     go clean -modcache && go clean -cache
run rustup rustup clean
run cargo  cargo cache --autoclean 2>/dev/null || { clean "$HOME/.cargo/registry/cache" cargo-registry; clean "$HOME/.cargo/git/db" cargo-git; }
run poetry poetry cache clear --all
clean "$HOME/.gradle/caches" gradle

# ── tool caches ──
section "tool caches"
for d in node-gyp ms-playwright deno biome goimports gopls typescript prisma aws; do
  clean "$HOME/.cache/$d" "$d"
done

# ── editors ──
section "editors"
for e in Code Cursor Windsurf VSCodium; do
  [[ -d "$HOME/.config/$e" ]] || continue
  for c in CachedData Cache GPUCache "Code Cache"; do
    clean "$HOME/.config/$e/$c" "$e/$c"
  done
done

# ── state ──
section "state"
for d in less vimundo nvim/undo nvim/swap nvim/shada; do
  clean "$HOME/.local/state/$d" "$d"
done

# ── virtualenvs ──
section "virtualenvs"
if [[ -d "$HOME/.virtualenvs" ]]; then
  for v in "$HOME/.virtualenvs"/*/; do
    [[ -f "$v/pyvenv.cfg" ]] && continue
    clean "$v" "$(basename "$v")"
  done
fi

# ── flatpak ──
if exists flatpak; then
  section "flatpak"
  flatpak uninstall --unused -y
fi

echo
echo "  done"
