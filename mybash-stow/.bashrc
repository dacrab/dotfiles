#!/usr/bin/env bash

# Check if running interactively
[[ $- != *i* ]] && return

#######################################################
# INITIALIZATION
#######################################################

# Display system info
command -v fastfetch >/dev/null 2>&1 && fastfetch

# Source system-wide bash configuration
[[ -f /etc/bashrc ]] && source /etc/bashrc

# Enable bash completion
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
elif [[ -f /etc/bash_completion ]]; then
    source /etc/bash_completion
fi

#######################################################
# SHELL OPTIONS
#######################################################

# Update window size after each command
shopt -s checkwinsize

# Append to history instead of overwriting
shopt -s histappend

# Disable terminal bell
bind "set bell-style none" 2>/dev/null

# Case-insensitive completion
bind "set completion-ignore-case on" 2>/dev/null

# Show completion list immediately
bind "set show-all-if-ambiguous on" 2>/dev/null

# Allow Ctrl+S for forward history search
stty -ixon 2>/dev/null

#######################################################
# HISTORY CONFIGURATION
#######################################################

export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTTIMEFORMAT="%F %T "
export HISTCONTROL="erasedups:ignoredups:ignorespace"
export PROMPT_COMMAND="history -a"

#######################################################
# ENVIRONMENT VARIABLES
#######################################################

# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Default editors
export EDITOR="nvim"
export VISUAL="nvim"

# Color support
export CLICOLOR=1
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;31m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[1;44;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'

# PATH additions
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

#######################################################
# UTILITY FUNCTIONS
#######################################################

# Detect Linux distribution
get_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            fedora|rhel|centos|rocky|almalinux) echo "redhat" ;;
            ubuntu|debian|mint) echo "debian" ;;
            arch|manjaro|endeavouros) echo "arch" ;;
            opensuse*|sles) echo "suse" ;;
            gentoo) echo "gentoo" ;;
            *) echo "unknown" ;;
        esac
    else
        echo "unknown"
    fi
}

# Extract various archive formats
extract() {
    for file in "$@"; do
        if [[ -f "$file" ]]; then
            case "$file" in
                *.tar.bz2) tar xjf "$file" ;;
                *.tar.gz) tar xzf "$file" ;;
                *.tar.xz) tar xJf "$file" ;;
                *.bz2) bunzip2 "$file" ;;
                *.rar) unrar x "$file" ;;
                *.gz) gunzip "$file" ;;
                *.tar) tar xf "$file" ;;
                *.tbz2) tar xjf "$file" ;;
                *.tgz) tar xzf "$file" ;;
                *.zip) unzip "$file" ;;
                *.Z) uncompress "$file" ;;
                *.7z) 7z x "$file" ;;
                *) echo "Unknown archive format: $file" ;;
            esac
        else
            echo "File not found: $file"
        fi
    done
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Go up n directories
up() {
    local levels=${1:-1}
    local path=""
    for ((i=0; i<levels; i++)); do
        path="../$path"
    done
    cd "$path"
}

