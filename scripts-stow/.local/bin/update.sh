#!/usr/bin/env bash
set -uo pipefail

QUIET=false
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
skip() { echo -e "  ${DM}–  $1${R}"; }
warn() { echo -e "  ${Y}⚠${R}  $1"; }
info() { echo -e "  ${B}ℹ${R}  $1"; }
sec()  { echo -e "\n${C}${L}$1${R}"; }
has()  { command -v "$1" &>/dev/null; }

spin() {
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
  tput civis 2>/dev/null || :
  while :; do
    printf "\r${DM}[%s]${R} %s..." "${frames:i++%10:1}" "$1"
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
  if $QUIET; then
    spin "$label"
    if "$@" &>/dev/null; then
      unspin ok "$label"
    else
      unspin fail "$label"
    fi
  else
    echo -e "\n  ${DM}▶ ${label}${R}"
    "$@" 2>&1 | sed 's/^/    /'
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
      ok "$label"
    else
      warn "$label"
    fi
  fi
}

get_distro() {
  [[ ! -f /etc/os-release ]] && echo "unknown" && return
  # shellcheck disable=SC1091
  source /etc/os-release
  case "$ID" in
    fedora|rhel|centos|rocky|almalinux) echo "redhat" ;;
    ubuntu|debian|mint) echo "debian" ;;
    arch|manjaro|endeavouros) echo "arch" ;;
    opensuse*|sles) echo "suse" ;;
    *) echo "unknown" ;;
  esac
}

update_system() {
  sec "System packages"
  case "$(get_distro)" in
    redhat) run "DNF upgrade" sudo dnf upgrade --refresh -y ;;
    debian) run "APT upgrade" bash -c 'sudo apt update && sudo apt full-upgrade -y' ;;
    arch) run "Pacman upgrade" sudo pacman -Syu --noconfirm ;;
    suse) run "Zypper upgrade" sudo zypper dup -y ;;
    *) warn "Unknown distro" ;;
  esac
}

update_tool() {
  local name=$1; shift
  has "$name" || { skip "$name"; return; }
  sec "$name"
  run "$*" "$@"
}

update_go_tools() {
  has go || { skip "go tools"; return; }
  local gobin
  gobin="$(go env GOPATH)/bin"
  [[ ! -d "$gobin" ]] && skip "go tools" && return
  
  sec "Go tools"
  while IFS= read -r bin; do
    local name modpath cmdpath curver latestver
    name=$(basename "$bin")
    modpath=$(go version -m "$bin" 2>/dev/null | awk '/^\s+mod/{ print $2; exit }')
    cmdpath=$(go version -m "$bin" 2>/dev/null | awk '/^\s+path/{ print $2; exit }')
    curver=$(go version -m "$bin" 2>/dev/null | awk '/^\s+mod/{ print $3; exit }')
    
    [[ -z "$modpath" || -z "$cmdpath" || -z "$curver" ]] && warn "$name" && continue
    
    latestver=$(GOFLAGS='' go list -m -json "${modpath}@latest" 2>/dev/null | awk -F'"' '/"Version"/{ print $4; exit }')
    [[ -z "$latestver" ]] && warn "$name" && continue
    [[ "$curver" == "$latestver" ]] && ok "$name ${DM}${curver}${R}" && continue
    
    info "$name ${DM}${curver} → ${latestver}${R}"
    run "$name" go install "${cmdpath}@latest"
  done < <(find "$gobin" -maxdepth 1 -type f -executable 2>/dev/null)
}

update_supabase() {
  has supabase || { skip "supabase"; return; }
  sec "Supabase CLI"
  local latest current
  latest=$(curl -fsSL https://api.github.com/repos/supabase/cli/releases/latest | grep -m1 '"tag_name"' | grep -oP 'v\K[\d.]+')
  current=$(supabase --version 2>/dev/null | grep -oP '[\d.]+')
  [[ "$current" == "$latest" ]] && ok "supabase ${DM}${current}${R}" && return
  info "supabase ${DM}${current} → ${latest}${R}"
  case "$(get_distro)" in
    redhat) run "install supabase rpm" sudo rpm -U "https://github.com/supabase/cli/releases/download/v${latest}/supabase_${latest}_linux_amd64.rpm" ;;
    debian) run "install supabase deb" bash -c "curl -fsSL https://github.com/supabase/cli/releases/download/v${latest}/supabase_${latest}_linux_amd64.deb -o /tmp/supabase.deb && sudo dpkg -i /tmp/supabase.deb" ;;
    *)
      run "install supabase binary" bash -c "curl -fsSL https://github.com/supabase/cli/releases/download/v${latest}/supabase_${latest}_linux_amd64.tar.gz | sudo tar -xz -C /usr/local/bin supabase"
      ;;
  esac
}

update_gh_ext() {
  has gh || { skip "gh extensions"; return; }
  (($(gh extension list 2>/dev/null | wc -l) == 0)) && skip "gh extensions" && return
  sec "GitHub CLI extensions"
  run "gh extension upgrade" gh extension upgrade --all
}

update_docker() {
  has docker || { skip "docker"; return; }
  docker ps &>/dev/null || { skip "docker"; return; }
  local images
  images=$(docker ps --format '{{.Image}}' 2>/dev/null)
  [[ -z "$images" ]] && skip "docker" && return
  
  sec "Docker images"
  while IFS= read -r img; do
    run "pull $img" docker pull "$img"
  done <<< "$images"
}

update_git() {
  has git || { skip "git"; return; }
  local dir="$HOME/Documents/GitHub"
  [[ ! -d "$dir" ]] && skip "git repos" && return
  
  sec "Git repositories"
  local repos
  repos=$(find "$dir" -maxdepth 2 -name ".git" 2>/dev/null | sed 's|/.git$||')
  [[ -z "$repos" ]] && skip "git repos" && return
  
  while IFS= read -r repo; do
    if (cd "$repo" && git pull --ff-only) &>/dev/null; then
      ok "$(basename "$repo")"
    else
      warn "$(basename "$repo")"
    fi
  done <<< "$repos"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -q|--quiet) QUIET=true ;;
    -h|--help) echo "Usage: $(basename "$0") [-q|--quiet] [-h|--help]"; exit 0 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
  shift
done

echo -e "${B}🚀 update.sh${R} ${DM}$(date '+%Y-%m-%d %H:%M:%S')${R}"
$QUIET && info "Quiet mode"

if has dnf || has apt || has pacman || has zypper; then
  echo -e "\n${Y}sudo required:${R}"
  sudo -v || warn "sudo failed"
  if sudo -n true 2>/dev/null; then
    while :; do sudo -v; sleep 50; done &
    SUDO_PID=$!
  fi
fi

update_system
update_supabase
update_tool flatpak flatpak update -y
update_tool bun bun upgrade
update_tool pnpm pnpm self-update
update_tool uv uv self update
update_tool pipx pipx upgrade-all
update_tool rustup rustup update
update_go_tools
update_gh_ext
update_docker
update_git

echo -e "\n${M}═══════════════════════════════════════${R}"
ok "All done!"
