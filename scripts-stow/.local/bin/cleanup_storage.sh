#!/usr/bin/env bash
# cleanup_storage.sh v6.0.0 - System cleanup utility
set -uo pipefail

# ── Flags ─────────────────────────────────────────────────────────────────────
DRY=false
AUTO=false
PURGE=false
INST=false
SPIN_PID=""
SUDO_PID=""

# ── Colours (disabled if not a terminal) ──────────────────────────────────────
if [[ -t 1 && "${TERM:-dumb}" != "dumb" ]]; then
  G='\033[32m'   # green
  Y='\033[33m'   # yellow
  B='\033[34m'   # blue
  C='\033[36m'   # cyan
  M='\033[35m'   # magenta
  DM='\033[2m'   # dim
  R='\033[0m'    # reset
  L='\033[1m'    # bold
else
  G='' Y='' B='' C='' M='' DM='' R='' L=''
fi

# ── Cleanup trap ──────────────────────────────────────────────────────────────
cleanup_trap() {
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null
  [[ -n "$SUDO_PID" ]] && kill "$SUDO_PID" 2>/dev/null
  tput cnorm 2>/dev/null || :
}
trap cleanup_trap EXIT INT TERM

# ── Output helpers ────────────────────────────────────────────────────────────
ok()      { echo -e "  ${G}✔${R}  $1"; }
warn()    { echo -e "  ${Y}⚠${R}  $1"; }
info()    { echo -e "  ${B}ℹ${R}  $1"; }
section() { echo -e "\n${C}==> ${L}$1${R}"; }

# ── Utility helpers ───────────────────────────────────────────────────────────
has()  { command -v "$1" &>/dev/null; }
hdir() { [[ -d "$1" && -n "$(ls -A "$1" 2>/dev/null)" ]]; }
sz()   { du -sh "$1" 2>/dev/null | cut -f1 || echo 0; }
szk()  { du -sk "$1" 2>/dev/null | cut -f1 || echo 0; }
disk() { df -h / | awk 'NR==2{ print $3"/"$2" ("$5")" }'; }

human() {
  local k=$1
  if   ((k >= 1048576)); then echo "$((k / 1048576))G"
  elif ((k >= 1024));    then echo "$((k / 1024))M"
  else                        echo "${k}K"
  fi
}

# ── Spinner ───────────────────────────────────────────────────────────────────
spin() {
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
  tput civis 2>/dev/null || :
  while :; do
    printf "\r\033[K${DM}[%s]${R} %s" "${frames:i++%10:1}" "$1"
    sleep .08
  done &
  SPIN_PID=$!
}

unspin() {
  if [[ -n "$SPIN_PID" ]]; then
    kill "$SPIN_PID" 2>/dev/null
    wait "$SPIN_PID" 2>/dev/null || :
    SPIN_PID=""
  fi
  printf "\r\033[K"
  tput cnorm 2>/dev/null || :
  if [[ "$1" == ok ]]; then
    ok "$2"
  else
    warn "Failed: $2"
  fi
}

# ── Run wrappers ──────────────────────────────────────────────────────────────

# run: runs a command with a spinner, suppressing output
run() {
  local label="$1"; shift
  if $DRY; then
    info "Would run: $label"
    return 0
  fi
  spin "$label"
  if "$@" &>/dev/null; then
    unspin ok "$label"
  else
    unspin fail "$label"
  fi
}

# run_v: runs a command with visible output (no spinner)
run_v() {
  local label="$1"; shift
  if $DRY; then
    info "Would run: $label"
    return 0
  fi
  if "$@"; then
    ok "$label"
  else
    warn "Failed: $label"
  fi
}

# cdir: clean contents of a directory
cdir() {
  local dir="$1" label="${2:-$1}" size
  hdir "$dir" || return 0
  size=$(sz "$dir")
  [[ "$size" == "0" ]] && return 0
  if $DRY; then
    info "Would clean: $label ($size)"
    return 0
  fi
  if find "$dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null; then
    ok "Cleaned: $label ($size)"
  else
    warn "Failed: $label"
  fi
}

