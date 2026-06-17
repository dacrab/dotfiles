#!/usr/bin/env bash
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

distro() {
  source /etc/os-release 2>/dev/null
  case "${ID:-}" in fedora|rhel|centos|rocky|almalinux) echo "redhat";; ubuntu|debian|mint) echo "debian";; arch|manjaro|endeavouros) echo "arch";; opensuse*|sles) echo "suse";; *) echo "unknown";; esac
}

echo "=== update ==="
sudo -v

case "$(distro)" in
  redhat) sudo dnf upgrade --refresh -y ;;
  debian) sudo apt update && sudo apt full-upgrade -y ;;
  arch) sudo pacman -Syu --noconfirm ;;
  suse) sudo zypper dup -y ;;
esac

has flatpak && flatpak update -y
has bun && bun upgrade
has pnpm && pnpm self-update
has uv && uv self update
has pipx && pipx upgrade-all
has rustup && rustup update

if has supabase; then
  v=$(curl -fsSL https://api.github.com/repos/supabase/cli/releases/latest | jq -r '.tag_name' | sed 's/^v//')
  cur=$(supabase --version | grep -oE '[\d.]+')
  [[ -n "$v" && "$cur" != "$v" ]] && curl -fsSL "https://github.com/supabase/cli/releases/download/v${v}/supabase_${v}_linux_amd64.tar.gz" | sudo tar -xz -C /usr/local/bin supabase
fi

has gh && gh extension upgrade --all

has docker && docker ps &>/dev/null && docker ps --format '{{.Image}}' | sort -u | while read -r img; do docker pull "$img"; done

if has go; then
  go clean -modcache 2>/dev/null
  go clean -cache 2>/dev/null
  gobin=$(go env GOPATH)/bin
  if [[ -d "$gobin" ]]; then
    find "$gobin" -maxdepth 1 -type f -executable 2>/dev/null | while read -r b; do
      p=$(go version -m "$b" 2>/dev/null | awk '/^\s+path/{print $2; exit}')
      [[ -n "$p" ]] && go install "${p}@latest"
    done
  fi
fi

has git && [[ -d "$HOME/Documents/GitHub" ]] && find "$HOME/Documents/GitHub" -maxdepth 2 -name ".git" | while read -r g; do
  (cd "$(dirname "$g")" && git pull --ff-only)
done

echo "✓ done"
