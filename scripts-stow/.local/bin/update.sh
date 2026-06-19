#!/usr/bin/env bash
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

distro() {
  source /etc/os-release 2>/dev/null
  case "${ID:-}" in fedora|rhel|centos|rocky|almalinux) echo "redhat";; ubuntu|debian|mint) echo "debian";; arch|manjaro|endeavouros) echo "arch";; opensuse*|sles) echo "suse";; *) echo "unknown";; esac
}

q() { "$@" &>/dev/null; }

echo "=== update ==="
sudo -v

case "$(distro)" in
  redhat) sudo dnf upgrade --refresh -y ;;
  debian) sudo apt update && sudo apt full-upgrade -y ;;
  arch) sudo pacman -Syu --noconfirm ;;
  suse) sudo zypper dup -y ;;
esac

echo "  runtimes ..."
has flatpak && q flatpak update -y
has bun && q bun upgrade
has pnpm && q pnpm self-update
has uv && q uv self update
has pipx && pipx upgrade-all | grep -v "^  "
has rustup && rustup update 2>/dev/null | grep -v "^info:" || true

if has supabase; then
  v=$(curl -fsSL https://api.github.com/repos/supabase/cli/releases/latest | jq -r '.tag_name' | sed 's/^v//')
  cur=$(supabase --version | grep -oE '[\d.]+')
  [[ -n "$v" && "$cur" != "$v" ]] && curl -fsSL "https://github.com/supabase/cli/releases/download/v${v}/supabase_${v}_linux_amd64.tar.gz" | sudo tar -xz -C /usr/local/bin supabase
fi

echo "  go tools ..."
has go && for p in golang.org/x/tools/gopls@latest honnef.co/go/tools/cmd/staticcheck@latest golang.org/x/vuln/cmd/govulncheck@latest; do
  q go install "$p"
done

echo "  gh extensions ..."
has gh && q gh extension upgrade --all

echo "  docker images ..."
has docker && docker ps &>/dev/null && docker ps --format '{{.Image}}' | sort -u | while read -r img; do q docker pull "$img"; done

echo "  git repos ..."
has git && [[ -d "$HOME/Documents/GitHub" ]] && find "$HOME/Documents/GitHub" -maxdepth 2 -name ".git" | while read -r g; do
  q git -C "$(dirname "$g")" pull --ff-only
done

echo "✓ done"
