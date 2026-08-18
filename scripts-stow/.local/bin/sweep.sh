#!/usr/bin/env bash
# ============================================
# sweep — system-wide cache & junk cleanup.
# Safe by default; destructive ops are opt-in.
# All defaults are overridable via environment.
# ============================================
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

# ----- Tunables (override via env) -----
SWEEP_MIN_KB="${SWEEP_MIN_KB:-100}"             # skip paths smaller than this (KB)
SWEEP_JOURNAL_DAYS="${SWEEP_JOURNAL_DAYS:-3}"   # vacuum journal logs older than N days
SWEEP_TRASH_DAYS="${SWEEP_TRASH_DAYS:-7}"       # empty trash older than N days
read -ra SWEEP_TOOL_CACHES  <<< "${SWEEP_TOOL_CACHES:-node-gyp deno biome gopls typescript prisma}"
read -ra SWEEP_EDITORS      <<< "${SWEEP_EDITORS:-Code Cursor Windsurf VSCodium}"
read -ra SWEEP_BROWSERS     <<< "${SWEEP_BROWSERS:-net.imput.helium}" # Chromium app dirs under $CONFIG
read -ra SWEEP_STATE_DIRS   <<< "${SWEEP_STATE_DIRS:-less}"           # transient state only (undo kept)
read -ra SWEEP_FLATPAK_APPS <<< "${SWEEP_FLATPAK_APPS:-}"             # limit flatpak caches (default: all)

DRY_RUN=0
AGGRESSIVE=0

usage() {
  cat <<'EOF'
Usage: sweep [OPTIONS]

Purge caches, logs and junk. Safe actions run by default; destructive
package-manager/container/state ops require --aggressive.

  -n, --dry-run     print what would be removed, change nothing
  -a, --aggressive  also autoremove packages, prune docker/podman/go
                    modules, and wipe editor undo/history state
  -h, --help        show this help

Env overrides:
  SWEEP_MIN_KB, SWEEP_JOURNAL_DAYS, SWEEP_TRASH_DAYS,
  SWEEP_TOOL_CACHES, SWEEP_EDITORS, SWEEP_BROWSERS,
  SWEEP_STATE_DIRS, SWEEP_FLATPAK_APPS
EOF
}

while (($#)); do
  case "$1" in
    -n|--dry-run) DRY_RUN=1 ;;
    -a|--aggressive) AGGRESSIVE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "sweep: unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

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

FREED=0

hsize() {
  local kb=$1
  if ((kb >= 1048576)); then printf '%dG' $((kb / 1048576))
  elif ((kb >= 1024));  then printf '%dM' $((kb / 1024))
  else                       printf '%dK' "$kb"
  fi
}

# Delete $1 if present and larger than $SWEEP_MIN_KB, printing freed space as $2.
clean() {
  [[ -e "$1" ]] || return
  local kb=0
  read -r kb _ < <(du -sk "$1" 2>/dev/null) || return
  ((kb < SWEEP_MIN_KB)) && return
  if ((DRY_RUN)); then
    printf '  [dry-run] %-24s %s\n' "$2" "$(hsize "$kb")"
    return
  fi
  rm -rf "$1" 2>/dev/null || return
  FREED=$((FREED + kb))
  printf '  %-24s %s\n' "$2" "$(hsize "$kb")"
}

# Run $@ only when not in dry-run mode; quiet by default.
run() {
  if ((DRY_RUN)); then
    printf '  [dry-run] run: %s\n' "$*"
  else
    "$@" >/dev/null 2>&1
  fi
}

if ((!DRY_RUN)); then
  has sudo && sudo -v
fi

# ----- System package caches (safe) -----
has apt    && run sudo apt-get clean
has dnf    && run sudo dnf clean all -q
has pacman && run sudo pacman -Sc --noconfirm
has zypper && run sudo zypper clean -a
has brew   && run brew cleanup -s

