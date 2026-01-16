#!/usr/bin/env bash
# cleanup_storage.sh v5.3.0 - System cleanup utility
set -uo pipefail

DRY=false AUTO=false PURGE=false INST=false
SPIN_PID="" SUDO_PID=""

[[ -t 1 && "${TERM:-dumb}" != "dumb" ]] && { G='\033[32m' Y='\033[33m' B='\033[34m' C='\033[36m' M='\033[35m' DM='\033[2m' R='\033[0m' L='\033[1m'; } || { G='' Y='' B='' C='' M='' DM='' R='' L=''; }

trap '[[ -n "$SPIN_PID" ]] && kill $SPIN_PID 2>/dev/null; [[ -n "$SUDO_PID" ]] && kill $SUDO_PID 2>/dev/null; tput cnorm 2>/dev/null ||:' EXIT INT TERM

ok() { echo -e "${G}[OK]${R} $1"; }
warn() { echo -e "${Y}[WARN]${R} $1"; }
info() { echo -e "${B}[INFO]${R} $1"; }
section() { echo -e "\n${C}$1${R}"; }
has() { command -v "$1" &>/dev/null; }
hdir() { [[ -d "$1" && -n "$(ls -A "$1" 2>/dev/null)" ]]; }
sz() { du -sh "$1" 2>/dev/null | cut -f1 || echo 0; }
szk() { du -sk "$1" 2>/dev/null | cut -f1 || echo 0; }
disk() { df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}'; }
human() { local k=$1; ((k>=1048576)) && echo "$((k/1048576))G" || { ((k>=1024)) && echo "$((k/1024))M" || echo "${k}K"; }; }

