#!/usr/bin/env bash
set -uo pipefail

DRY=false AUTO=false PURGE=false INST=false
SUDO_PID="" SPIN_PID=""

if [[ -t 1 && "${TERM:-dumb}" != "dumb" ]]; then
  G='\033[32m' Y='\033[33m' B='\033[34m' C='\033[36m' M='\033[35m' DM='\033[2m' R='\033[0m' L='\033[1m'
else
  G='' Y='' B='' C='' M='' DM='' R='' L=''
fi

cleanup() {
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null
  [[ -n "$SUDO_PID" ]] && kill "$SUDO_PID" 2>/dev/null
  tput cnorm 2>/dev/null || :
}
trap cleanup EXIT INT TERM

ok()   { echo -e "  ${G}✔${R}  $1"; }
warn() { echo -e "  ${Y}⚠${R}  $1"; }
info() { echo -e "  ${B}ℹ${R}  $1"; }
sec()  { echo -e "\n${C}${L}$1${R}"; }
has()  { command -v "$1" &>/dev/null; }
szk()  { du -sk "$1" 2>/dev/null | cut -f1 || echo 0; }
disk() { df -h / | awk 'NR==2{ print $3"/"$2" ("$5")" }'; }

human() {
  local k=$1
  ((k >= 1048576)) && echo "$((k / 1048576))G" && return
  ((k >= 1024)) && echo "$((k / 1024))M" && return
  echo "${k}K"
}

spin() {
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
  tput civis 2>/dev/null || :
  while :; do
    printf "\r${DM}[%s]${R} %s" "${frames:i++%10:1}" "$1"
    sleep .08
  done &
  SPIN_PID=$!
}

unspin() {
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null && wait "$SPIN_PID" 2>/dev/null || :
  SPIN_PID=""
  printf "\r\033[K"
  tput cnorm 2>/dev/null || :
  if [[ "$1" == ok ]]; then
    ok "$2"
  else
    warn "$2"
  fi
}

run() {
  local label="$1"; shift
  $DRY && info "Would run: $label" && return
  spin "$label"
  if "$@" &>/dev/null; then
    unspin ok "$label"
  else
    unspin fail "$label"
  fi
}

clean() {
  local path="$1" label="${2:-$1}"
  [[ ! -e "$path" ]] && return
  local size
  size=$(szk "$path")
  ((size < 100)) && return
  $DRY && info "Would clean: $label ($(human "$size"))" && return
  if rm -rf "$path" 2>/dev/null; then
    ok "$label ($(human "$size"))"
  else
    warn "$label"
  fi
}

