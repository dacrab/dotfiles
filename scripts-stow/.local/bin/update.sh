#!/usr/bin/env bash
# ============================================
# update — update the system, runtimes, and tools.
# Safe no-op for anything that isn't installed.
# ============================================
set -uo pipefail

has() { command -v "$1" &>/dev/null; }
run() { has "$1" && "$@"; }

# ----- Tunables (override via env) -----
REPOS_DIR="${REPOS_DIR:-$HOME/Documents/GitHub}"

distro() {
  source /etc/os-release 2>/dev/null
  echo "${ID_LIKE:-${ID:-}}"
}

has sudo && sudo -v

# ----- System packages -----
case "$(distro)" in
  *fedora*|*rhel*)   sudo dnf upgrade --refresh -y ;;
  *ubuntu*|*debian*) sudo apt update && sudo apt full-upgrade -y ;;
  *arch*)            sudo pacman -Syu --noconfirm ;;
  *suse*)            sudo zypper dup -y ;;
esac

has flatpak  && flatpak update -y
has snap     && sudo snap refresh
has fwupdmgr && sudo fwupdmgr refresh --no-metadata-check && sudo fwupdmgr update -y

# ----- Language runtimes & package managers -----
run rustup update

run go install golang.org/x/tools/gopls@latest
run go install honnef.co/go/tools/cmd/staticcheck@latest

run bun upgrade && run bun update -g
run npm update -g
run pnpm update -g && run pnpm self-update
run uv self update && run uv tool upgrade --all
run pipx upgrade-all
{ run cargo install-update -a; } 2>/dev/null

# ----- CLI tools -----
run gh extension upgrade --all

# ----- Containers -----
if has docker && docker ps -q &>/dev/null; then
  declare -A seen
  while IFS= read -r img; do
    ((seen[$img])) || { docker pull "$img" >/dev/null 2>&1 || true; seen[$img]=1; }
  done < <(docker ps --format '{{.Image}}')
fi

# ----- Git repos -----
if has git; then
  if [[ -d "$REPOS_DIR" ]]; then
    shopt -s nullglob dotglob
    for repo in "$REPOS_DIR"/*/.git "$REPOS_DIR"/*/*/.git; do
      git -C "${repo%/.git}" pull --ff-only 2>/dev/null || true
    done
  fi
fi