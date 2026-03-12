#!/usr/bin/env bash
# update.sh - System & toolchain updater
set -uo pipefail

# ── Flags ─────────────────────────────────────────────────────────────────────
QUIET=false   # -q: suppress command output (spinner only)
SUDO_PID=""
SPIN_PID=""

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
skip()    { echo -e "  ${DM}–  $1 (not found)${R}"; }
warn()    { echo -e "  ${Y}⚠${R}  $1"; }
info()    { echo -e "  ${B}ℹ${R}  $1"; }
section() { echo -e "\n${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}\n${L}  $1${R}"; }

# ── Utility ───────────────────────────────────────────────────────────────────
has() { command -v "$1" &>/dev/null; }

# ── Spinner (used only in quiet mode) ─────────────────────────────────────────
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

# ── Run wrapper ───────────────────────────────────────────────────────────────
# In normal mode: prints a header, streams live output indented, then status.
# In quiet mode (-q): uses a spinner and suppresses output.
run() {
  local label="$1"; shift

  if $QUIET; then
    spin "$label"
    if "$@" &>/dev/null; then
      unspin ok "$label"
    else
      unspin fail "$label"
    fi
    return
  fi

  # Live mode: stream output with indentation
  echo -e "\n  ${DM}▶ ${label}${R}"
  echo -e "  ${DM}$(printf '%.0s─' {1..45})${R}"

  # Use a temp file to capture exit code across the pipeline subshell
  local tmp_exit
  tmp_exit=$(mktemp)
  { "$@" 2>&1; echo $? > "$tmp_exit"; } | sed 's/^/    /'
  local exit_code
  exit_code=$(<"$tmp_exit")
  rm -f "$tmp_exit"

  echo -e "  ${DM}$(printf '%.0s─' {1..45})${R}"
  if [[ "$exit_code" -eq 0 ]]; then
    ok "$label"
  else
    warn "Failed: $label (exit $exit_code)"
  fi
  return "$exit_code"
}

# ── Distro detection ──────────────────────────────────────────────────────────
get_distro() {
  if [[ ! -f /etc/os-release ]]; then
    echo "unknown"
    return
  fi
  # shellcheck disable=SC1091
  source /etc/os-release
  case "$ID" in
    fedora|rhel|centos|rocky|almalinux) echo "redhat" ;;
    ubuntu|debian|mint)                 echo "debian" ;;
    arch|manjaro|endeavouros)           echo "arch"   ;;
    opensuse*|sles)                     echo "suse"   ;;
    *)                                  echo "unknown" ;;
  esac
}

# ── Updaters ──────────────────────────────────────────────────────────────────

update_system() {
  section "System packages"
  local distro
  distro=$(get_distro)
  case "$distro" in
    redhat) run "DNF upgrade"    sudo dnf upgrade --refresh -y ;;
    debian) run "APT upgrade"    bash -c 'sudo apt update && sudo apt full-upgrade -y' ;;
    arch)   run "Pacman upgrade" sudo pacman -Syu --noconfirm ;;
    suse)   run "Zypper upgrade" sudo zypper dup -y ;;
    *)      warn "Unknown distro — skipping system packages" ;;
  esac
}

update_flatpak() {
  if ! has flatpak; then
    skip "flatpak"
    return
  fi
  section "Flatpak"
  run "Flatpak update" flatpak update -y
}

update_bun() {
  if ! has bun; then
    skip "bun"
    return
  fi
  section "Bun"
  run "bun upgrade" bun upgrade
}

update_pnpm() {
  if ! has pnpm; then
    skip "pnpm"
    return
  fi
  section "pnpm"
  run "pnpm self-update" pnpm self-update
}


update_uv() {
  if ! has uv; then
    skip "uv"
    return
  fi
  section "uv"
  run "uv self update" uv self update
}

update_pipx() {
  if ! has pipx; then
    skip "pipx"
    return
  fi
  section "pipx"
  run "pipx upgrade-all" pipx upgrade-all
}

update_rust() {
  if ! has rustup; then
    skip "rustup"
    return
  fi
  section "Rust (rustup)"
  run "rustup update" rustup update
}

update_go_tools() {
  if ! has go; then
    skip "go tools"
    return
  fi

  local gobin
  gobin="$(go env GOPATH)/bin"

  if [[ ! -d "$gobin" ]]; then
    skip "go tools (no GOPATH/bin)"
    return
  fi

  section "Go tools"

  local bin name modpath cmdpath
  while IFS= read -r bin; do
    name=$(basename "$bin")

    # Resolve the module path and the exact command path from build info
    modpath=$(go version -m "$bin" 2>/dev/null | awk '/^\s+mod/{ print $2; exit }')
    cmdpath=$(go version -m "$bin" 2>/dev/null | awk '/^\s+path/{ print $2; exit }')

    if [[ -z "$modpath" || -z "$cmdpath" ]]; then
      warn "$name — cannot resolve module/command path, skipping"
      continue
    fi

    run "$name" go install "${cmdpath}@latest"
  done < <(find "$gobin" -maxdepth 1 -type f -executable 2>/dev/null)
}

update_gh_extensions() {
  if ! has gh; then
    skip "gh extensions"
    return
  fi

  local count
  count=$(gh extension list 2>/dev/null | wc -l)

  if ((count == 0)); then
    skip "gh extensions (none installed)"
    return
  fi

  section "GitHub CLI extensions"
  run "gh extension upgrade --all" gh extension upgrade --all
}



update_docker() {
  if ! has docker; then
    skip "docker"
    return
  fi

  if ! docker ps &>/dev/null; then
    skip "docker (daemon not running)"
    return
  fi

  local images
  images=$(docker ps --format '{{.Image}}' 2>/dev/null)

  if [[ -z "$images" ]]; then
    skip "docker (no running containers)"
    return
  fi

  section "Docker (running container images)"

  local img
  while IFS= read -r img; do
    run "docker pull $img" docker pull "$img"
  done <<< "$images"
}

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

  -q, --quiet   Suppress command output (spinner only)
  -h, --help    Show this help message
EOF
}

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    -q|--quiet) QUIET=true ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

# ── Main ──────────────────────────────────────────────────────────────────────
echo -e "${B}🚀  update.sh${R} — System & toolchain updater"
echo -e "${DM}    $(date '+%Y-%m-%d %H:%M:%S')${R}"
$QUIET && info "Quiet mode — output suppressed"

# Prompt for sudo upfront so it's not buried in output
if has dnf || has apt || has pacman || has zypper; then
  echo -e "\n${Y}  sudo required for system packages:${R}"
  sudo -v || { warn "sudo authentication failed, system packages will be skipped"; }
  # Keep sudo alive in the background
  if sudo -n true 2>/dev/null; then
    while :; do sudo -v; sleep 50; done &
    SUDO_PID=$!
  fi
fi

update_system
update_flatpak
update_bun
update_pnpm
update_uv
update_pipx
update_rust
update_go_tools
update_gh_extensions
update_docker

echo -e "\n${M}═══════════════════════════════════════${R}"
ok "All done!"