# Auto-show directory contents (multi-column) after cd
cd() {
    if [[ $# -eq 0 ]]; then
        if builtin cd ~; then
            if command -v eza >/dev/null 2>&1; then
                eza --icons --group-directories-first
            elif command -v exa >/dev/null 2>&1; then
                exa --icons --group-directories-first
            elif command -v lsd >/dev/null 2>&1; then
                lsd --group-dirs=first --icon=auto
            else
                ls -CF --color=auto
            fi
        fi
    else
        if builtin cd "$@"; then
            if command -v eza >/dev/null 2>&1; then
                eza --icons --group-directories-first
            elif command -v exa >/dev/null 2>&1; then
                exa --icons --group-directories-first
            elif command -v lsd >/dev/null 2>&1; then
                lsd --group-dirs=first --icon=auto
            else
                ls -CF --color=auto
            fi
        fi
    fi
}

# Search text in files
search_files() {
    grep -rn --color=always "$1" . | less -R
}

# Get internal and external IP
myip() {
    echo "Internal IP:"
    ip route get 1.1.1.1 | awk '{print $7}' 2>/dev/null || echo "Not connected"
    echo "External IP:"
    curl -s ifconfig.me || echo "Unable to fetch"
}
# Quick commit
gcom() {
    git add . && git commit -m "$1"
}

# Lazy git (add, commit, push)
lazy() {
    git add . && git commit -m "$1" && git push
}

#######################################################
# ALIASES - NAVIGATION
#######################################################

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ..1='cd ..'
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ~='cd ~'
#######################################################
# ALIASES - SYSTEM
#######################################################

alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'
alias reload='source ~/.bashrc'
alias please='sudo $(fc -ln -1)'
alias pathadd='export PATH="$PWD:$PATH" && echo $PATH'
#######################################################
# ALIASES - FILE OPERATIONS
#######################################################

alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias mkdir='mkdir -pv'

# Safe alternatives
command -v trash >/dev/null 2>&1 && alias rm='trash'

# Default ls aliases
alias ls='ls --color=auto -F'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -1F'
alias lt='ls -ltr'
alias lh='ls -lh'
alias tree='tree -C'

# Prefer eza (or exa) or lsd for icons and organized output
if command -v eza >/dev/null 2>&1; then
    alias ls='eza -a -1 --icons --group-directories-first'
    alias l='eza -1 --icons --group-directories-first'
    alias la='eza -a -1 --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first --no-user --no-group --no-permissions --no-filesize --time=modified --time-style="%Y-%m-%d %H:%M"'
    alias lt='eza -T --level=2 --icons --group-directories-first'
elif command -v exa >/dev/null 2>&1; then
    alias ls='exa -a -1 --icons --group-directories-first'
    alias l='exa -1 --icons --group-directories-first'
    alias la='exa -a -1 --icons --group-directories-first'
    alias ll='exa -l --icons --group-directories-first --no-user --no-group --no-permissions --no-filesize --time=modified --time-style="%Y-%m-%d %H:%M"'
    alias lt='exa -T --level=2 --icons --group-directories-first'
elif command -v lsd >/dev/null 2>&1; then
    alias ls='lsd -a -1 --group-dirs=first --icon=auto'
    alias l='lsd -1 --group-dirs=first --icon=auto'
    alias la='lsd -a -1 --group-dirs=first --icon=auto'
    alias ll='lsd -l --group-dirs=first --icon=auto --blocks date,name --date "+%Y-%m-%d %H:%M"'
    alias lt='lsd --tree --depth 2 --group-dirs=first --icon=auto'
fi

#######################################################
# ALIASES - TEXT PROCESSING
#######################################################

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Use modern alternatives if available
command -v rg >/dev/null 2>&1 && alias grep='rg'
command -v bat >/dev/null 2>&1 && alias cat='bat'

#######################################################
# ALIASES - ARCHIVES
#######################################################

alias untar='tar -xvf'
alias targz='tar -czvf'

#######################################################
# ALIASES - SYSTEM MONITORING
#######################################################

alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps auxf'
alias psg='ps aux | grep'
alias top='htop'
alias ports='netstat -tulanp'

#######################################################
# ALIASES - PACKAGE MANAGEMENT
#######################################################

DISTRO=$(get_distro)
case "$DISTRO" in
    "debian")
        alias install='sudo apt install'
        alias update='sudo apt update && sudo apt upgrade'
        alias search='apt search'
        alias remove='sudo apt remove'
        ;;
    "redhat")
        alias install='sudo dnf install'
        alias update='sudo dnf update'
        alias search='dnf search'
        alias remove='sudo dnf remove'
        ;;
    "arch")
        alias install='sudo pacman -S'
        alias update='sudo pacman -Syu'
        alias search='pacman -Ss'
        alias remove='sudo pacman -R'
        ;;
esac

#######################################################
# ALIASES - DEVELOPMENT
#######################################################

alias vim='nvim'
alias vi='nvim'
alias edit='$EDITOR'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias ggraph='git log --graph --decorate --oneline --all'
alias gst='git status -sb'
alias gco='git checkout'
alias gb='git branch --all'
alias gclean='git fetch -p && git branch --merged | egrep -v "(^\*|main|master|dev)" | xargs -r git branch -d'

#######################################################
# ALIASES - DOCKER
#######################################################

alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'
alias dclean='docker system prune -af'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcb='docker compose build'
alias dcl='docker compose logs -f'

#######################################################
# ALIASES - NETWORKING
#######################################################

alias ping='ping -c 5'
alias wget='wget -c'
alias curl='curl -L'
alias iplocal="hostname -I | awk '{print $1}'"
alias ippublic='curl -s https://ifconfig.me'

#######################################################
# ALIASES - SERVERS
#######################################################

alias serve='python3 -m http.server 8000'
alias servep='python3 -m http.server 8000 --bind 127.0.0.1'

alias cursor-reset='cd ~/Documents/GitHub/cursor-reset && ./cursor-reset.sh'

#######################################################
# CUSTOM KEYBINDINGS
#######################################################

# Bind Ctrl+f to zi (zoxide interactive)
bind '"\C-f":"zi\n"' 2>/dev/null

#######################################################
# PROMPT AND SHELL ENHANCEMENTS
#######################################################

# Initialize starship prompt if available
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# Initialize zoxide if available
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"

#######################################################
# AUTO-START X11
#######################################################

# Auto-start X11 on tty1
if [[ -z "$DISPLAY" ]] && [[ "$(tty)" = "/dev/tty1" ]]; then
    exec startx
fi

. "$HOME/.local/share/../bin/env"
export PATH="/home/dacrab/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/home/dacrab/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
export PATH="$PATH:$HOME/.composer/vendor/bin"
