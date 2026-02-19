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
- fuzzel-stow — Fuzzel launcher

### Shell & CLI
- mybash — Bash config (.bashrc / .bash_profile) and Starship prompt
- git-stow — Global git configuration
- fzf-stow — fzf shell integration
- fastfetch-stow — Fastfetch system info config
- scripts-stow — Helper scripts (random-wall.sh, cleanup_storage.sh)
- ssh-stow — Safe SSH files (config and public keys only)

### Apps & Theming
- gtk-stow — GTK configuration (GTK2/GTK3/GTK4 themes, cursor, fonts)
- browser-flags-stow — Chrome/Code Wayland flags
- spicetify-stow — Spicetify config
- tiling-assistant-stow — GNOME tiling assistant
- zed-stow — Zed editor settings

### Archived
Old configs in `archived/`: rofi, themes, waypaper, xsettingsd

## Requirements

- GNU Stow
- Hyprland or Niri (for respective WM configs)
- Starship (for mybash) and bash
- For random-wall.sh: gsettings (GNOME) or adapt for your compositor

## Install

```bash
git clone --recursive https://github.com/dacrab/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Core setup
stow hypr-stow hyprpanel-stow gtk-stow mybash git-stow fzf-stow scripts-stow \
     ghostty-stow waybar-stow spicetify-stow tiling-assistant-stow \
     browser-flags-stow fastfetch-stow wofi-stow fuzzel-stow zed-stow

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

### cleanup_storage.sh (alias: `sweep`)

System cleanup utility that removes caches, temp files, and optionally project artifacts.

```bash
sweep              # Standard cleanup (caches, logs, trash, etc.)
sweep -p           # + clean old project artifacts (node_modules, target, dist, etc.)
sweep -i           # + clean installer files in Downloads (iso, deb, rpm, AppImage, etc.)
sweep -p -i        # Both project artifacts and installers
sweep -d           # Dry run - preview what would be deleted
sweep -y           # Auto-confirm all prompts
```

What it cleans:
- Package manager caches (dnf, apt, pacman, yay, paru)
- Journal logs, trash, thumbnails
- Dev tool caches (npm, pnpm, pip, cargo, go, gradle)
- Editor caches (VS Code, Cursor, JetBrains)
- Container pruning (docker, podman)
- Flatpak/Snap orphans
- Old AppImage backups

With `-p` (purge): Scans `~/dev`, `~/Projects`, `~/Documents/GitHub`, etc. for old (>7 days) build artifacts like `node_modules`, `target`, `.venv`, `.next`, `dist`.

With `-i` (installers): Finds large installer files (>10MB) in Downloads/Desktop.

### random-wall.sh

Sets a random wallpaper from a directory, avoiding immediate repeats.

- Location: `scripts-stow/.local/bin/` (symlinked when stowed)
- Custom directory: `WALLPAPER_DIR="$HOME/Pictures/wallpapers/nord" random-wall.sh`
- Defaults to `$HOME/Pictures/wallpapers`

Note: Supports GNOME (gsettings), Hyprland (hyprpaper), and Niri (swaybg) automatically.

## SSH Notes

- Repo tracks only `ssh-stow/.ssh/config` and `ssh-stow/.ssh/*.pub`
- Private keys and known_hosts are gitignored

## Updating

```bash
cd ~/dotfiles
git pull
stow -R hypr-stow hyprpanel-stow gtk-stow mybash git-stow fzf-stow scripts-stow \
        ghostty-stow waybar-stow spicetify-stow tiling-assistant-stow \
        browser-flags-stow fastfetch-stow wofi-stow fuzzel-stow zed-stow ssh-stow
```

## License

MIT — see [LICENSE](LICENSE).
