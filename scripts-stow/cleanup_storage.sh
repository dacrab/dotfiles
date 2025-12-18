#!/bin/bash

# Storage Cleanup Utility - "The Great Sweep"
# Reclaims space from system caches, dev artifacts, and temp files.

clean_storage() {
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local NC='\033[0m' # No Color

    echo -e "${BLUE}🚀 Starting Comprehensive Cleanup...${NC}"
    echo "=================================================="

    # 1. System Cleanup (Requires Sudo)
    echo -e "${YELLOW}📦 [System] Cleaning Package Managers & Logs...${NC}"
    if command -v dnf &> /dev/null; then
        echo "Cleaning DNF cache..."
        sudo dnf clean all
    fi
    
    if command -v journalctl &> /dev/null; then
        echo "Vacuuming system journal (keeping 7 days)..."
        sudo journalctl --vacuum-time=7d
    fi

    # 2. Container & Flatpak Cleanup
    if command -v docker &> /dev/null; then
        echo -e "${YELLOW}🐳 [Docker] Pruning system...${NC}"
        docker system prune -af
    fi

    if command -v flatpak &> /dev/null; then
        echo -e "${YELLOW}📦 [Flatpak] Removing unused runtimes...${NC}"
        flatpak uninstall --unused -y
    fi

    # 3. Development Environments
    echo -e "${YELLOW}🛠️  [Dev] Cleaning package manager caches...${NC}"
    
    if command -v npm &> /dev/null; then
        echo "Cleaning NPM cache & NPX..."
        npm cache clean --force
        rm -rf "$HOME/.npm/_npx"/* 2>/dev/null
    fi

    if command -v bun &> /dev/null; then
        echo "Cleaning Bun cache..."
        bun clean 2>/dev/null || rm -rf "$HOME/.bun/install/cache"/* 2>/dev/null
    fi

    if command -v go &> /dev/null; then
        echo "Cleaning Go module cache..."
        go clean -modcache
    fi

    # 4. Project-Specific Artifacts (Unity Library)
    local SEARCH_DIR="$HOME/Documents/GitHub"
    if [ ! -d "$SEARCH_DIR" ]; then
        SEARCH_DIR="."
    fi

    echo -e "${YELLOW}🎮 [Unity] Searching for Library folders in $SEARCH_DIR...${NC}"
    find "$SEARCH_DIR" -maxdepth 3 -name "Library" -type d -prune -print -exec rm -rf {} + 2>/dev/null

    # 5. App-Specific Temp/Trash
    echo -e "${YELLOW}🧹 [Temp] Cleaning Trash and App temps...${NC}"
    
    # Trash
    if [ -d "$HOME/.local/share/Trash" ]; then
        echo "Emptying Trash..."
        rm -rf "$HOME/.local/share/Trash"/* 2>/dev/null
    fi

    # Bottles
    if [ -d "$HOME/.var/app/com.usebottles.bottles/data/bottles/temp" ]; then
        echo "Clearing Bottles temp..."
        rm -rf "$HOME/.var/app/com.usebottles.bottles/data/bottles/temp"/* 2>/dev/null
    fi

    # Factory
    if [ -d "$HOME/.factory" ]; then
        echo "Clearing Factory sessions & artifacts..."
        rm -rf "$HOME/.factory/sessions"/* 2>/dev/null
        rm -rf "$HOME/.factory/artifacts"/* 2>/dev/null
    fi

    echo "=================================================="
    echo -e "${GREEN}✅ Cleanup Complete! Drive is looking lean.${NC}"
}

# Run the function if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    clean_storage
fi
