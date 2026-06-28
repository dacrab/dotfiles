#!/usr/bin/env bash
set -uo pipefail

HAS_GUM=false; command -v gum &>/dev/null && HAS_GUM=true

has() { command -v "$1" &>/dev/null; }

# ── Styling ──
hdr()  { $HAS_GUM && gum style --border double --padding "0 2" --foreground 212 --bold --width 60 --align center "$1" || echo "===== $1 ====="; }
title(){ echo; $HAS_GUM && gum style --foreground 39 --bold --padding "0 0" "  $1" && gum style --foreground 39 --faint "  ──────────────────────────────────" || echo "--- $1 ---"; }
inf()  { $HAS_GUM && gum log -t "15:04:05" -l info "$1" || echo "  [$(date +%T)] ✓ $1"; }
warn() { $HAS_GUM && gum log -t "15:04:05" -l warn "$1" || echo "  ⚠ $1"; }

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
  echo "    ✓ $l  ($h)"
}

START=$(date +%s)

echo
hdr "System Sweep"
echo

sudo -v

# ──────────────────────────────────────────────
title "Package Managers"
if has apt; then echo "  → apt autoremove"; sudo apt autoremove --purge -y; fi
if has dnf; then echo "  → dnf clean + autoremove"; sudo dnf clean all -q --setopt=tsflags=nodocs && sudo dnf autoremove -y -q; fi
if has pacman; then echo "  → pacman orphans"; sudo bash -c 'pacman -Qdtq 2>/dev/null | xargs -r sudo pacman -Rns 2>/dev/null || true'; fi
if has zypper; then echo "  → zypper clean"; sudo zypper clean -a; fi
if has brew; then echo "  → brew cleanup"; brew cleanup -s; fi
if has snap; then
  echo "  → snap disabled revisions"
  snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | while read -r n r; do
    sudo snap remove "$n" --revision="$r" 2>/dev/null
  done
fi
inf "Package managers cleaned"

# ──────────────────────────────────────────────
title "System"
if has journalctl; then
  echo "  → journalctl vacuum"
  sudo journalctl --vacuum-time=3d 2>&1 | tail -1
fi
echo "  → trash"
if has trash-empty; then trash-empty -f 7 2>/dev/null; else clean "$HOME/.local/share/Trash" Trash; fi
clean "$HOME/.cache/thumbnails" thumbnails
inf "System cleaned"

# ──────────────────────────────────────────────
title "Containers"
if [[ -S /var/run/docker.sock ]]; then
  echo "  → docker prune"
  docker system prune -f
  docker builder prune -af
fi
if has podman; then echo "  → podman prune"; podman system prune -f; fi
inf "Containers cleaned"

# ──────────────────────────────────────────────
title "Runtimes"
if has npm; then echo "  → npm cache"; npm cache clean --force; fi
if has pnpm; then echo "  → pnpm store"; pnpm store prune; fi
if has yarn; then echo "  → yarn cache"; yarn cache clean; fi
if has bun; then echo "  → bun cache"; bun pm cache rm; fi
if has pip3; then echo "  → pip3 cache"; pip3 cache purge; fi
if has pip; then echo "  → pip cache"; pip cache purge; fi
if has uv; then echo "  → uv cache"; uv cache clean; fi
if has go; then echo "  → go cache"; go clean -modcache && go clean -cache; fi
if has rustup; then echo "  → rustup clean"; rustup clean; fi
if has cargo; then
  echo "  → cargo cache"
  cargo cache --autoclean 2>/dev/null || {
    clean "$HOME/.cargo/registry/cache" cargo-registry
    clean "$HOME/.cargo/git/db" cargo-git
  }
fi
if has poetry; then echo "  → poetry cache"; poetry cache clear --all; fi
clean "$HOME/.gradle/caches" gradle
inf "Runtimes cleaned"

# ──────────────────────────────────────────────
title "Tool Caches"
for d in node-gyp ms-playwright deno biome goimports gopls typescript prisma aws; do
  clean "$HOME/.cache/$d" "$d"
done
inf "Tool caches cleaned"

# ──────────────────────────────────────────────
title "Editors"
for e in Code Cursor Windsurf VSCodium; do
  [[ -d "$HOME/.config/$e" ]] || continue
  for c in CachedData Cache GPUCache "Code Cache"; do
    clean "$HOME/.config/$e/$c" "$e/$c"
  done
done
inf "Editor caches cleaned"

# ──────────────────────────────────────────────
title "State"
for d in less vimundo nvim/undo nvim/swap nvim/shada; do
  clean "$HOME/.local/state/$d" "$d"
done
inf "State cleaned"

# ──────────────────────────────────────────────
title "Virtualenvs"
if [[ -d "$HOME/.virtualenvs" ]]; then
  for v in "$HOME/.virtualenvs"/*/; do
    [[ -f "$v/pyvenv.cfg" ]] && continue
    clean "$v" "$(basename "$v")"
  done
fi
inf "Virtualenvs cleaned"

# ──────────────────────────────────────────────
if has flatpak; then
  title "Flatpak"
  echo "  → flatpak unused runtimes"
  flatpak uninstall --unused -y
  inf "Flatpak cleaned"
fi

# ──────────────────────────────────────────────
END=$(date +%s)
ELAPSED=$((END - START))
echo
hdr "Sweep complete! (${ELAPSED}s)"
echo
