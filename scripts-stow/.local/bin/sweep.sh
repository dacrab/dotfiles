#!/usr/bin/env bash
set -uo pipefail

TIMEOUT=30

exists() { command -v "$1" &>/dev/null; }

fmt_size() {
  local kb=$1
  if ((kb >= 1048576)); then echo "$((kb / 1048576))G"
  elif ((kb >= 1024)); then echo "$((kb / 1024))M"
  else echo "${kb}K"
  fi
}

sweep_dir() {
  local path=$1 label=${2:-$1}
  [[ -e "$path" ]] || return
  local kb
  kb=$(timeout 10 du -sk "$path" 2>/dev/null | cut -f1) || return
  ((kb < 100)) && return
  if timeout 30 rm -rf "$path" 2>/dev/null; then
    printf '  ✓ %-20s %s\n' "$label" "$(fmt_size "$kb")"
  fi
}

heading() {
  echo
  echo "  $1"
  echo "  ${1//?/─}"
}

echo "  Sweep"
echo "  ─────"

sudo -v

# ── package managers ──
heading "package managers"

if exists apt; then
  timeout "$TIMEOUT" sudo apt autoremove --purge -y
fi
if exists dnf; then
  timeout "$TIMEOUT" sudo dnf clean all -q --setopt=tsflags=nodocs
  timeout "$TIMEOUT" sudo dnf autoremove -y -q
fi
if exists pacman; then
  timeout "$TIMEOUT" sudo pacman -Rns "$(pacman -Qdtq 2>/dev/null)" 2>/dev/null || true
fi
if exists zypper; then
  timeout "$TIMEOUT" sudo zypper clean -a
fi
if exists brew; then
  timeout "$TIMEOUT" brew cleanup -s 2>/dev/null
fi
if exists snap; then
  snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | while read -r name rev; do
    timeout "$TIMEOUT" sudo snap remove "$name" --revision="$rev" 2>/dev/null
  done
fi

# ── system ──
heading "system"

if exists journalctl; then
  timeout "$TIMEOUT" sudo journalctl --vacuum-time=3d 2>&1 | tail -1
fi
if exists trash-empty; then
  timeout "$TIMEOUT" trash-empty -f 7 2>/dev/null
else
  sweep_dir "$HOME/.local/share/Trash" Trash
fi
sweep_dir "$HOME/.cache/thumbnails" thumbnails

# ── containers ──
heading "containers"

if exists docker && timeout 5 docker info &>/dev/null; then
  timeout "$TIMEOUT" docker system prune -f
  timeout "$TIMEOUT" docker builder prune -af
fi
if exists podman; then
  timeout "$TIMEOUT" podman system prune -f
fi

# ── language runtimes ──
heading "runtimes"

if exists npm;   then timeout "$TIMEOUT" npm cache clean --force; fi
if exists pnpm;  then timeout "$TIMEOUT" pnpm store prune; fi
if exists yarn;  then timeout "$TIMEOUT" yarn cache clean; fi
if exists bun;   then timeout "$TIMEOUT" bun pm cache rm 2>/dev/null; fi
if exists pip3;  then timeout "$TIMEOUT" pip3 cache purge; fi
if exists pip;   then timeout "$TIMEOUT" pip cache purge; fi
if exists uv;    then timeout "$TIMEOUT" uv cache clean; fi
if exists go;    then timeout "$TIMEOUT" go clean -modcache; timeout "$TIMEOUT" go clean -cache; fi
if exists cargo; then
  timeout "$TIMEOUT" cargo cache --autoclean 2>/dev/null || {
    sweep_dir "$HOME/.cargo/registry/cache" cargo-registry
    sweep_dir "$HOME/.cargo/git/db"        cargo-git
  }
fi
if exists rustup; then
  timeout "$TIMEOUT" rustup clean 2>/dev/null
fi
if exists poetry; then
  timeout "$TIMEOUT" poetry cache clear --all -n 2>/dev/null || true
fi
sweep_dir "$HOME/.gradle/caches" gradle

# ── tool caches ──
(
  out=""
  for tool in node-gyp ms-playwright deno biome goimports gopls typescript prisma aws; do
    result=$(sweep_dir "$HOME/.cache/$tool" "$tool")
    [[ -n "$result" ]] && out+="$result"$'\n'
  done
  [[ -z "$out" ]] && exit
  heading "tool caches"
  echo -n "$out"
)

# ── editors ──
(
  out=""
  for editor in Code Cursor Windsurf VSCodium; do
    [[ -d "$HOME/.config/$editor" ]] || continue
    for cache in CachedData Cache GPUCache "Code Cache"; do
      result=$(sweep_dir "$HOME/.config/$editor/$cache" "$editor/$cache")
      [[ -n "$result" ]] && out+="$result"$'\n'
    done
  done
  [[ -z "$out" ]] && exit
  heading "editors"
  echo -n "$out"
)

# ── state files ──
(
  out=""
  for dir in less vimundo nvim/undo nvim/swap nvim/shada; do
    result=$(sweep_dir "$HOME/.local/state/$dir" "$dir")
    [[ -n "$result" ]] && out+="$result"$'\n'
  done
  [[ -z "$out" ]] && exit
  heading "state"
  echo -n "$out"
)

# ── orphaned virtualenvs ──
if [[ -d "$HOME/.virtualenvs" ]]; then
  out=""
  for venv in "$HOME/.virtualenvs"/*/; do
    [[ -f "$venv/pyvenv.cfg" ]] && continue
    result=$(sweep_dir "$venv" "$(basename "$venv")")
    [[ -n "$result" ]] && out+="$result"$'\n'
  done
  if [[ -n "$out" ]]; then
    heading "virtualenvs"
    echo -n "$out"
  fi
fi

# ── flatpak ──
if exists flatpak; then
  heading "flatpak"
  timeout "$TIMEOUT" flatpak uninstall --unused -y
fi

echo
echo "  done"