if ((!DRY_RUN)) && has snap; then
  while read -r name rev rest; do
    [[ "$rest" == *disabled* ]] && sudo snap remove "$name" --revision="$rev"
  done < <(snap list --all 2>/dev/null)
fi

# ----- Aggressive: package autoremove / container prune -----
if ((AGGRESSIVE)); then
  has apt && run sudo apt autoremove --purge -y
  has dnf && run sudo dnf autoremove -y -q
  if has pacman; then
    mapfile -t orphans < <(sudo pacman -Qdtq 2>/dev/null)
    ((${#orphans[@]})) && run sudo pacman -Rns --noconfirm "${orphans[@]}"
  fi
  has docker && run docker system prune -f
  has docker && run docker builder prune -af
  has podman && run podman system prune -f
fi

# ----- System logs & trash -----
if ((!DRY_RUN)) && has journalctl; then
  out=$(sudo journalctl --vacuum-time="${SWEEP_JOURNAL_DAYS}d" 2>&1)
  [[ -n "$out" ]] && echo "${out##*$'\n'}"
fi
if has trash-empty; then
  run trash-empty -f "$SWEEP_TRASH_DAYS"
else
  clean "$DATA/Trash" Trash
fi
clean "$CACHE/thumbnails" thumbnails

# ----- Language caches -----
has npm  && run npm cache clean --force
has pnpm && run pnpm store prune
has yarn && run yarn cache clean
has bun  && run bun pm cache rm
if has pip3; then run pip3 cache purge; elif has pip; then run pip cache purge; fi
has uv   && run uv cache clean
if ((AGGRESSIVE)); then
  has go && run go clean -modcache -cache
else
  has go && run go clean -cache
fi
clean "$HOME/.npm/_npx" npx-cache

if has cargo; then
  if ((!DRY_RUN)); then
    cargo cache --autoclean 2>/dev/null || {
      clean "$HOME/.cargo/registry/cache" cargo-registry
      clean "$HOME/.cargo/registry/src" cargo-src
      clean "$HOME/.cargo/git/db" cargo-git
      clean "$HOME/.cargo/git/checkouts" cargo-checkouts
    }
  fi
fi

has poetry  && run poetry cache clear . --all --no-interaction
has flatpak && run flatpak uninstall --unused -y

# ----- Flatpak app caches (Spotify, Telegram, etc.) -----
if has flatpak; then
  for c in ~/.var/app/*/cache; do
    [[ -d "$c" ]] || continue
    app=${c#~/.var/app/}
    app=${app%/cache}
    ((${#SWEEP_FLATPAK_APPS[@]})) && \
      [[ ! " ${SWEEP_FLATPAK_APPS[*]} " == *" $app "* ]] && continue
    clean "$c" "flatpak/$app"
  done
fi

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

# ----- Chromium-based app caches (browsers, AI IDEs) -----
# Clears only well-known cache dirs; profile data (File System,
# WebStorage, IndexedDB, login state) is left untouched.
for b in "${SWEEP_BROWSERS[@]}"; do
  [[ -d "$CONFIG/$b" ]] || continue
  clean "$CACHE/$b" "$b/cache-dir"
  for c in "Default/Cache" "Default/Code Cache" "Default/GPUCache" \
           "Default/Service Worker/CacheStorage"; do
    clean "$CONFIG/$b/$c" "$b/$c"
  done
done

# ----- Transient state (editor undo/history kept unless --aggressive) -----
for d in "${SWEEP_STATE_DIRS[@]}"; do
  clean "$STATE/$d" "$d"
done
if ((AGGRESSIVE)); then
  for d in vimundo nvim/undo nvim/swap nvim/shada; do
    clean "$STATE/$d" "$d"
  done
fi

echo
if ((DRY_RUN)); then
  echo "Dry run — nothing was removed."
else
  echo "Done. Freed $(hsize "$FREED")."
fi
