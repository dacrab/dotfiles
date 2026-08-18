#!/usr/bin/env bash
# ============================================
# update — update the system, runtimes, and tools.
# Safe no-op for anything that isn't installed.
# Firmware updates are opt-in via --firmware.
# ============================================
set -uo pipefail

has() { command -v "$1" &>/dev/null; }

# ----- Tunables (override via env) -----
REPOS_DIR="${REPOS_DIR:-$HOME/Documents/GitHub}"

DRY_RUN=0
FIRMWARE=0

usage() {
  cat <<'EOF'
Usage: update [OPTIONS]

Update system packages, runtimes and tools. Anything not installed is
skipped. Firmware (fwupd) updates are opt-in.

  -n, --dry-run   print what would be updated, change nothing
  -f, --firmware  also apply fwupd firmware updates
  -h, --help      show this help
EOF
}

while (($#)); do
  case "$1" in
    -n|--dry-run) DRY_RUN=1 ;;
    -f|--firmware) FIRMWARE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "update: unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

# Run $@ when its command is installed, honoring dry-run.
run() {
  has "$1" || return 1
  if ((DRY_RUN)); then
    printf '  [dry-run] %s\n' "$*"
    return
  fi
  "$@"
}

distro() {
  source /etc/os-release 2>/dev/null
  echo "${ID_LIKE:-${ID:-}}"
}

if ((!DRY_RUN)); then
  has sudo && sudo -v
fi

# ----- System packages -----
case "$(distro)" in
  *fedora*|*rhel*)   run sudo dnf upgrade --refresh -y ;;
  *ubuntu*|*debian*) run sudo apt update && run sudo apt full-upgrade -y ;;
  *arch*)            run sudo pacman -Syu --noconfirm ;;
  *suse*)            run sudo zypper dup -y ;;
esac

run flatpak update -y
run sudo snap refresh
run sudo fwupdmgr refresh --no-metadata-check
if ((FIRMWARE)); then
  run sudo fwupdmgr update -y
fi

# ----- Language runtimes & package managers -----
run rustup update

run go install golang.org/x/tools/gopls@latest
run go install honnef.co/go/tools/cmd/staticcheck@latest

run bun upgrade && run bun update -g
run npm update -g
run pnpm update -g && run pnpm self-update
run uv self update && run uv tool upgrade --all
run pipx upgrade-all
{ run cargo-install-update -a; } 2>/dev/null

# ----- CLI tools -----
run gh extension upgrade --all

# ----- Containers: refresh images of running containers -----
if has docker; then
  if ((DRY_RUN)); then
    printf '  [dry-run] docker pull images of running containers\n'
  elif docker ps -q &>/dev/null; then
    declare -A seen
    while IFS= read -r img; do
      ((seen[$img])) || { docker pull "$img" >/dev/null 2>&1 || true; seen[$img]=1; }
    done < <(docker ps --format '{{.Image}}')
  fi
fi

# ----- Git repos -----
if has git && [[ -d "$REPOS_DIR" ]]; then
  if ((DRY_RUN)); then
    printf '  [dry-run] git pull --ff-only in %s\n' "$REPOS_DIR"
  else
    shopt -s nullglob dotglob
    for repo in "$REPOS_DIR"/*/.git "$REPOS_DIR"/*/*/.git; do
      git -C "${repo%/.git}" pull --ff-only 2>/dev/null || true
    done
    shopt -u nullglob dotglob
  fi
fi

if ((DRY_RUN)); then
  echo "Dry run — nothing was updated."
fi