clean_system() {
  sec "System packages"
  
  if has dnf; then
    run "DNF clean" sudo dnf clean all -q
    run "DNF autoremove" sudo dnf autoremove -y -q
  elif has apt-get; then
    run "APT clean" sudo apt-get clean
    run "APT autoremove" sudo apt-get autoremove --purge -y
  elif has pacman; then
    run "Pacman clean" sudo pacman -Sc --noconfirm
    local -a orphans=()
    while IFS= read -r pkg; do
      orphans+=("$pkg")
    done < <(pacman -Qdtq 2>/dev/null || :)
    [[ ${#orphans[@]} -gt 0 ]] && run "Pacman orphans" sudo pacman -Rns --noconfirm "${orphans[@]}"
  fi
  
  has zypper && run "Zypper clean" sudo zypper clean --all
  has journalctl && run "Journal vacuum" sudo journalctl --vacuum-time=3d
  
  if has trash-empty; then
    $DRY || { spin "Trash"; yes | trash-empty 7 &>/dev/null; unspin ok "Trash"; }
  else
    clean "$HOME/.local/share/Trash" "Trash"
  fi
  
  clean "$HOME/.cache/thumbnails" "Thumbnails"
}

clean_containers() {
  sec "Containers"
  has docker && docker ps &>/dev/null && run "Docker prune" docker system prune -f
  has podman && run "Podman prune" podman system prune -f
}

clean_dev() {
  sec "Dev tools"
  
  if has npm; then
    run "NPM cache" npm cache clean --force
    run "NPM verify" npm cache verify
  fi
  has pnpm && run "PNPM prune" pnpm store prune
  has yarn && run "Yarn cache" yarn cache clean
  has bun && run "Bun cache" bun pm cache rm
  
  has pip3 && run "Pip cache" pip3 cache purge
  has uv && run "UV cache" uv cache clean
  has pipx && run "Pipx cache" pipx runpip --spec "" -- cache purge 2>/dev/null || :
  
  if has go; then
    run "Go modcache" go clean -modcache
    run "Go cache" go clean -cache
  fi
  
  has dotnet && run "NuGet cache" dotnet nuget locals all --clear
  if has cargo; then
    if cargo cache --help &>/dev/null; then
      run "Cargo cache" cargo cache --autoclean
    else
      clean "$HOME/.cargo/registry/cache" "Cargo registry"
      clean "$HOME/.cargo/git/db" "Cargo git db"
    fi
  fi
  
  clean "$HOME/.gradle/caches" "Gradle caches"
  clean "$HOME/.gradle/daemon" "Gradle daemon"
  
  for tool in node-gyp ms-playwright ms-playwright-go deno biome goimports gopls typescript prisma aws; do
    clean "$HOME/.cache/$tool" "$tool cache"
  done
  
  [[ -d "$HOME/.virtualenvs" ]] && for venv in "$HOME/.virtualenvs"/*/; do
    [[ -f "$venv/pyvenv.cfg" ]] || clean "$venv" "Orphan venv"
  done
}

clean_editors() {
  sec "Editors"
  
  for editor in Code Cursor Windsurf VSCodium; do
    [[ -d "$HOME/.config/$editor" ]] || continue
    for cache in CachedData Cache GPUCache "Code Cache"; do
      clean "$HOME/.config/$editor/$cache" "$editor $cache"
    done
  done
  
  for jb in "$HOME/.cache/JetBrains"/* "$HOME/.config/JetBrains"/*; do
    [[ -d "$jb" ]] || continue
    clean "$jb/caches" "$(basename "$jb") caches"
    clean "$jb/log" "$(basename "$jb") logs"
  done
}

clean_apps() {
  sec "Apps & misc"
  
  clean "$HOME/.factory/sessions" "Factory sessions"
  clean "$HOME/.factory/artifacts" "Factory artifacts"
  
  for cache in gstreamer-1.0 mesa_shader_cache tracker3 libdnf5 gnome-software; do
    clean "$HOME/.cache/$cache" "$cache"
  done
  
  for state_dir in "warnings" "less" "vimundo" "nvim/undo" "nvim/swap" "nvim/shada" "bash" "zsh"; do
    clean "$HOME/.local/state/$state_dir" "state: $state_dir"
  done
}

clean_browsers() {
  sec "Browsers"
  
  for ff in "$HOME/.mozilla/firefox"/*.default*/cache2 "$HOME/.mozilla/firefox"/*.default*/startupCache; do
    [[ -d "$ff" ]] && clean "$ff" "Firefox cache"
  done
  
  for chrome in "$HOME/.config/google-chrome" "$HOME/.config/chromium" "$HOME/.config/brave" "$HOME/.config/microsoft-edge"; do
    [[ -d "$chrome" ]] || continue
    clean "$chrome/Default/Cache" "$(basename "$chrome") cache"
    clean "$chrome/Default/Code Cache" "$(basename "$chrome") code cache"
    clean "$chrome/Default/GPUCache" "$(basename "$chrome") GPU cache"
  done
}

clean_flatpak() {
  has flatpak || return
  sec "Flatpak"
  
  run "Flatpak unused" flatpak uninstall --unused -y
  clean "$HOME/.cache/flatpak" "Flatpak cache"
  
  [[ -d "$HOME/.var/app" ]] || return
  local installed
  installed=$(flatpak list --app --columns=application 2>/dev/null || :)
  for app in "$HOME/.var/app"/*/; do
    [[ -d "$app" ]] || continue
    echo "$installed" | grep -qx "$(basename "$app")" || clean "$app" "Orphan: $(basename "$app")"
  done
}

clean_snap() {
  has snap || return
  sec "Snap"
  
  $DRY || snap list --all 2>/dev/null | awk '/disabled/{ print $1, $3 }' | while read -r name rev; do
    sudo snap remove "$name" --revision="$rev" &>/dev/null && ok "Snap: $name (rev $rev)"
  done
  
  [[ -d "$HOME/snap" ]] || return
  local installed
  installed=$(snap list 2>/dev/null | awk 'NR>1{ print $1 }' || :)
  for snap_dir in "$HOME/snap"/*/; do
    [[ -d "$snap_dir" ]] || continue
    local name
    name=$(basename "$snap_dir")
    [[ "$name" == ".cache" ]] && continue
    echo "$installed" | grep -qx "$name" || clean "$snap_dir" "Orphan: $name"
  done
}

clean_appimage() {
  sec "AppImages"
  for dir in "$HOME/AppImages" "$HOME/Applications" "$HOME/.local/bin"; do
    [[ -d "$dir" ]] || continue
    find "$dir" -maxdepth 1 \( -iname "*.appimage.zs-old" -o -iname "*.appimage.bak" \) 2>/dev/null | while read -r f; do
      clean "$f" "Old: $(basename "$f")"
    done
  done
}

scan_and_clean() {
  local title="$1" prompt="$2" min_size=$3; shift 3
  
  sec "$title"
  
  local -a paths=() sizes=()
  local total=0
  
  spin "Scanning..."
  
  if [[ $# -gt 0 ]]; then
    while IFS= read -r -d '' item; do
      [[ -e "$item" ]] || continue
      local size
      size=$(szk "$item")
      ((size < min_size)) && continue
      paths+=("$item")
      sizes+=("$size")
      ((total += size))
    done < <(find "$@" -print0 2>/dev/null)
  else
    while IFS= read -r -d '' item; do
      [[ -e "$item" ]] || continue
      local size
      size=$(szk "$item")
      ((size < min_size)) && continue
      paths+=("$item")
      sizes+=("$size")
      ((total += size))
    done
  fi
  
  unspin ok "Scan complete"
  
  [[ ${#paths[@]} -eq 0 ]] && ok "Nothing found" && return
  
  echo -e "Found ${L}${#paths[@]}${R} items ($(human "$total"))\n"
  
  for i in "${!paths[@]}"; do
    ((i >= 15)) && break
    printf "  ${G}●${R} %8s  %s\n" "$(human "${sizes[$i]}")" "$(basename "${paths[$i]}")"
  done
  ((${#paths[@]} > 15)) && echo -e "  ${DM}... and $((${#paths[@]} - 15)) more${R}"
  echo
  
  $DRY && info "Would clean ${#paths[@]} items ($(human "$total"))" && return
  
  if ! $AUTO; then
    read -rp "$prompt ${#paths[@]} items ($(human "$total"))? [y/N] " -n1 reply
    echo
    [[ ! "$reply" =~ ^[Yy]$ ]] && return
  fi
  
  echo
  local freed=0
  for i in "${!paths[@]}"; do
    rm -rf "${paths[$i]}" 2>/dev/null && ok "$(basename "${paths[$i]}") ($(human "${sizes[$i]}"))" && ((freed += sizes[i]))
  done
  echo -e "\n${G}Freed $(human "$freed")${R}"
}

purge_artifacts() {
  local -a bases=("$HOME/dev" "$HOME/Projects" "$HOME/GitHub" "$HOME/Code" "$HOME/www" "$HOME/Documents/GitHub" "$HOME/Documents/Projects")
  
  local -a dirs=()
  for base in "${bases[@]}"; do
    [[ -d "$base" ]] && dirs+=("$base")
  done
  [[ ${#dirs[@]} -eq 0 ]] && return
  
  local -a types=(node_modules target build dist .venv venv __pycache__ .next .nuxt .output .gradle .turbo .parcel-cache .angular .svelte-kit coverage obj .zig-cache)
  
  local -a find_expr=()
  local first=true
  for type in "${types[@]}"; do
    if $first; then
      find_expr+=(-name "$type")
      first=false
    else
      find_expr+=(-o -name "$type")
    fi
  done
  
  scan_and_clean "Project artifacts" "Clean" 1024 \
    "${dirs[@]}" -mindepth 2 -maxdepth 4 -type d \
    '(' "${find_expr[@]}" ')' -mtime +7
}

clean_installers() {
  local -a dirs=("$HOME/Downloads" "$HOME/Desktop")
  local -a existing=()
  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] && existing+=("$dir")
  done
  [[ ${#existing[@]} -eq 0 ]] && return
  
  local -a exts=(iso deb rpm AppImage tar.gz tar.xz tar.bz2 zip dmg pkg exe msi)
  
  local -a find_expr=()
  local first=true
  for ext in "${exts[@]}"; do
    if $first; then
      find_expr=(-iname "*.$ext")
      first=false
    else
      find_expr+=(-o -iname "*.$ext")
    fi
  done
  
  scan_and_clean "Installer files" "Remove" 10240 \
    "${existing[@]}" -maxdepth 2 -type f \
    '(' "${find_expr[@]}" ')'
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--dry-run) DRY=true ;;
    -y|--yes) AUTO=true ;;
    -p|--purge) PURGE=true ;;
    -i|--installers) INST=true ;;
    -h|--help) echo "Usage: $(basename "$0") [-d|--dry-run] [-y|--yes] [-p|--purge] [-i|--installers]"; exit 0 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
  shift
done

echo -e "${B}🚀 Cleanup${R}"
DISK_BEFORE=$(disk)
echo -e "Disk: ${DISK_BEFORE}"
$DRY && echo -e "${Y}[DRY RUN]${R}"

if ! $AUTO && ! $DRY; then
  echo -e "\n${Y}⚠️  This will delete caches and temporary files.${R}"
  read -rp "Proceed? [y/N] " -n1 reply
  echo
  [[ ! "$reply" =~ ^[Yy]$ ]] && exit 0
fi

if ! $DRY && (has dnf || has apt-get || has pacman || has zypper); then
  sudo -v && { while :; do sudo -v; sleep 50; done & SUDO_PID=$!; }
fi

clean_system
clean_containers
clean_dev
clean_editors
clean_apps
clean_browsers
clean_flatpak
clean_snap
clean_appimage

$PURGE && purge_artifacts
$INST && clean_installers

echo -e "\n${M}═══════════════════════════════════════${R}"
ok "Complete!"
echo -e "  Before: ${DISK_BEFORE}"
echo -e "  After:  $(disk)"
