#!/usr/bin/env bash
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

distro() {
  source /etc/os-release
  case "${ID:-}" in
    fedora|rhel|centos|rocky|almalinux) echo "redhat";;
    ubuntu|debian|mint) echo "debian";;
    arch|manjaro|endeavouros) echo "arch";;
    opensuse*|sles) echo "suse";;
    *) echo "unknown";;
  esac
}

echo "===== System Update ====="
START=$(date +%s)

sudo -v
case "$(distro)" in
  redhat) sudo dnf upgrade --refresh -y ;;
  debian) sudo apt update && sudo apt full-upgrade -y ;;
  arch)   sudo pacman -Syu --noconfirm ;;
  suse)   sudo zypper dup -y ;;
esac

has spicetify && {
  spotify_flatpak="$(flatpak info --show-location com.spotify.Client 2>/dev/null)/files/extra/share/spotify"
  if [[ -d "$spotify_flatpak" ]]; then
    sudo chmod a+wr "$spotify_flatpak"
    sudo chmod a+wr -R "$spotify_flatpak/Apps"
  fi
  "$HOME/.spicetify/spicetify" upgrade && "$HOME/.spicetify/spicetify" restore backup apply
}
has flatpak  && { flatpak update --appstream; flatpak update -y; } || true
has snap     && sudo snap refresh
has bun      && (bun upgrade; bun update -g)
has npm      && npm update -g
has pnpm     && (pnpm update -g; pnpm self-update)
has uv       && uv self update
has pipx     && pipx upgrade-all
has rustup   && rustup update

if has cargo; then
  if has cargo-install-update; then cargo install-update -a; fi
fi

if has go; then
  for p in golang.org/x/tools/gopls@latest honnef.co/go/tools/cmd/staticcheck@latest; do
    go install "$p"
  done
fi

has gh && gh extension upgrade --all

has fwupdmgr && sudo fwupdmgr refresh --no-metadata-check && sudo fwupdmgr update -y

if has docker && docker ps -q &>/dev/null; then
  docker ps --format '{{.Image}}' | sort -u | xargs -r docker pull
fi

REPOS_DIR="${REPOS_DIR:-$HOME/Documents/GitHub}"
if has git && [[ -d "$REPOS_DIR" ]]; then
  find "$REPOS_DIR" -maxdepth 2 -name ".git" | while read -r g; do
    dir="$(dirname "$g")"
    upstream="$(git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null)"
    [[ -z "$upstream" ]] && continue
    stashed=false
    ! git -C "$dir" diff --quiet && git -C "$dir" stash push -m "auto-stash $(date +%Y%m%d)" --quiet && stashed=true
    git -C "$dir" pull --ff-only
    $stashed && git -C "$dir" stash pop --quiet
    [[ -f "$dir/.gitmodules" ]] && git -C "$dir" submodule update --recursive
  done
fi

echo "===== Done ($(( $(date +%s) - START ))s) ====="