# rmp: remove a path entirely
rmp() {
  local target="$1" label="${2:-$1}" size
  [[ -e "$target" ]] || return 0
  size=$(sz "$target")
  [[ "$size" == "0" ]] && return 0
  if $DRY; then
    info "Would remove: $label ($size)"
    return 0
  fi
  if rm -rf "$target" 2>/dev/null; then
    ok "Removed: $label ($size)"
  else
    warn "Failed: $label"
  fi
}

# ── Clean sections ────────────────────────────────────────────────────────────

clean_system() {
  section "System packages"

  if has dnf; then
    run "DNF clean"      sudo dnf clean all -q
    run "DNF autoremove" sudo dnf autoremove -y -q
  fi

  if has apt-get; then
    run "APT clean"      sudo apt-get clean
    run "APT autoremove" sudo apt-get autoremove --purge -y
  fi

  if has pacman; then
    run "Pacman clean" sudo pacman -Sc --noconfirm
    local -a orphans
    mapfile -t orphans < <(pacman -Qdtq 2>/dev/null || :)
    if [[ ${#orphans[@]} -gt 0 ]]; then
      run "Pacman orphans" sudo pacman -Rns --noconfirm "${orphans[@]}"
    fi
  fi

  has zypper && run "Zypper clean" sudo zypper clean --all
  has yay    && run "Yay clean"    yay  -Sc --noconfirm
  has paru   && run "Paru clean"   paru -Sc --noconfirm

  has journalctl && run_v "Journal vacuum" sudo journalctl --vacuum-time=3d

  if has trash-empty; then
    if $DRY; then
      info "Would run: Trash"
    else
      spin "Trash"
      yes | trash-empty 7 &>/dev/null
      unspin ok "Trash"
    fi
  else
    cdir "$HOME/.local/share/Trash" "Trash"
  fi

  cdir "$HOME/.cache/thumbnails" "Thumbnails"
}

clean_containers() {
  section "Containers"

  if has docker && docker ps &>/dev/null; then
    run "Docker prune" docker system prune -f
  fi

  has podman && run "Podman prune" podman system prune -f
}

clean_dev() {
  section "Dev tools"

  has npm  && run "NPM cache"   npm cache clean --force
  has pnpm && run "PNPM prune"  pnpm store prune
  has yarn && run "Yarn cache"  yarn cache clean
  has bun  && cdir "$HOME/.bun/install/cache" "Bun cache"

  has pip3 && run "Pip cache" pip3 cache purge
  has uv   && run "UV cache"  uv cache clean
  has pipx && run "Pipx cache" pipx runpip --spec "" -- cache purge 2>/dev/null || :

  if has go; then
    run "Go modcache" go clean -modcache
    run "Go cache"    go clean -cache
  fi

  has dotnet && run "NuGet cache" dotnet nuget locals all --clear

  if hdir "$HOME/.cargo"; then
    cdir "$HOME/.cargo/registry/cache" "Cargo registry cache"
    cdir "$HOME/.cargo/git/db"         "Cargo git db"
  fi

  cdir "$HOME/.gradle/caches" "Gradle caches"
  cdir "$HOME/.gradle/daemon" "Gradle daemon"

  local tool
  for tool in node-gyp ms-playwright ms-playwright-go deno biome goimports gopls; do
    cdir "$HOME/.cache/$tool" "$tool cache"
  done

  # Orphaned virtualenvs
  if hdir "$HOME/.virtualenvs"; then
    local venv
    for venv in "$HOME/.virtualenvs"/*/; do
      [[ -f "$venv/pyvenv.cfg" ]] || rmp "$venv" "Orphan venv: $(basename "$venv")"
    done
  fi
}

clean_editors() {
  section "Editors"

  local editor cache_dir
  for editor in Code Cursor Windsurf VSCodium Antigravity Kiro; do
    [[ -d "$HOME/.config/$editor" ]] || continue
    for cache_dir in CachedData Cache GPUCache "Code Cache"; do
      cdir "$HOME/.config/$editor/$cache_dir" "$editor $cache_dir"
    done
  done

  local jb_dir
  for jb_dir in "$HOME/.cache/JetBrains"/* "$HOME/.config/JetBrains"/*; do
    [[ -d "$jb_dir" ]] || continue
    cdir "$jb_dir/caches" "$(basename "$jb_dir") caches"
    cdir "$jb_dir/log"    "$(basename "$jb_dir") logs"
  done
}

clean_apps() {
  section "Apps & misc caches"

  cdir "$HOME/.factory/sessions"  "Factory sessions"
  cdir "$HOME/.factory/artifacts" "Factory artifacts"

  local cache
  for cache in gstreamer-1.0 mesa_shader_cache tracker3 libdnf5 gnome-software; do
    cdir "$HOME/.cache/$cache" "$cache"
  done
}

clean_flatpak() {
  has flatpak || return
  section "Flatpak"

  run "Flatpak unused" flatpak uninstall --unused -y
  cdir "$HOME/.cache/flatpak" "Flatpak cache"

  [[ -d "$HOME/.var/app" ]] || return

  local installed app_id app_dir
  installed=$(flatpak list --app --columns=application 2>/dev/null || :)
  for app_dir in "$HOME/.var/app"/*/; do
    [[ -d "$app_dir" ]] || continue
    app_id=$(basename "$app_dir")
    echo "$installed" | grep -qx "$app_id" || rmp "$app_dir" "Orphan flatpak: $app_id"
  done
}

clean_snap() {
  has snap || return
  section "Snap"

  if ! $DRY; then
    snap list --all 2>/dev/null \
      | awk '/disabled/{ print $1, $3 }' \
      | while read -r snap_name revision; do
          if sudo snap remove "$snap_name" --revision="$revision" &>/dev/null; then
            ok "Snap: $snap_name (rev $revision)"
          fi
        done
  fi

  [[ -d "$HOME/snap" ]] || return

  local installed snap_dir snap_name
  installed=$(snap list 2>/dev/null | awk 'NR>1{ print $1 }' || :)
  for snap_dir in "$HOME/snap"/*/; do
    [[ -d "$snap_dir" ]] || continue
    snap_name=$(basename "$snap_dir")
    [[ "$snap_name" == ".cache" ]] && continue
    echo "$installed" | grep -qx "$snap_name" || rmp "$snap_dir" "Orphan snap: $snap_name"
  done
}

clean_appimage() {
  section "AppImages"

  local search_dir file
  for search_dir in "$HOME/AppImages" "$HOME/Applications" "$HOME/.local/bin"; do
    [[ -d "$search_dir" ]] || continue
    while IFS= read -r -d '' file; do
      rmp "$file" "Old: $(basename "$file")"
    done < <(find "$search_dir" -maxdepth 1 \
               \( -iname "*.appimage.zs-old" -o -iname "*.appimage.bak" \) \
               -print0 2>/dev/null)
  done
}

# ── Optional: project artifact scanner ───────────────────────────────────────
purge_artifacts() {
  section "Project artifacts"

  local -a artifact_types=(
    node_modules target build dist .venv venv __pycache__
    .next .nuxt .output .gradle .turbo .parcel-cache
    .angular .svelte-kit coverage obj .zig-cache
  )
  local -a base_dirs=(
    "$HOME/dev" "$HOME/Projects" "$HOME/GitHub" "$HOME/Code"
    "$HOME/www" "$HOME/Documents/GitHub" "$HOME/Documents/Projects"
  )

  # Parallel arrays to track found artifacts
  local -a paths=() sizes=() ages=() projects=()
  local total=0

  spin "Scanning for artifacts..."

  local base_dir artifact_type dir rel depth age_days project size_k
  for base_dir in "${base_dirs[@]}"; do
    [[ -d "$base_dir" ]] || continue
    for artifact_type in "${artifact_types[@]}"; do
      while IFS= read -r dir; do
        [[ -z "$dir" || ! -d "$dir" ]] && continue

        # Relative path from base
        rel="${dir#"$base_dir"/}"
        [[ "$rel" == "$dir" ]] && continue

        # Must be at least 1 level deep inside a project
        depth=$(echo "$rel" | tr -cd '/' | wc -c)
        ((depth < 1)) && continue

        # Skip nested artifact dirs (e.g. node_modules inside node_modules)
        [[ "$rel" == *"$artifact_type/$artifact_type"*      ]] && continue
        [[ "$rel" == *"$artifact_type/"*"/$artifact_type"   ]] && continue

        # Skip small dirs
        size_k=$(szk "$dir")
        ((size_k < 1024)) && continue

        age_days=$(( ( $(date +%s) - $(stat -c %Y "$dir" 2>/dev/null || echo 0) ) / 86400 ))
        project=$(echo "$rel" | cut -d/ -f1)

        paths+=("$dir")
        sizes+=("$size_k")
        ages+=("$age_days")
        projects+=("$project")
        ((total += size_k))

      done < <(find "$base_dir" -mindepth 2 -maxdepth 4 -type d -name "$artifact_type" 2>/dev/null)
    done
  done

  unspin ok "Scan complete"

  if [[ ${#paths[@]} -eq 0 ]]; then
    ok "No artifacts found"
    return
  fi

  echo -e "Found ${L}${#paths[@]}${R} artifacts ($(human "$total"))\n"

  # Sort by size descending → sorted indices
  local -a sorted_indices=()
  while IFS= read -r idx; do
    sorted_indices+=("$idx")
  done < <(
    for idx in "${!sizes[@]}"; do echo "$idx ${sizes[$idx]}"; done \
      | sort -k2 -rn \
      | cut -d' ' -f1
  )

  # Determine how many to display
  local term_lines max_display=20
  term_lines=$(tput lines 2>/dev/null || echo 20)
  local display=$(( term_lines - 10 ))
  ((display < 5))  && display=5
  ((display > max_display)) && display=max_display

  # Display artifacts; auto-select those older than 7 days
  local -a selected=()
  local idx m is_old
  for idx in "${sorted_indices[@]:0:$display}"; do
    if ((ages[idx] < 7)); then
      m=" ${DM}(recent)${R}"
      is_old=false
    else
      m=""
      is_old=true
      selected+=("$idx")
    fi

    if $is_old; then
      printf "  ${G}●${R} %-20s %8s  %-15s%s\n" \
        "${projects[$idx]}" "$(human "${sizes[$idx]}")" "$(basename "${paths[$idx]}")" "$m"
    else
      printf "  ${DM}○ %-20s %8s  %-15s%s${R}\n" \
        "${projects[$idx]}" "$(human "${sizes[$idx]}")" "$(basename "${paths[$idx]}")" "$m"
    fi
  done

  local remaining=$(( ${#sorted_indices[@]} - display ))
  ((remaining > 0)) && echo -e "  ${DM}... and $remaining more${R}"

  if [[ ${#selected[@]} -eq 0 ]]; then
    echo -e "\n${Y}All artifacts are recent (<7d), skipping${R}"
    return
  fi

  # Sum selected sizes
  local selected_total=0
  for idx in "${selected[@]}"; do
    ((selected_total += sizes[idx]))
  done
  echo

  if $DRY; then
    info "Would clean ${#selected[@]} artifacts ($(human "$selected_total"))"
    return
  fi

  if ! $AUTO; then
    read -rp "Clean ${#selected[@]} old artifacts ($(human "$selected_total"))? [y/N] " -n1 reply
    echo
    [[ ! "$reply" =~ ^[Yy]$ ]] && return
  fi

  echo
  local freed=0
  for idx in "${selected[@]}"; do
    if rm -rf "${paths[$idx]}" 2>/dev/null; then
      ok "${projects[$idx]}/$(basename "${paths[$idx]}") ($(human "${sizes[$idx]}"))"
      ((freed += sizes[idx]))
    else
      warn "Failed: ${projects[$idx]}"
    fi
  done

  echo -e "\n${G}Freed $(human "$freed")${R}"
}

# ── Optional: installer file scanner ─────────────────────────────────────────
clean_installers() {
  section "Installer files"

  local -a extensions=(iso deb rpm AppImage tar.gz tar.xz tar.bz2 zip dmg pkg exe msi)
  local -a search_dirs=("$HOME/Downloads" "$HOME/Desktop")

  local -a files=() sizes=() names=()
  local total=0

  spin "Scanning for installers..."

  local dir ext file size_k
  for dir in "${search_dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    for ext in "${extensions[@]}"; do
      while IFS= read -r file; do
        [[ -z "$file" || ! -f "$file" ]] && continue
        size_k=$(szk "$file")
        ((size_k < 10240)) && continue  # skip files smaller than 10 MB
        files+=("$file")
        sizes+=("$size_k")
        names+=("$(basename "$file")")
        ((total += size_k))
      done < <(find "$dir" -maxdepth 2 -type f -iname "*.$ext" 2>/dev/null)
    done
  done

  unspin ok "Scan complete"

  if [[ ${#files[@]} -eq 0 ]]; then
    ok "No installers found"
    return
  fi

  echo -e "Found ${L}${#files[@]}${R} installers ($(human "$total"))\n"

  # Sort by size descending
  local -a sorted_indices=()
  while IFS= read -r idx; do
    sorted_indices+=("$idx")
  done < <(
    for idx in "${!sizes[@]}"; do echo "$idx ${sizes[$idx]}"; done \
      | sort -k2 -rn \
      | cut -d' ' -f1
  )

  local term_lines
  term_lines=$(tput lines 2>/dev/null || echo 20)
  local display=$(( term_lines - 10 ))
  ((display < 5))  && display=5
  ((display > 15)) && display=15

  local idx
  for idx in "${sorted_indices[@]:0:$display}"; do
    printf "  ${G}●${R} %8s  %s\n" "$(human "${sizes[$idx]}")" "${names[$idx]}"
  done

  local remaining=$(( ${#sorted_indices[@]} - display ))
  ((remaining > 0)) && echo -e "  ${DM}... and $remaining more${R}"
  echo

  if $DRY; then
    info "Would remove ${#files[@]} installers ($(human "$total"))"
    return
  fi

  if ! $AUTO; then
    read -rp "Remove ${#files[@]} installers ($(human "$total"))? [y/N] " -n1 reply
    echo
    [[ ! "$reply" =~ ^[Yy]$ ]] && return
  fi

  echo
  local freed=0
  for idx in "${sorted_indices[@]}"; do
    if rm -f "${files[$idx]}" 2>/dev/null; then
      ok "${names[$idx]} ($(human "${sizes[$idx]}"))"
      ((freed += sizes[idx]))
    else
      warn "Failed: ${names[$idx]}"
    fi
  done

  echo -e "\n${G}Freed $(human "$freed")${R}"
}

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

  -d, --dry-run     Preview changes without deleting anything
  -y, --yes         Skip confirmation prompts
  -p, --purge       Also scan and clean project artifacts (node_modules, etc.)
  -i, --installers  Also scan and clean old installer files in Downloads
  -h, --help        Show this help message
EOF
}

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--dry-run)    DRY=true  ;;
    -y|--yes)        AUTO=true ;;
    -p|--purge)      PURGE=true ;;
    -i|--installers) INST=true ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

# ── Main ──────────────────────────────────────────────────────────────────────
echo -e "${B}🚀 Cleanup v6.0.0${R}"
DISK_BEFORE=$(disk)
echo -e "Disk usage: ${DISK_BEFORE}"
$DRY && echo -e "${Y}[DRY RUN] No files will be deleted.${R}"

# Confirm before proceeding (unless --yes or --dry-run)
if ! $AUTO && ! $DRY; then
  echo -e "\n${Y}⚠️  This will delete caches and temporary files.${R}"
  read -rp "Proceed? [y/N] " -n1 reply
  echo
  [[ ! "$reply" =~ ^[Yy]$ ]] && exit 0
fi

# Keep sudo alive in the background if system package managers are present
if ! $DRY && (has dnf || has apt-get || has pacman || has zypper); then
  sudo -v && {
    while :; do sudo -v; sleep 50; done &
    SUDO_PID=$!
  }
fi

clean_system
clean_containers
clean_dev
clean_editors
clean_apps
clean_flatpak
clean_snap
clean_appimage

$PURGE && purge_artifacts
$INST  && clean_installers

DISK_AFTER=$(disk)
echo -e "\n${M}═══════════════════════════════════════${R}"
ok "Complete!"
echo -e "  Before: ${DISK_BEFORE}"
echo -e "  After:  ${DISK_AFTER}"
