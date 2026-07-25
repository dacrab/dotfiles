#!/usr/bin/env bash
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

distro() {
  source /etc/os-release 2>/dev/null
  echo "${ID_LIKE:-$ID}"
}

echo "===== System Update ====="
START=$(date +%s)

sudo -v
case "$(distro)" in
  *fedora*|*rhel*) sudo dnf upgrade --refresh -y ;;
  *ubuntu*|*debian*) sudo apt update && sudo apt full-upgrade -y ;;
  *arch*) sudo pacman -Syu --noconfirm ;;
  *suse*) sudo zypper dup -y ;;
esac

has flatpak  && flatpak update -y || true
has snap     && sudo snap refresh
has bun      && bun upgrade && bun update -g
has npm      && npm update -g
has pnpm     && pnpm update -g && pnpm self-update
has uv       && uv self update
has pipx     && pipx upgrade-all
has rustup   && rustup update
has cargo    && cargo install-update -a 2>/dev/null || true
has gh       && gh extension upgrade --all
has fwupdmgr && sudo fwupdmgr refresh --no-metadata-check && sudo fwupdmgr update -y

if has go; then
  go install golang.org/x/tools/gopls@latest
  go install honnef.co/go/tools/cmd/staticcheck@latest
fi

if has docker && docker ps -q &>/dev/null; then
  docker ps --format '{{.Image}}' | sort -u | xargs -r docker pull
fi

if has git; then
  REPOS_DIR="${REPOS_DIR:-$HOME/Documents/GitHub}"
  [[ -d "$REPOS_DIR" ]] && find "$REPOS_DIR" -maxdepth 2 -name ".git" | while read -r g; do
    dir="$(dirname "$g")"
    git -C "$dir" pull --ff-only 2>/dev/null || true
  done
fi

echo "===== Done ($(( $(date +%s) - START ))s) ====="
