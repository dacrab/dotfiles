#!/usr/bin/env bash
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

# Map /etc/os-release ID to package manager family
distro() {
  source /etc/os-release
  case "${ID:-}" in fedora|rhel|centos|rocky|almalinux) echo "redhat";; ubuntu|debian|mint) echo "debian";; arch|manjaro|endeavouros) echo "arch";; opensuse*|sles) echo "suse";; *) echo "unknown";; esac
}

echo "=== update ==="
sudo -v

echo "  system ..."
case "$(distro)" in
  redhat) sudo dnf upgrade --refresh -y ;;
  debian) sudo apt update && sudo apt full-upgrade -y ;;
  arch) sudo pacman -Syu --noconfirm ;;
  suse) sudo zypper dup -y ;;
esac

echo "  runtimes ..."
has flatpak && flatpak update -y
has snap && sudo snap refresh
has bun && bun upgrade && bun update -g
has npm && npm update -g
has pnpm && pnpm update -g && pnpm self-update
has uv && uv self update
has pipx && pipx upgrade-all
has rustup && rustup update

echo "  cargo ..."
has cargo && cargo install-update -a

echo "  go tools ..."
has go && for p in golang.org/x/tools/gopls@latest honnef.co/go/tools/cmd/staticcheck@latest golang.org/x/vuln/cmd/govulncheck@latest; do
  go install "$p"
done

echo "  gh extensions ..."
has gh && gh extension upgrade --all

echo "  docker images ..."
has docker && docker ps -q && docker ps --format '{{.Image}}' | sort -u | while read -r img; do docker pull "$img"; done

echo "  git repos ..."
has git && [[ -d "$HOME/Documents/GitHub" ]] && find "$HOME/Documents/GitHub" -maxdepth 2 -name ".git" | while read -r g; do
  git -C "$(dirname "$g")" pull --ff-only
done

echo "✓ done"
