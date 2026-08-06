#!/usr/bin/env bash
# ============================================
# update — update the system, runtimes, and tools.
# Safe no-op for anything that isn't installed.
# ============================================
set -uo pipefail

has() { command -v "$1" &>/dev/null; }
run() { has "$1" && "$@"; }

distro() {
  source /etc/os-release 2>/dev/null
  echo "${ID_LIKE:-${ID:-}}"
}

has sudo && sudo -v

# ============================================
# System packages
# ============================================
case "$(distro)" in
  *fedora*|*rhel*)      sudo dnf upgrade --refresh -y ;;
  *ubuntu*|*debian*)    sudo apt update && sudo apt full-upgrade -y ;;
  *arch*)               sudo pacman -Syu --noconfirm ;;
  *suse*)               sudo zypper dup -y ;;
esac

has flatpak  && flatpak update -y
has snap     && sudo snap refresh
has fwupdmgr && sudo fwupdmgr refresh --no-metadata-check && sudo fwupdmgr update -y

# ============================================
# Language runtimes & package managers
# ============================================
run rustup update

run go install golang.org/x/tools/gopls@latest
run go install honnef.co/go/tools/cmd/staticcheck@latest

run bun upgrade && run bun update -g
run npm update -g
run pnpm update -g && run pnpm self-update
run uv self update && run uv tool upgrade --all
run pipx upgrade-all
run cargo install-update -a

# ============================================
# CLI tools
# ============================================
run gh extension upgrade --all

# ============================================
# Containers
# ============================================
if has docker && docker ps -q &>/dev/null; then
  docker ps --format '{{.Image}}' | sort -u | xargs -r docker pull
fi

# ============================================
# Git repos
# ============================================
if has git; then
  REPOS_DIR="${REPOS_DIR:-$HOME/Documents/GitHub}"
  [[ -d "$REPOS_DIR" ]] && find "$REPOS_DIR" -maxdepth 2 -name ".git" | while read -r g; do
    git -C "$(dirname "$g")" pull --ff-only 2>/dev/null || true
  done
fi
