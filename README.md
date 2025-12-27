# dacrab's Dotfiles

Stow‑managed configs for my Linux environment: Hyprland/Niri, panels/launchers, terminals, shell, SSH, and helper scripts. Packages are symlinked into $HOME using GNU Stow.

## Contents

### Window Managers & Desktop
- hypr-stow — Hyprland config (hyprland.conf, keybindings, hyprpaper)
- niri-stow — Niri compositor config
- hyprpanel-stow — Panel for Hyprland
- ashell-stow — Alternative shell/panel setup
- waybar-stow — Waybar config

### Terminals
- ghostty-stow — Ghostty terminal (primary)
- kitty-stow — Kitty terminal (backup config)

### Launchers
- wofi-stow — Wofi launcher

### Shell & CLI
- mybash — Bash config (.bashrc / .bash_profile) and Starship prompt
- git-stow — Global git configuration
- fzf-stow — fzf shell integration
- fastfetch-stow — Fastfetch system info config
- scripts-stow — Helper scripts (e.g., random-wall.sh)
- ssh-stow — Safe SSH files (config and public keys only)

### Apps & Theming
- gtk-stow — GTK configuration (GTK2/GTK3/GTK4 themes, cursor, fonts)
- browser-flags-stow — Chrome/Code Wayland flags
- spicetify-stow — Spicetify config
- tiling-assistant-stow — GNOME tiling assistant

### Archived
Old configs in `archived/`: fuzzel, rofi, themes, waypaper, xsettingsd

## Requirements

- GNU Stow
- Hyprland or Niri (for respective WM configs)
- Starship (for mybash) and bash
- For random-wall.sh: gsettings (GNOME) or adapt for your compositor

## Install

```bash
git clone https://github.com/dacrab/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Core setup
stow hypr-stow hyprpanel-stow gtk-stow mybash git-stow fzf-stow scripts-stow \
     ghostty-stow waybar-stow spicetify-stow tiling-assistant-stow \
     browser-flags-stow fastfetch-stow wofi-stow

# Optional: Niri instead of Hyprland
stow niri-stow ashell-stow

# Optional: Kitty terminal (backup)
stow kitty-stow

# SSH (only safe files tracked)
stow ssh-stow
```

Tips:
- Re‑stow after updates: `stow -R <package>`
- Unstow to remove: `stow -D <package>`
- Preview changes: `stow --simulate <package>`

## Scripts

### random-wall.sh

Sets a random wallpaper from a directory, avoiding immediate repeats.

- Location: `scripts-stow/.local/bin/` (symlinked when stowed)
- Custom directory: `WALLPAPER_DIR="$HOME/Pictures/wallpapers/nord" random-wall.sh`
- Defaults to `$HOME/Pictures/wallpapers`

Note: Uses `gsettings` (GNOME). For Hyprland/Niri, adapt the apply step.

## SSH Notes

- Repo tracks only `ssh-stow/.ssh/config` and `ssh-stow/.ssh/*.pub`
- Private keys and known_hosts are gitignored

## Updating

```bash
cd ~/dotfiles
git pull
stow -R hypr-stow hyprpanel-stow gtk-stow mybash git-stow fzf-stow scripts-stow \
        ghostty-stow waybar-stow spicetify-stow tiling-assistant-stow \
        browser-flags-stow fastfetch-stow wofi-stow ssh-stow
```

## License

MIT — see [LICENSE](LICENSE).
