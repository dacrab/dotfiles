#!/usr/bin/env bash
# cleanup_storage.sh v5.1.0 - System cleanup utility
set -uo pipefail

VERSION="5.1.0"
DRY=false AUTO=false
SPIN_PID="" SUDO_PID=""

# Colors
if [[ -t 1 && "${TERM:-dumb}" != "dumb" ]]; then
    GRN='\033[32m' YLW='\033[33m' BLU='\033[34m' CYN='\033[36m' MAG='\033[35m' DIM='\033[2m' RST='\033[0m'
else GRN='' YLW='' BLU='' CYN='' MAG='' DIM='' RST=''; fi

cleanup() { [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null; [[ -n "$SUDO_PID" ]] && kill "$SUDO_PID" 2>/dev/null; tput cnorm 2>/dev/null ||:; }
trap cleanup EXIT INT TERM

ok() { echo -e "${GRN}[OK]${RST} $1"; }
warn() { echo -e "${YLW}[WARN]${RST} $1"; }
info() { echo -e "${BLU}[INFO]${RST} $1"; }
section() { echo -e "\n${CYN}$1${RST}"; }
has() { command -v "$1" &>/dev/null; }
hdir() { [[ -d "$1" && -n "$(ls -A "$1" 2>/dev/null)" ]]; }
dsize() { du -sh "$1" 2>/dev/null | cut -f1 || echo "0"; }
disk() { df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}'; }

spin_start() {
    local m="$1" f='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
    tput civis 2>/dev/null ||:
    while :; do printf "\r${DIM}[%s]${RST} %s" "${f:i++%10:1}" "$m"; sleep 0.08; done &
    SPIN_PID=$!
}

spin_stop() {
    [[ -n "$SPIN_PID" ]] && { kill "$SPIN_PID" 2>/dev/null; wait "$SPIN_PID" 2>/dev/null ||:; SPIN_PID=""; }
    printf "\r\033[K"; tput cnorm 2>/dev/null ||:
    [[ "$1" == "ok" ]] && ok "$2" || warn "Failed: $2"
}

run() {
    local n="$1"; shift
    $DRY && { info "Would run: $n"; return 0; }
    spin_start "$n"
    "$@" &>/dev/null && spin_stop ok "$n" || spin_stop fail "$n"
}

run_v() {
    local n="$1"; shift
    $DRY && { info "Would run: $n"; return 0; }
    "$@" && ok "$n" || warn "Failed: $n"
}

clean_dir() {
    local d="$1" n="${2:-$1}" s
    hdir "$d" || return 0; s=$(dsize "$d"); [[ "$s" == "0" ]] && return 0
    $DRY && { info "Would clean: $n ($s)"; return 0; }
    find "$d" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null && ok "Cleaned: $n ($s)" || warn "Failed: $n"
}

rm_path() {
    local t="$1" n="${2:-$1}" s
    [[ -e "$t" ]] || return 0; s=$(dsize "$t"); [[ "$s" == "0" ]] && return 0
    $DRY && { info "Would remove: $n ($s)"; return 0; }
    rm -rf "$t" 2>/dev/null && ok "Removed: $n ($s)" || warn "Failed: $n"
}

clean_system() {
    section "📦 System"
    has dnf && { run "DNF clean" sudo dnf clean all -q; run "DNF autoremove" sudo dnf autoremove -y -q; }
    has apt-get && { run "APT clean" sudo apt-get clean; run "APT autoremove" sudo apt-get autoremove --purge -y; }
    if has pacman; then
        run "Pacman clean" sudo pacman -Sc --noconfirm
        local -a orph; mapfile -t orph < <(pacman -Qdtq 2>/dev/null ||:)
        [[ ${#orph[@]} -gt 0 ]] && run "Pacman orphans" sudo pacman -Rns --noconfirm "${orph[@]}"
    fi
    has zypper && run "Zypper clean" sudo zypper clean --all
    has yay && run "Yay clean" yay -Sc --noconfirm
    has paru && run "Paru clean" paru -Sc --noconfirm
    has journalctl && run_v "Journal vacuum" sudo journalctl --vacuum-time=3d
    if has trash-empty; then
        $DRY && info "Would run: Trash" || { spin_start "Trash"; yes | trash-empty 7 &>/dev/null; spin_stop ok "Trash"; }
    else clean_dir "$HOME/.local/share/Trash" "Trash"; fi
    clean_dir "$HOME/.cache/thumbnails" "Thumbnails"
}

clean_containers() {
    section "🐳 Containers"
    has docker && docker ps &>/dev/null && run "Docker prune" docker system prune -f
    has podman && run "Podman prune" podman system prune -f
}

clean_dev() {
    section "🛠️ Dev Tools"
    has npm && { run "NPM cache" npm cache clean --force; rm_path "$HOME/.npm/_cacache" "NPM cache"; }
    has pnpm && run "PNPM prune" pnpm store prune
    has yarn && run "Yarn cache" yarn cache clean
    has bun && clean_dir "$HOME/.bun/install/cache" "Bun cache"
    has pip3 && { run "Pip cache" pip3 cache purge; clean_dir "$HOME/.cache/pip" "Pip cache"; }
    has uv && { run "UV cache" uv cache clean; clean_dir "$HOME/.cache/uv" "UV cache"; }
    has go && { run "Go modcache" go clean -modcache; clean_dir "$HOME/.cache/go-build" "Go build"; }
    has dotnet && run "NuGet clean" dotnet nuget locals all --clear
    hdir "$HOME/.cargo" && { clean_dir "$HOME/.cargo/registry/cache" "Cargo cache"; clean_dir "$HOME/.cargo/git/db" "Cargo git"; }
    clean_dir "$HOME/.gradle/caches" "Gradle caches"
    clean_dir "$HOME/.gradle/daemon" "Gradle daemon"
    for c in node-gyp ms-playwright deno biome goimports gopls; do clean_dir "$HOME/.cache/$c" "$c"; done
}

clean_editors() {
    section "📝 Editors"
    for e in Code Cursor Windsurf VSCodium Antigravity Kiro; do
        [[ -d "$HOME/.config/$e" ]] || continue
        for c in CachedData Cache GPUCache "Code Cache"; do clean_dir "$HOME/.config/$e/$c" "$e $c"; done
    done
    for jb in "$HOME/.cache/JetBrains"/* "$HOME/.config/JetBrains"/*; do
        [[ -d "$jb" ]] || continue; local n; n=$(basename "$jb")
        clean_dir "$jb/caches" "$n caches"; clean_dir "$jb/log" "$n logs"
    done
}

clean_apps() {
    section "🧹 App Caches"
    clean_dir "$HOME/.factory/sessions" "Factory sessions"
    clean_dir "$HOME/.factory/artifacts" "Factory artifacts"
    for c in gstreamer-1.0 mesa_shader_cache tracker3 libdnf5 gnome-software; do clean_dir "$HOME/.cache/$c" "$c"; done
}

clean_flatpak() {
    has flatpak || return 0
    section "📦 Flatpak"
    run "Flatpak unused" flatpak uninstall --unused -y
    clean_dir "$HOME/.cache/flatpak" "Flatpak cache"
    [[ -d "$HOME/.var/app" ]] || return 0
    local inst; inst=$(flatpak list --app --columns=application 2>/dev/null ||:)
    for d in "$HOME/.var/app"/*/; do
        [[ -d "$d" ]] || continue; local id; id=$(basename "$d")
        echo "$inst" | grep -qx "$id" || rm_path "$d" "Orphan: $id"
    done
}

clean_snap() {
    has snap || return 0
    section "📦 Snap"
    $DRY || snap list --all 2>/dev/null | awk '/disabled/{print $1,$3}' | while read -r s r; do
        sudo snap remove "$s" --revision="$r" &>/dev/null && ok "Snap: $s (rev $r)"
    done
    [[ -d "$HOME/snap" ]] || return 0
    local inst; inst=$(snap list 2>/dev/null | awk 'NR>1{print $1}' ||:)
    for d in "$HOME/snap"/*/; do
        [[ -d "$d" ]] || continue; local n; n=$(basename "$d"); [[ "$n" == ".cache" ]] && continue
        echo "$inst" | grep -qx "$n" || rm_path "$d" "Orphan: $n"
    done
}

clean_appimage() {
    section "📦 AppImages"
    for d in "$HOME/AppImages" "$HOME/Applications" "$HOME/.local/bin"; do
        [[ -d "$d" ]] || continue
        while IFS= read -r -d '' f; do rm_path "$f" "Old: $(basename "$f")"; done \
            < <(find "$d" -maxdepth 1 \( -iname "*.appimage.zs-old" -o -iname "*.appimage.bak" \) -print0 2>/dev/null)
    done
}

usage() { echo "Usage: $(basename "$0") [-d|--dry-run] [-y|--yes] [-h|--help]"; }

while [[ $# -gt 0 ]]; do
    case $1 in -d|--dry-run) DRY=true;; -y|--yes) AUTO=true;; -h|--help) usage; exit 0;; *) echo "Unknown: $1"; usage; exit 1;; esac; shift
done

echo -e "${BLU}🚀 Cleanup v${VERSION}${RST}"
BEFORE=$(disk); echo "Disk: $BEFORE"
$DRY && echo -e "${YLW}[DRY RUN]${RST}"

if ! $AUTO && ! $DRY; then
    echo -e "${YLW}⚠️  This will delete caches and temp files.${RST}"
    read -rp "Proceed? [y/N] " -n1 r; echo; [[ ! "$r" =~ ^[Yy]$ ]] && exit 0
    (has dnf || has apt-get || has pacman || has zypper) && sudo -v && { while :; do sudo -v; sleep 50; done & SUDO_PID=$!; }
fi

clean_system; clean_containers; clean_dev; clean_editors; clean_apps; clean_flatpak; clean_snap; clean_appimage

echo -e "\n${MAG}═══════════════════════════════════════${RST}"
ok "Complete!"; AFTER=$(disk); echo "Before: $BEFORE"; echo "After:  $AFTER"
