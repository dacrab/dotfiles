#!/bin/bash

# System Cleanup Utility - Cross-platform Linux cleanup for development environments

VERSION="3.0.0"
LOG_FILE="/tmp/cleanup_storage.log"
DRY_RUN=false
AUTO_CONFIRM=false
DISK_USAGE_BEFORE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Logging helpers
_log() {
    local level="$1" color="$2" msg="$3"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${color}[${level}]${NC} $msg"
    echo "[$timestamp] [${level}] $msg" >> "$LOG_FILE"
}

log() { _log "INFO" "$BLUE" "$1"; }
warn() { _log "WARN" "$YELLOW" "$1"; }
success() { _log "OK" "$GREEN" "$1"; }
error() { _log "ERROR" "$RED" "$1"; }

# Utility functions
get_dir_size() {
    [ -d "$1" ] && [ -n "$(ls -A "$1" 2>/dev/null)" ] && \
        du -sh "$1" 2>/dev/null | awk '{print $1}' || echo "0"
}

has_cmd() { command -v "$1" &> /dev/null; }
has_dir() { [ -d "$1" ] && [ "$(ls -A "$1" 2>/dev/null)" ]; }
get_disk_usage() { df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}'; }

# Cleanup helpers
safe_remove() {
    local target="$1"
    local desc="${2:-$target}"
    [ ! -e "$target" ] && return 0
    
    local size
    if [ -d "$target" ]; then
        size=$(get_dir_size "$target")
    else
        size=$(du -sh "$target" 2>/dev/null | awk '{print $1}' || echo "0")
    fi
    [ "$size" = "0" ] && return 0
    
    if [ "$DRY_RUN" = true ]; then
        log "Would remove: $desc ($size)"
    elif rm -rf "$target" 2>/dev/null; then
        success "Removed: $desc ($size)"
    else
        warn "Failed to remove: $desc"
    fi
}

safe_clean_dir() {
    local dir="$1"
    local desc="${2:-$dir}"
    [ ! -d "$dir" ] || [ -z "$(ls -A "$dir" 2>/dev/null)" ] && return 0
    
    local size
    size=$(get_dir_size "$dir")
    [ "$size" = "0" ] && return 0
    
    if [ "$DRY_RUN" = true ]; then
        log "Would clean: $desc ($size)"
    elif find "$dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null; then
        success "Cleaned: $desc ($size)"
    else
        warn "Failed to clean: $desc"
    fi
}

safe_run() {
    local desc="$1"
    shift
    if [ "$DRY_RUN" = true ]; then
        log "Would run: $desc"
    else
        log "Running: $desc"
        if eval "$*" 2>/dev/null; then
            success "Completed: $desc"
        else
            warn "Failed: $desc (non-fatal)"
        fi
    fi
}

# Cleanup modules
cleanup_system() {
    echo -e "\n${CYAN}📦 System & Package Managers${NC}"
    echo "-----------------------------------"
    
    has_cmd dnf && safe_run "Cleaning DNF cache" "sudo dnf clean all"
    has_cmd yum && ! has_cmd dnf && safe_run "Cleaning YUM cache" "sudo yum clean all"
    has_cmd apt-get && safe_run "Cleaning APT cache" "sudo apt-get clean && sudo apt-get autoremove -y"
    has_cmd pacman && safe_run "Cleaning Pacman cache" "sudo pacman -Sc --noconfirm"
    has_cmd zypper && safe_run "Cleaning Zypper cache" "sudo zypper clean --all"
    has_cmd journalctl && safe_run "Vacuuming system journal" "sudo journalctl --vacuum-time=3d"
    
    if has_cmd trash-empty; then
        safe_run "Emptying Trash" "trash-empty 7 -f 2>/dev/null || trash-empty 7"
    elif has_dir "$HOME/.local/share/Trash"; then
        safe_clean_dir "$HOME/.local/share/Trash" "Trash"
    fi
    
    has_dir "$HOME/.cache/thumbnails" && safe_clean_dir "$HOME/.cache/thumbnails" "Thumbnail cache"
}

