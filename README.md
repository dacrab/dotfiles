# dacrab's Dotfiles

Stow‑managed configs for my Linux environment: Hyprland/Niri, panels/launchers, terminals, shell, SSH, and helper scripts. Packages are symlinked into $HOME using GNU Stow.

## Contents

### Window Managers & Desktop
- niri-stow — Niri compositor config

### Terminals
- ghostty-stow — Ghostty terminal

### Launchers
- fuzzel-stow — Fuzzel launcher

### Shell & CLI
- mybash — Bash config (.bashrc / .bash_profile) and Starship prompt
- git-stow — Global git configuration
- fzf-stow — fzf shell integration
- fastfetch-stow — Fastfetch system info config
- scripts-stow — Helper scripts (random-wall.sh, cleanup_storage.sh, update.sh)
- ssh-stow — Safe SSH files (config and public keys only)

### Apps & Theming
- gtk-stow — GTK configuration (GTK2/GTK3/GTK4 themes, cursor, fonts)
- browser-flags-stow — Chrome/Code Wayland flags
- spicetify-stow — Spicetify config
- zed-stow — Zed editor settings

### Archived
Old configs in `archived/`

## Requirements

- GNU Stow
- Niri (for WM config)
- Starship (for mybash) and bash
- For random-wall.sh: gsettings (GNOME) or adapt for your compositor

## Install

```bash
git clone --recursive https://github.com/dacrab/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Core setup
stow niri-stow gtk-stow mybash git-stow fzf-stow scripts-stow \
     ghostty-stow spicetify-stow browser-flags-stow \
     fastfetch-stow fuzzel-stow zed-stow ssh-stow
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
- Dev tool caches (npm, pnpm, bun, pip, uv, go, dotnet, cargo, gradle)
- Virtualenv orphans (~/.virtualenvs and stray venv dirs)
- Editor caches (VS Code, Cursor, JetBrains, Antigravity, Kiro)
- Container pruning (docker, podman)
- Flatpak/Snap orphans
- Old AppImage backups

With `-p` (purge): Scans `~/dev`, `~/Projects`, `~/Documents/GitHub`, etc. for old (>7 days) build artifacts like `node_modules`, `target`, `.venv`, `.next`, `dist`.

With `-i` (installers): Finds large installer files (>10MB) in Downloads/Desktop.

### random-wall.sh (alias: `wall`)

Sets a random wallpaper from a chosen theme folder, avoiding immediate repeats.

```bash
wall          # Interactive folder picker — choose from subfolders in ~/Pictures/wallpapers
wall nord     # Pick random wallpaper directly from the nord folder
```

- Wallpaper base: `~/Pictures/wallpapers/` (subfolders are your themes)
- Default folder (for keybind): set via `DEFAULT_FOLDER` at top of script (currently `nord`)
- Keybind (`Super+Shift+W`): instantly sets a random wall from whichever folder you last picked in the menu — no terminal, no prompt
- Saves last chosen folder to `~/.local/state/random-wall/active_folder`
- Supports GNOME (gsettings) and Niri (swaybg)

## SSH Notes

- Repo tracks only `ssh-stow/.ssh/config` and `ssh-stow/.ssh/*.pub`
- Private keys and known_hosts are gitignored

## Updating

```bash
cd ~/dotfiles
git pull
stow -R niri-stow gtk-stow mybash git-stow fzf-stow scripts-stow \
        ghostty-stow spicetify-stow browser-flags-stow \
        fastfetch-stow fuzzel-stow zed-stow ssh-stow
```

## License

MIT — see [LICENSE](LICENSE).
