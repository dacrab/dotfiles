#!/usr/bin/env bash
# update - update system, runtimes, and tools.
set -uo pipefail

has() { command -v "$1" &>/dev/null; }
REPOS_DIR="${REPOS_DIR:-$HOME/Documents/GitHub}"

# system packages
# shellcheck source=/dev/null
source /etc/os-release 2>/dev/null
case "${ID_LIKE:-$ID}" in
  *fedora*|*rhel*)   sudo dnf upgrade --refresh -y ;;
  *ubuntu*|*debian*) sudo apt update && sudo apt full-upgrade -y ;;
  *arch*)            sudo pacman -Syu --noconfirm ;;
  *suse*)            sudo zypper dup -y ;;
esac

has flatpak  && flatpak update -y
has snap     && sudo snap refresh
has fwupdmgr && sudo fwupdmgr refresh --no-metadata-check
has fwupdmgr && sudo fwupdmgr update -y

# runtimes and package managers
has rustup && rustup update
has go     && go install golang.org/x/tools/gopls@latest && go install honnef.co/go/tools/cmd/staticcheck@latest
has bun    && bun upgrade && bun update -g
has npm    && npm update -g
has pnpm   && pnpm update -g && pnpm self-update
has uv     && uv self update && uv tool upgrade --all
has pipx   && pipx upgrade-all
has cargo-install-update && cargo-install-update -a

# cli tools
has gh && gh extension upgrade --all

# refresh images of running containers
if has docker && docker ps -q &>/dev/null; then
  docker ps --format '{{.Image}}' | sort -u | xargs -r docker pull
fi

# pull git repos
if has git && [[ -d "$REPOS_DIR" ]]; then
  find "$REPOS_DIR" -maxdepth 3 -name .git -exec git -C '{}/..' pull --ff-only \;
fi