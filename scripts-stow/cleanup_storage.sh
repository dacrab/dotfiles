#!/bin/bash

# ==============================================================================
#  System Cleanup Utility - "The Great Sweep" (Enhanced)
#  Tailored for: Fedora Linux | Dev Environment (Node, Go, Python, Dotnet, Unity)
# ==============================================================================

set -e

# --- Configuration ---
VERSION="2.0.0"
LOG_FILE="/tmp/cleanup_storage.log"
DRY_RUN=false
AUTO_CONFIRM=false

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Helpers ---
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[INFO] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[WARN] $1" >> "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
    echo "[OK] $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
}

get_disk_usage() {
    df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}'
}

# --- Cleanup Modules ---

cleanup_system() {
    echo -e "\n${CYAN}📦 System & Package Managers${NC}"
    echo "-----------------------------------"

    # DNF (Fedora)
    if command -v dnf &> /dev/null; then
        log "Cleaning DNF metadata and cache..."
        if [ "$DRY_RUN" = false ]; then
            sudo dnf clean all
        fi
    fi

    # Journald
    if command -v journalctl &> /dev/null; then
        log "Vacuuming system journal (Retaining 3 days)..."
        if [ "$DRY_RUN" = false ]; then
            sudo journalctl --vacuum-time=3d
        fi
    fi

    # Trash
    if command -v trash-empty &> /dev/null; then
        log "Emptying Trash (older than 7 days)..."
         if [ "$DRY_RUN" = false ]; then
            # Use -f to avoid interactive prompt
            trash-empty 7 -f || trash-empty 7
        fi
    elif [ -d "$HOME/.local/share/Trash" ]; then
        warn "trash-cli not found, manually emptying ~/.local/share/Trash..."
        if [ "$DRY_RUN" = false ]; then
            rm -rf "$HOME/.local/share/Trash"/* 2>/dev/null || true
        fi
    fi
}

cleanup_audit_tools() {
    echo -e "\n${CYAN}🔍 Audit & Analysis Artifacts${NC}"
    echo "-----------------------------------"

    # CodeQL
    if command -v codeql &> /dev/null; then
        log "Searching for CodeQL databases (*-db) and SARIF results..."
        # Search in common dev directories, limiting depth for performance
        local SEARCH_DIRS=("$HOME/repo" "$HOME/Documents")
        for dir in "${SEARCH_DIRS[@]}"; do
            if [ -d "$dir" ]; then
                [ "$DRY_RUN" = false ] && find "$dir" -maxdepth 4 -type d -name "*-db" -exec rm -rf {} + 2>/dev/null || true
                [ "$DRY_RUN" = false ] && find "$dir" -maxdepth 4 -type f -name "*.sarif" -delete 2>/dev/null || true
            fi
        done
    fi
}

cleanup_containers() {
    echo -e "\n${CYAN}🐳 Containers & Sandboxes${NC}"
    echo "-----------------------------------"

    # Docker
    if command -v docker &> /dev/null; then
        if docker ps -q &>/dev/null; then # Check if daemon is running
            log "Pruning unused Docker objects..."
            if [ "$DRY_RUN" = false ]; then
                docker system prune -f
            fi
        else
            warn "Docker is installed but not running. Skipping."
        fi
    fi

    # Flatpak
    if command -v flatpak &> /dev/null; then
        log "Removing unused Flatpak runtimes..."
        if [ "$DRY_RUN" = false ]; then
            flatpak uninstall --unused -y
        fi
    fi
}

cleanup_dev_tools() {
    echo -e "\n${CYAN}🛠️  Development Tools${NC}"
    echo "-----------------------------------"

    # Node / JS
    if command -v npm &> /dev/null; then
        log "Cleaning NPM cache..."
        [ "$DRY_RUN" = false ] && npm cache clean --force || true
        [ "$DRY_RUN" = false ] && rm -rf "$HOME/.npm/_npx" 2>/dev/null || true
    fi
    if command -v pnpm &> /dev/null; then
        log "Pruning PNPM store..."
        [ "$DRY_RUN" = false ] && pnpm store prune || true
    fi
    if command -v bun &> /dev/null; then
        log "Cleaning Bun cache..."
        [ "$DRY_RUN" = false ] && bun pm cache rm 2>/dev/null || true
        [ "$DRY_RUN" = false ] && rm -rf "$HOME/.bun/install/cache"/* 2>/dev/null || true
    fi

    # Python
    if command -v pip &> /dev/null; then
        log "Purging Pip cache..."
        [ "$DRY_RUN" = false ] && pip cache purge || true
    fi
    if command -v uv &> /dev/null; then
        log "Cleaning uv cache..."
        [ "$DRY_RUN" = false ] && uv cache clean || true
    fi

    # Go
    if command -v go &> /dev/null; then
        log "Cleaning Go module cache..."
        [ "$DRY_RUN" = false ] && go clean -modcache || true
    fi

    # Dotnet
    if command -v dotnet &> /dev/null; then
        log "Cleaning NuGet locals..."
        [ "$DRY_RUN" = false ] && dotnet nuget locals all --clear || true
    fi
    
    # Maven
    if [ -d "$HOME/.m2/repository" ]; then
        log "Found Maven repository ($HOME/.m2/repository). Skipping auto-delete (too aggressive)."
    fi
}



cleanup_editors() {
    echo -e "\n${CYAN}📝 IDE & Editor Caches${NC}"
    echo "-----------------------------------"
    
    # VS Code / Derivatives
    local editors=("Code" "Cursor" "Windsurf" "VSCodium")
    for editor in "${editors[@]}"; do
        local cache_path="$HOME/.config/$editor/CachedData"
        if [ -d "$cache_path" ]; then
            log "Clearing $editor CachedData..."
            [ "$DRY_RUN" = false ] && rm -rf "${cache_path:?}"/* 2>/dev/null || true
        fi
    done
}

cleanup_custom() {
    echo -e "\n${CYAN}🧹 Application Caches & Temp${NC}"
    echo "-----------------------------------"

    # Bottles
    local bottles_temp="$HOME/.var/app/com.usebottles.bottles/data/bottles/temp"
    if [ -d "$bottles_temp" ]; then
        log "Clearing Bottles temp..."
        [ "$DRY_RUN" = false ] && rm -rf "${bottles_temp:?}"/* 2>/dev/null || true
    fi

    # Factory (User specific)
    local factory_dir="$HOME/.factory"
    if [ -d "$factory_dir" ]; then
        log "Clearing Factory sessions & artifacts..."
        [ "$DRY_RUN" = false ] && rm -rf "$factory_dir/sessions"/* 2>/dev/null || true
        [ "$DRY_RUN" = false ] && rm -rf "$factory_dir/artifacts"/* 2>/dev/null || true
    fi
    
    # User Cache (Thumbnails)
    log "Clearing thumbnail cache..."
    [ "$DRY_RUN" = false ] && rm -rf "$HOME/.cache/thumbnails"/* 2>/dev/null || true
}

# --- Main ---

usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo "Options:"
    echo "  -d, --dry-run    Show what would be deleted without doing it"
    echo "  -y, --yes        Skip confirmation prompt"
    echo "  -h, --help       Show this help"
}

# Parse Args
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--dry-run) DRY_RUN=true ;; 
        -y|--yes) AUTO_CONFIRM=true ;; 
        -h|--help) usage; exit 0 ;; 
        *) error "Unknown parameter passed: $1"; exit 1 ;; 
    esac
    shift
done

echo -e "${BLUE}🚀 Starting Cleanup Utility v${VERSION}${NC}"
echo "Current Disk Usage: $(get_disk_usage)"
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN MODE ENABLED]${NC}"
fi

if [ "$AUTO_CONFIRM" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}This will delete caches and temp files. Ensure all work is saved.${NC}"
    read -p "Are you sure you want to proceed? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    # Sudo prompt early if we are going to use it
    if command -v dnf &> /dev/null || command -v journalctl &> /dev/null; then
         echo "Acquiring sudo privilege for system cleanup..."
         sudo -v
    fi
fi

cleanup_system
cleanup_containers
cleanup_dev_tools
cleanup_audit_tools
cleanup_custom

cleanup_editors

echo -e "\n-----------------------------------"
success "Cleanup Complete!"
echo "New Disk Usage: $(get_disk_usage)"
echo -e "${BLUE}Have a nice day!${NC}"