cleanup_containers() {
    echo -e "\n${CYAN}🐳 Containers & Sandboxes${NC}"
    echo "-----------------------------------"
    
    if has_cmd docker; then
        if docker ps -q &>/dev/null 2>&1; then
            safe_run "Pruning Docker" "docker system prune -f"
        else
            warn "Docker daemon not running. Skipping."
        fi
    fi
    
    has_cmd podman && safe_run "Pruning Podman" "podman system prune -f"
    
    if has_cmd flatpak; then
        safe_run "Removing unused Flatpak runtimes" "flatpak uninstall --unused -y"
        has_dir "$HOME/.cache/flatpak" && safe_clean_dir "$HOME/.cache/flatpak" "Flatpak cache"
    fi
    
    has_cmd snap && safe_run "Removing old Snap revisions" \
        "sudo snap list --all | awk '/disabled/{print \$1, \$3}' | while read s r; do sudo snap remove \"\$s\" --revision=\"\$r\" 2>/dev/null; done"
}

cleanup_dev_tools() {
    echo -e "\n${CYAN}🛠️  Development Tools${NC}"
    echo "-----------------------------------"
    
    # JavaScript/Node
    has_cmd npm && safe_run "Cleaning NPM cache" "npm cache clean --force" && \
        safe_remove "$HOME/.npm/_npx" "NPM npx cache" && \
        safe_remove "$HOME/.npm/_cacache" "NPM cache"
    has_cmd pnpm && safe_run "Pruning PNPM store" "pnpm store prune"
    has_cmd yarn && safe_run "Cleaning Yarn cache" "yarn cache clean"
    has_cmd bun && safe_run "Cleaning Bun cache" "bun pm cache rm 2>/dev/null || true" && \
        safe_clean_dir "$HOME/.bun/install/cache" "Bun cache"
    
    # Deno/Biome
    (has_cmd deno || has_dir "$HOME/.deno") && safe_clean_dir "$HOME/.deno" "Deno cache" && \
        safe_clean_dir "$HOME/.cache/deno" "Deno cache"
    has_dir "$HOME/.biome" && safe_clean_dir "$HOME/.biome" "Biome cache"
    has_dir "$HOME/.cache/biome" && safe_clean_dir "$HOME/.cache/biome" "Biome cache"
    
    # Build tools
    has_dir "$HOME/.cache/node-gyp" && safe_clean_dir "$HOME/.cache/node-gyp" "Node-gyp cache"
    has_dir "$HOME/.cache/ms-playwright" && safe_clean_dir "$HOME/.cache/ms-playwright" "Playwright cache"
    has_dir "$HOME/.cache/ms-playwright-go" && safe_clean_dir "$HOME/.cache/ms-playwright-go" "Playwright Go cache"
    
    # Python
    if has_cmd pip || has_cmd pip3; then
        local pip_cmd
        pip_cmd=$(command -v pip3 2>/dev/null || echo "pip")
        safe_run "Purging Pip cache" "$pip_cmd cache purge 2>/dev/null || true"
        safe_clean_dir "$HOME/.cache/pip" "Pip cache"
    fi
    has_cmd uv && safe_run "Cleaning uv cache" "uv cache clean" && \
        safe_clean_dir "$HOME/.cache/uv" "UV cache"
    
    # Go
    has_cmd go && safe_run "Cleaning Go module cache" "go clean -modcache" && \
        safe_clean_dir "$HOME/.cache/go-build" "Go build cache"
    
    # .NET
    has_cmd dotnet && safe_run "Cleaning NuGet locals" "dotnet nuget locals all --clear" && \
        safe_clean_dir "$HOME/.nuget" "NuGet cache"
    
    # Java ecosystem
    has_dir "$HOME/.m2/repository" && log "Maven repository found. Skipping (use 'mvn dependency:purge-local-repository' manually)"
    has_dir "$HOME/.gradle/caches" && safe_clean_dir "$HOME/.gradle/caches" "Gradle caches"
    has_dir "$HOME/.gradle/daemon" && safe_clean_dir "$HOME/.gradle/daemon" "Gradle daemon"
    has_dir "$HOME/.sbt" && safe_clean_dir "$HOME/.sbt/preloaded" "SBT preloaded" && \
        safe_clean_dir "$HOME/.ivy2/cache" "Ivy cache"
    
    # Rust
    if has_cmd cargo || has_dir "$HOME/.cargo"; then
        safe_run "Cleaning Cargo cache" "cargo cache --autoclean 2>/dev/null || true"
        safe_clean_dir "$HOME/.cargo/registry/cache" "Cargo registry cache"
        safe_clean_dir "$HOME/.cargo/git/db" "Cargo git cache"
    fi
    has_dir "$HOME/.rustup/toolchains" && log "Rust toolchains found. Skipping (too aggressive)"
}