spin() { local f='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0; tput civis 2>/dev/null||:; while :; do printf "\r\033[K${DM}[%s]${R} %s" "${f:i++%10:1}" "$1"; sleep .08; done & SPIN_PID=$!; }
unspin() { [[ -n "$SPIN_PID" ]] && { kill $SPIN_PID 2>/dev/null; wait $SPIN_PID 2>/dev/null||:; SPIN_PID=""; }; printf "\r\033[K"; tput cnorm 2>/dev/null||:; [[ "$1" == ok ]] && ok "$2" || warn "Failed: $2"; }

run() { local n="$1"; shift; $DRY && { info "Would run: $n"; return 0; }; spin "$n"; "$@" &>/dev/null && unspin ok "$n" || unspin fail "$n"; }
run_v() { local n="$1"; shift; $DRY && { info "Would run: $n"; return 0; }; "$@" && ok "$n" || warn "Failed: $n"; }

cdir() { local d="$1" n="${2:-$1}" s; hdir "$d" || return 0; s=$(sz "$d"); [[ "$s" == "0" ]] && return 0; $DRY && { info "Would clean: $n ($s)"; return 0; }; find "$d" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null && ok "Cleaned: $n ($s)" || warn "Failed: $n"; }
rmp() { local t="$1" n="${2:-$1}" s; [[ -e "$t" ]] || return 0; s=$(sz "$t"); [[ "$s" == "0" ]] && return 0; $DRY && { info "Would remove: $n ($s)"; return 0; }; rm -rf "$t" 2>/dev/null && ok "Removed: $n ($s)" || warn "Failed: $n"; }

clean_system() {
    section "📦 System"
    has dnf && { run "DNF clean" sudo dnf clean all -q; run "DNF autoremove" sudo dnf autoremove -y -q; }
    has apt-get && { run "APT clean" sudo apt-get clean; run "APT autoremove" sudo apt-get autoremove --purge -y; }
    has pacman && { run "Pacman clean" sudo pacman -Sc --noconfirm; local -a o; mapfile -t o < <(pacman -Qdtq 2>/dev/null||:); [[ ${#o[@]} -gt 0 ]] && run "Pacman orphans" sudo pacman -Rns --noconfirm "${o[@]}"; }
    has zypper && run "Zypper clean" sudo zypper clean --all
    has yay && run "Yay clean" yay -Sc --noconfirm
    has paru && run "Paru clean" paru -Sc --noconfirm
    has journalctl && run_v "Journal vacuum" sudo journalctl --vacuum-time=3d
    has trash-empty && { $DRY && info "Would run: Trash" || { spin "Trash"; yes|trash-empty 7 &>/dev/null; unspin ok "Trash"; }; } || cdir "$HOME/.local/share/Trash" "Trash"
    cdir "$HOME/.cache/thumbnails" "Thumbnails"
}

clean_containers() { section "🐳 Containers"; has docker && docker ps &>/dev/null && run "Docker prune" docker system prune -f; has podman && run "Podman prune" podman system prune -f; }

clean_dev() {
    section "🛠️ Dev Tools"
    has npm && { run "NPM cache" npm cache clean --force; rmp "$HOME/.npm/_cacache" "NPM cache"; }
    has pnpm && run "PNPM prune" pnpm store prune; has yarn && run "Yarn cache" yarn cache clean; has bun && cdir "$HOME/.bun/install/cache" "Bun"
    has pip3 && { run "Pip cache" pip3 cache purge; cdir "$HOME/.cache/pip" "Pip"; }; has uv && { run "UV cache" uv cache clean; cdir "$HOME/.cache/uv" "UV"; }
    has go && { run "Go modcache" go clean -modcache; cdir "$HOME/.cache/go-build" "Go build"; }; has dotnet && run "NuGet" dotnet nuget locals all --clear
    hdir "$HOME/.cargo" && { cdir "$HOME/.cargo/registry/cache" "Cargo cache"; cdir "$HOME/.cargo/git/db" "Cargo git"; }
    cdir "$HOME/.gradle/caches" "Gradle caches"; cdir "$HOME/.gradle/daemon" "Gradle daemon"
    for c in node-gyp ms-playwright deno biome goimports gopls; do cdir "$HOME/.cache/$c" "$c"; done
}

clean_editors() {
    section "📝 Editors"
    for e in Code Cursor Windsurf VSCodium Antigravity Kiro; do [[ -d "$HOME/.config/$e" ]] && for c in CachedData Cache GPUCache "Code Cache"; do cdir "$HOME/.config/$e/$c" "$e $c"; done; done
    for j in "$HOME/.cache/JetBrains"/* "$HOME/.config/JetBrains"/*; do [[ -d "$j" ]] && { cdir "$j/caches" "$(basename "$j") caches"; cdir "$j/log" "$(basename "$j") logs"; }; done
}

clean_apps() { section "🧹 Apps"; cdir "$HOME/.factory/sessions" "Factory sessions"; cdir "$HOME/.factory/artifacts" "Factory artifacts"; for c in gstreamer-1.0 mesa_shader_cache tracker3 libdnf5 gnome-software; do cdir "$HOME/.cache/$c" "$c"; done; }

clean_flatpak() {
    has flatpak || return; section "📦 Flatpak"; run "Flatpak unused" flatpak uninstall --unused -y; cdir "$HOME/.cache/flatpak" "Flatpak cache"
    [[ -d "$HOME/.var/app" ]] || return; local i; i=$(flatpak list --app --columns=application 2>/dev/null||:)
    for d in "$HOME/.var/app"/*/; do [[ -d "$d" ]] && { local id; id=$(basename "$d"); echo "$i"|grep -qx "$id" || rmp "$d" "Orphan: $id"; }; done
}

clean_snap() {
    has snap || return; section "📦 Snap"; $DRY || snap list --all 2>/dev/null|awk '/disabled/{print $1,$3}'|while read -r s r; do sudo snap remove "$s" --revision="$r" &>/dev/null && ok "Snap: $s (rev $r)"; done
    [[ -d "$HOME/snap" ]] || return; local i; i=$(snap list 2>/dev/null|awk 'NR>1{print $1}'||:)
    for d in "$HOME/snap"/*/; do [[ -d "$d" ]] && { local n; n=$(basename "$d"); [[ "$n" != ".cache" ]] && echo "$i"|grep -qx "$n" || rmp "$d" "Orphan: $n"; }; done
}

clean_appimage() { section "📦 AppImages"; for d in "$HOME/AppImages" "$HOME/Applications" "$HOME/.local/bin"; do [[ -d "$d" ]] && while IFS= read -r -d '' f; do rmp "$f" "Old: $(basename "$f")"; done < <(find "$d" -maxdepth 1 \( -iname "*.appimage.zs-old" -o -iname "*.appimage.bak" \) -print0 2>/dev/null); done; }

purge_artifacts() {
    section "🗑️ Project Artifacts"
    local -a F=() S=() A=() P=() T=(node_modules target build dist .venv venv __pycache__ .next .nuxt .output .gradle .turbo .parcel-cache .angular .svelte-kit coverage obj .zig-cache)
    local BD=("$HOME/dev" "$HOME/Projects" "$HOME/GitHub" "$HOME/Code" "$HOME/www" "$HOME/Documents/GitHub" "$HOME/Documents/Projects") tot=0
    spin "Scanning..."; for b in "${BD[@]}"; do [[ -d "$b" ]] || continue; for t in "${T[@]}"; do while IFS= read -r d; do
        [[ -z "$d" || ! -d "$d" ]] && continue; local r="${d#"$b"/}"; [[ "$r" == "$d" ]] && continue; local dp; dp=$(echo "$r"|tr -cd /|wc -c); ((dp<1)) && continue
        [[ "$r" == *"$t/$t"* || "$r" == *"$t/"*"/$t" ]] && continue; local k a p; k=$(szk "$d"); ((k<1024)) && continue
        a=$((($(date +%s)-$(stat -c %Y "$d" 2>/dev/null||echo 0))/86400)); p=$(echo "$r"|cut -d/ -f1)
        F+=("$d"); S+=("$k"); A+=("$a"); P+=("$p"); ((tot+=k))
    done < <(find "$b" -mindepth 2 -maxdepth 4 -type d -name "$t" 2>/dev/null); done; done
    [[ -n "$SPIN_PID" ]] && { kill $SPIN_PID 2>/dev/null; wait $SPIN_PID 2>/dev/null||:; SPIN_PID=""; }; printf "\r\033[K"; tput cnorm 2>/dev/null||:
    [[ ${#F[@]} -eq 0 ]] && { ok "No artifacts found"; return; }
    echo -e "Found ${L}${#F[@]}${R} artifacts ($(human $tot))\n"
    local -a si=(); while IFS= read -r i; do si+=("$i"); done < <(for i in "${!S[@]}"; do echo "$i ${S[$i]}"; done|sort -k2 -rn|cut -d' ' -f1)
    local -a sel=(); local th=$(($(tput lines 2>/dev/null||echo 20)-10)); ((th<5)) && th=5; ((th>20)) && th=20
    for i in "${si[@]:0:$th}"; do local m="" s=true; ((A[$i]<7)) && { m=" ${DM}(recent)${R}"; s=false; }
        $s && { sel+=("$i"); printf "  ${G}●${R} %-20s %8s  %-15s%s\n" "${P[$i]}" "$(human ${S[$i]})" "$(basename "${F[$i]}")" "$m"; } || printf "  ${DM}○ %-20s %8s  %-15s%s${R}\n" "${P[$i]}" "$(human ${S[$i]})" "$(basename "${F[$i]}")" "$m"
    done; ((${#si[@]}>th)) && echo -e "  ${DM}... and $((${#si[@]}-th)) more${R}"
    [[ ${#sel[@]} -eq 0 ]] && { echo -e "\n${Y}All recent (<7d), skipping${R}"; return; }
    local sk=0; for i in "${sel[@]}"; do ((sk+=S[$i])); done; echo
    $DRY && { info "Would clean ${#sel[@]} artifacts ($(human $sk))"; return; }
    $AUTO || { read -rp "Clean ${#sel[@]} old artifacts ($(human $sk))? [y/N] " -n1 r; echo; [[ ! "$r" =~ ^[Yy]$ ]] && return; }
    echo; local ck=0; for i in "${sel[@]}"; do rm -rf "${F[$i]}" 2>/dev/null && { ok "${P[$i]}/$(basename "${F[$i]}") ($(human ${S[$i]}))"; ((ck+=S[$i])); } || warn "Failed: ${P[$i]}"; done
    echo -e "\n${G}Freed $(human $ck)${R}"
}

clean_installers() {
    section "📥 Installers"
    local -a F=() S=() N=() X=(iso deb rpm AppImage tar.gz tar.xz tar.bz2 zip dmg pkg exe msi) D=("$HOME/Downloads" "$HOME/Desktop") tot=0
    spin "Scanning..."
    for d in "${D[@]}"; do [[ -d "$d" ]] || continue; for x in "${X[@]}"; do while IFS= read -r f; do
        [[ -z "$f" || ! -f "$f" ]] && continue; local k; k=$(szk "$f"); ((k<10240)) && continue
        F+=("$f"); S+=("$k"); N+=("$(basename "$f")"); ((tot+=k))
    done < <(find "$d" -maxdepth 2 -type f -iname "*.$x" 2>/dev/null); done; done
    [[ -n "$SPIN_PID" ]] && { kill $SPIN_PID 2>/dev/null; wait $SPIN_PID 2>/dev/null||:; SPIN_PID=""; }; printf "\r\033[K"; tput cnorm 2>/dev/null||:
    [[ ${#F[@]} -eq 0 ]] && { ok "No installers found"; return; }
    echo -e "Found ${L}${#F[@]}${R} installers ($(human $tot))\n"
    local -a si=(); while IFS= read -r i; do si+=("$i"); done < <(for i in "${!S[@]}"; do echo "$i ${S[$i]}"; done|sort -k2 -rn|cut -d' ' -f1)
    local th=$(($(tput lines 2>/dev/null||echo 20)-10)); ((th<5)) && th=5; ((th>15)) && th=15
    for i in "${si[@]:0:$th}"; do printf "  ${G}●${R} %8s  %s\n" "$(human ${S[$i]})" "${N[$i]}"; done
    ((${#si[@]}>th)) && echo -e "  ${DM}... and $((${#si[@]}-th)) more${R}"
    echo; $DRY && { info "Would remove ${#F[@]} installers ($(human $tot))"; return; }
    $AUTO || { read -rp "Remove ${#F[@]} installers ($(human $tot))? [y/N] " -n1 r; echo; [[ ! "$r" =~ ^[Yy]$ ]] && return; }
    echo; local ck=0; for i in "${si[@]}"; do rm -f "${F[$i]}" 2>/dev/null && { ok "${N[$i]} ($(human ${S[$i]}))"; ((ck+=S[$i])); } || warn "Failed: ${N[$i]}"; done
    echo -e "\n${G}Freed $(human $ck)${R}"
}

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
  -d, --dry-run     Preview changes
  -y, --yes         Skip prompts
  -p, --purge       Clean project artifacts (node_modules, target, etc)
  -i, --installers  Clean old installer files in Downloads
  -h, --help        Show help
EOF
}

while [[ $# -gt 0 ]]; do case $1 in -d|--dry-run)DRY=true;;-y|--yes)AUTO=true;;-p|--purge)PURGE=true;;-i|--installers)INST=true;;-h|--help)usage;exit 0;;*)echo "Unknown: $1";usage;exit 1;;esac;shift;done

echo -e "${B}🚀 Cleanup v5.3.0${R}"; BEF=$(disk); echo "Disk: $BEF"; $DRY && echo -e "${Y}[DRY RUN]${R}"
if ! $AUTO && ! $DRY; then echo -e "${Y}⚠️  This will delete caches and temp files.${R}"; read -rp "Proceed? [y/N] " -n1 r; echo; [[ ! "$r" =~ ^[Yy]$ ]] && exit 0
    (has dnf||has apt-get||has pacman||has zypper) && sudo -v && { while :; do sudo -v; sleep 50; done & SUDO_PID=$!; }; fi

clean_system; clean_containers; clean_dev; clean_editors; clean_apps; clean_flatpak; clean_snap; clean_appimage
$PURGE && purge_artifacts; $INST && clean_installers

echo -e "\n${M}═══════════════════════════════════════${R}"; ok "Complete!"; AFT=$(disk); echo "Before: $BEF"; echo "After:  $AFT"
