#!/usr/bin/env bash
# sweep - portable cache/junk cleaner, topgrade-style:
# it detects what is installed and cleans only that, skipping the rest.
#
# usage: sweep [-n|--dry-run]
#
# env overrides (see README):
#   SWEEP_TRASH_DAYS     purge trash older than N days (default 7, 0 disables)
#   SWEEP_JOURNAL_AGE    journalctl --vacuum-time value (default 3d)
#   SWEEP_COREDUMP_DAYS  delete coredumps older than N days (default 7)
#   SWEEP_DOCKER         set to 1 to also prune stopped docker containers/dangling images
set -uo pipefail

DRY=""
case "${1:-}" in
-n | --dry-run) DRY=1 ;;
-h | --help)
       sed -n '2,11p' "$0"
       exit 0
       ;;
"") ;;
*)
       echo "sweep: unknown option: $1 (try --help)" >&2
       exit 2
       ;;
esac

TRASH_DAYS="${SWEEP_TRASH_DAYS:-7}"
JOURNAL_AGE="${SWEEP_JOURNAL_AGE:-3d}"
COREDUMP_DAYS="${SWEEP_COREDUMP_DAYS:-7}"

has() { command -v "$1" &>/dev/null; }
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"

section() { printf '\n==> %s\n' "$*"; }

# remove path if it exists (dry-run just reports)
clean() {
       [[ -e "$1" ]] || return 0
       [[ -n "$DRY" ]] && {
              echo "  rm -rf $1"
              return 0
       }
       rm -rf "$1"
}

# run a command (dry-run just reports); root steps go through sudo when needed
run() {
       [[ -n "$DRY" ]] && {
              echo "  $*"
              return 0
       }
       "$@"
}
as_root() {
       if [[ $EUID -eq 0 ]]; then
              run "$@"
       elif has sudo; then
              run sudo "$@"
       fi
}

# ---- package manager caches ---------------------------------------------
section "package manager caches"
has apt && as_root apt-get clean
has dnf && as_root dnf clean all -q
has pacman && as_root pacman -Sc --noconfirm
has zypper && as_root zypper clean -a
has brew && run brew cleanup -s

# stale snap revisions
if has snap; then
       while read -r name rev rest; do
              [[ "$rest" == *disabled* ]] && as_root snap remove "$name" --revision="$rev"
       done < <(snap list --all 2>/dev/null)
fi

# ---- logs, crash dumps, trash ------------------------------------------
section "system logs and crash dumps"
has journalctl && as_root journalctl --vacuum-time="$JOURNAL_AGE"
if [[ -d /var/lib/systemd/coredump ]]; then
       as_root find /var/lib/systemd/coredump -maxdepth 1 -type f -mtime +"$COREDUMP_DAYS" -delete
fi

if [[ "$TRASH_DAYS" != 0 ]] && has trash-empty; then
       run trash-empty -f "$TRASH_DAYS"
fi
clean "$CACHE/thumbnails"

# ---- language and runtime caches ---------------------------------------
section "language and runtime caches"
has npm && run npm cache clean --force --silent
has pnpm && run pnpm store prune
has yarn && run yarn cache clean
if has pip; then
       run pip cache purge
elif has pip3; then run pip3 cache purge; fi
has uv && run uv cache clean
has go && run go clean -cache
has poetry && run poetry cache clear . --all --no-interaction
has cargo-cache && run cargo cache --autoclean
clean "$HOME/.npm/_npx"

# bun: `bun pm cache rm` only works inside a project dir, so clean its
# global caches directly - both regenerate on demand
if has bun; then
       clean "${BUN_INSTALL:-$HOME/.bun}/install/cache"
       clean "$CACHE/bun"
fi

# ---- flatpak -------------------------------------------------------------
section "flatpak"
if has flatpak; then
       run flatpak uninstall --unused -y
       for c in "$HOME/.var/app"/*/cache; do clean "$c"; done
fi

# ---- generic tool caches under XDG cache --------------------------------
section "tool caches"
for d in node-gyp electron deno biome gopls typescript prisma opencode \
       tealdeer mozilla libreoffice Unity unityhub unity3d golangci-lint \
       tracker3 libdnf5 gnome-software flatpak fontconfig mesa_shader_cache \
       radv_builtin_shaders gstreamer-1.0 gnome-desktop-thumbnailer; do
       clean "$CACHE/$d"
done

# ---- vscode-family editors ----------------------------------------------
section "editor caches"
for e in Code "Code - OSS" VSCodium Cursor Windsurf; do
       [[ -d "$CONFIG/$e" ]] || continue
       for c in CachedData Cache CachedProfilesData CachedExtensionVSIXs \
              GPUCache "Code Cache" DawnGraphiteCache DawnWebGPUCache logs; do
              clean "$CONFIG/$e/$c"
       done
done

# ---- chromium/electron apps (auto-detected via their 'Local State' marker) --
# covers ~/.config browsers and flatpak apps in ~/.var/app alike; only
# cache-named directories are removed, profile data is never touched
section "chromium app caches"
while IFS= read -r -d '' marker; do
       root=$(dirname "$marker")
       while IFS= read -r d; do clean "$d"; done < <(
              find "$root" -maxdepth 4 -type d \
                     \( -name Cache -o -name "Code Cache" -o -name "Media Cache" \
                     -o -name GPUCache -o -name CacheStorage \
                     -o -name DawnGraphiteCache -o -name DawnWebGPUCache \
                     -o -name GraphiteDawnCache -o -name GPUPersistentCache \
                     -o -name ShaderCache -o -name GrShaderCache \
                     -o -name component_crx_cache \) -prune -print 2>/dev/null
       )
       clean "$CACHE/$(basename "$root")"
done < <(find "$CONFIG" "$HOME/.var/app" -maxdepth 6 -name "Local State" -type f -print0 2>/dev/null)

# ---- misc transient state -------------------------------------------------
clean "$STATE/less"

# ---- optional: docker (opt-in, off by default) ---------------------------
if [[ "${SWEEP_DOCKER:-0}" == 1 ]] && has docker; then
       run docker system prune -f # no --volumes, no -a: images/volumes are kept
fi

[[ -n "$DRY" ]] && echo "sweep done (dry run - nothing was removed)" || echo "sweep done"