cleanup_editors() {
    echo -e "\n${CYAN}📝 IDE & Editor Caches${NC}"
    echo "-----------------------------------"
    
    local editors=("Code" "Cursor" "Windsurf" "VSCodium" "Antigravity" "Kiro")
    local cache_dirs=("CachedData" "Cache" "CachedExtensionVSIXs" "CachedConfigurations" "GPUCache" "Code Cache")
    
    for editor in "${editors[@]}"; do
        [ -d "$HOME/.config/$editor" ] || continue
        for cache_dir in "${cache_dirs[@]}"; do
            safe_clean_dir "$HOME/.config/$editor/$cache_dir" "$editor $cache_dir"
        done
    done
    
    # JetBrains
    for jb_base in "$HOME/.cache/JetBrains" "$HOME/.config/JetBrains"; do
        [ -d "$jb_base" ] || continue
        for ide_dir in "$jb_base"/*; do
            [ -d "$ide_dir" ] || continue
            local ide_name
            ide_name=$(basename "$ide_dir")
            safe_clean_dir "$ide_dir/caches" "$ide_name caches"
            safe_clean_dir "$ide_dir/log" "$ide_name logs"
            safe_clean_dir "$ide_dir/tmp" "$ide_name temp"
        done
    done
    
    # Other editors
    has_dir "$HOME/.config/unityhub" && safe_clean_dir "$HOME/.config/unityhub/Cache" "Unity Hub cache"
    has_dir "$HOME/.config/Zed" && safe_clean_dir "$HOME/.config/Zed/Cache" "Zed cache" && \
        safe_clean_dir "$HOME/.config/Zed/CachedData" "Zed CachedData"
    has_dir "$HOME/.var/app/dev.zed.Zed" && safe_clean_dir "$HOME/.var/app/dev.zed.Zed/cache" "Zed (Flatpak) cache"
}

cleanup_audit_tools() {
    echo -e "\n${CYAN}🔍 Audit & Analysis Artifacts${NC}"
    echo "-----------------------------------"
    
    has_cmd codeql || return 0
    
    log "Searching for CodeQL databases and SARIF results..."
    local search_dirs=("$HOME/repo" "$HOME/Documents" "$HOME/Projects" "$HOME/src")
    
    for dir in "${search_dirs[@]}"; do
        [ -d "$dir" ] || continue
        if [ "$DRY_RUN" = true ]; then
            find "$dir" -maxdepth 4 -type d -name "*-db" 2>/dev/null | while read -r db; do
                log "Would remove: $db"
            done
            find "$dir" -maxdepth 4 -type f -name "*.sarif" 2>/dev/null | while read -r sarif; do
                log "Would remove: $sarif"
            done
        else
            find "$dir" -maxdepth 4 -type d -name "*-db" -exec rm -rf {} + 2>/dev/null || true
            find "$dir" -maxdepth 4 -type f -name "*.sarif" -delete 2>/dev/null || true
        fi
    done
}

cleanup_custom() {
    echo -e "\n${CYAN}🧹 Application Caches & Temp${NC}"
    echo "-----------------------------------"
    
    has_dir "$HOME/.var/app/com.usebottles.bottles/data/bottles/temp" && \
        safe_clean_dir "$HOME/.var/app/com.usebottles.bottles/data/bottles/temp" "Bottles temp"
    has_dir "$HOME/.factory" && safe_clean_dir "$HOME/.factory/sessions" "Factory sessions" && \
        safe_clean_dir "$HOME/.factory/artifacts" "Factory artifacts"
    
    local large_caches=(
        "$HOME/.cache/gstreamer-1.0"
        "$HOME/.cache/mesa_shader_cache"
        "$HOME/.cache/tracker3"
        "$HOME/.cache/libdnf5"
        "$HOME/.cache/gnome-software"
        "$HOME/.cache/net.imput.helium"
        "$HOME/.cache/goimports"
        "$HOME/.cache/gopls"
    )
    
    for cache_dir in "${large_caches[@]}"; do
        has_dir "$cache_dir" && safe_clean_dir "$cache_dir" "$(basename "$cache_dir") cache"
    done
}

# Main
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

System Cleanup Utility - Removes caches, temp files, and unused data

Options:
  -d, --dry-run    Show what would be deleted without doing it
  -y, --yes        Skip confirmation prompt
  -h, --help       Show this help

Examples:
  $(basename "$0")              # Interactive cleanup
  $(basename "$0") -d           # Dry run
  $(basename "$0") -y           # Auto-confirm
  $(basename "$0") -d -y        # Dry run with auto-confirm
EOF
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--dry-run) DRY_RUN=true ;;
        -y|--yes) AUTO_CONFIRM=true ;;
        -h|--help) usage; exit 0 ;;
        *) error "Unknown parameter: $1"; usage; exit 1 ;;
    esac
    shift
done

# Initialize
{
    echo "=== Cleanup Session Started: $(date) ==="
    echo "Version: $VERSION"
    echo "Dry Run: $DRY_RUN"
    echo ""
} > "$LOG_FILE"

echo -e "${BLUE}🚀 Starting Cleanup Utility v${VERSION}${NC}"
DISK_USAGE_BEFORE=$(get_disk_usage)
echo "Current Disk Usage: $DISK_USAGE_BEFORE"
echo "Disk Usage Before: $DISK_USAGE_BEFORE" >> "$LOG_FILE"

[ "$DRY_RUN" = true ] && echo -e "${YELLOW}[DRY RUN MODE ENABLED - No files will be deleted]${NC}"
echo ""

# Confirmation
if [ "$AUTO_CONFIRM" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}⚠️  This will delete caches and temp files.${NC}"
    echo -e "${YELLOW}   Ensure all work is saved before proceeding.${NC}"
    echo ""
    read -p "Are you sure you want to proceed? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && { echo "Aborted."; exit 1; }
    
    if has_cmd dnf || has_cmd yum || has_cmd apt-get || has_cmd pacman || has_cmd zypper || has_cmd journalctl; then
        echo "Acquiring sudo privilege for system cleanup..."
        sudo -v
    fi
fi

# Run cleanup
cleanup_system
cleanup_containers
cleanup_dev_tools
cleanup_editors
cleanup_audit_tools
cleanup_custom

# Summary
echo -e "\n${MAGENTA}═══════════════════════════════════════${NC}"
success "Cleanup Complete!"
echo ""
DISK_USAGE_AFTER=$(get_disk_usage)
echo "Disk Usage Before: $DISK_USAGE_BEFORE"
echo "Disk Usage After:  $DISK_USAGE_AFTER"
echo ""
[ "$DRY_RUN" = false ] && echo -e "${GREEN}✓ Cleanup operations completed successfully${NC}"
echo -e "${BLUE}Log file: ${LOG_FILE}${NC}"
echo -e "${BLUE}Have a nice day! 🎉${NC}"
echo ""

{
    echo "Disk Usage After: $DISK_USAGE_AFTER"
    echo "=== Cleanup Session Ended: $(date) ==="
} >> "$LOG_FILE"
