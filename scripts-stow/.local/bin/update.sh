#!/usr/bin/env bash
set -uo pipefail

HAS_GUM=false; command -v gum &>/dev/null && HAS_GUM=true

has() { command -v "$1" &>/dev/null; }

distro() {
  source /etc/os-release
  case "${ID:-}" in fedora|rhel|centos|rocky|almalinux) echo "redhat";; ubuntu|debian|mint) echo "debian";; arch|manjaro|endeavouros) echo "arch";; opensuse*|sles) echo "suse";; *) echo "unknown";; esac
}

# ── Styling ──
hdr()  { $HAS_GUM && gum style --border double --padding "0 2" --foreground 212 --bold --width 60 --align center "$1" || echo "===== $1 ====="; }
title(){ echo; $HAS_GUM && gum style --foreground 39 --bold --padding "0 0" "  $1" && gum style --foreground 39 --faint "  ──────────────────────────────────" || echo "--- $1 ---"; }
inf()  { $HAS_GUM && gum log -t "15:04:05" -l info "$1" || echo "  [$(date +%T)] ✓ $1"; }
warn() { $HAS_GUM && gum log -t "15:04:05" -l warn "$1" || echo "  ⚠ $1"; }
fail() { $HAS_GUM && gum log -t "15:04:05" -l error "$1" || echo "  ✗ $1"; }

START=$(date +%s)

echo
hdr "System Update"
echo

# ──────────────────────────────────────────────
title "System Packages"
sudo -v
case "$(distro)" in
  redhat) sudo dnf upgrade --refresh -y ;;
  debian) sudo apt update && sudo apt full-upgrade -y ;;
  arch)   sudo pacman -Syu --noconfirm ;;
  suse)   sudo zypper dup -y ;;
esac
inf "Packages updated"

# ──────────────────────────────────────────────
title "Spicetify"
if has spicetify; then
  echo "  → spicetify"
  spicetify update
fi

# ──────────────────────────────────────────────
title "Runtimes"
if has flatpak; then
  echo "  → flatpak"
  flatpak update --appstream 2>/dev/null || true
  flatpak update -y || warn "flatpak had non-fatal errors"
fi
if has snap; then echo "  → snap"; sudo snap refresh; fi
if has bun; then echo "  → bun"; bun upgrade && bun update -g; fi
if has npm; then echo "  → npm"; npm update -g; fi
if has pnpm; then echo "  → pnpm"; pnpm update -g && pnpm self-update; fi
if has uv; then echo "  → uv"; uv self update; fi
if has pipx; then echo "  → pipx"; pipx upgrade-all; fi
if has rustup; then echo "  → rustup"; rustup update; fi
inf "Runtimes updated"

# ──────────────────────────────────────────────
title "Cargo"
if has cargo; then
  if ! cargo install-update --version &>/dev/null; then
    echo "  → installing cargo-update..."
    cargo install cargo-update
  fi
  cargo install-update -a
  inf "Cargo tools updated"
fi

# ──────────────────────────────────────────────
title "Go"
if has go; then
  for p in golang.org/x/tools/gopls@latest honnef.co/go/tools/cmd/staticcheck@latest golang.org/x/vuln/cmd/govulncheck@latest; do
    echo "  → go install $p"
    go install "$p"
  done
  inf "Go tools updated"
fi

# ──────────────────────────────────────────────
title "GitHub CLI"
if has gh; then
  gh extension upgrade --all
  inf "GH extensions updated"
fi

# ──────────────────────────────────────────────
title "Docker"
if has docker && docker ps -q &>/dev/null; then
  echo "  → pulling running images..."
  docker ps --format '{{.Image}}' | sort -u | while read -r img; do
    docker pull "$img"
  done
  inf "Docker images pulled"
fi

# ──────────────────────────────────────────────
title "Git Repos"
if has git && [[ -d "$HOME/Documents/GitHub" ]]; then
  find "$HOME/Documents/GitHub" -maxdepth 2 -name ".git" | while read -r g; do
    dir="$(dirname "$g")"
    name="$(basename "$dir")"
    branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    upstream="$(git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null)"
    echo "  → $name ($branch)"

    if [[ -z "$upstream" ]]; then
      echo "    ↪ no upstream tracking, skipping"
      continue
    fi
    if ! git -C "$dir" diff --quiet; then
      echo "    ↪ uncommitted changes, stashing..."
      git -C "$dir" stash push -m "auto-stash $(date +%Y%m%d)" --quiet
    fi
    if git -C "$dir" pull --ff-only; then
      echo "    ✓ updated"
    else
      echo "    ✗ pull failed"
    fi
    [[ -f "$dir/.gitmodules" ]] && git -C "$dir" submodule update --recursive
  done
  inf "Git repos updated"
fi

# ──────────────────────────────────────────────
END=$(date +%s)
ELAPSED=$((END - START))
echo
hdr "Update complete! (${ELAPSED}s)"
echo
