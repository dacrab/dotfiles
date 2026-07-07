# dotfiles

Stow-managed configs for my Linux environment: Hyprland/Niri, panels, terminals, shell, and helper scripts.

## Contents

- **hypr-stow** — Hyprland compositor (modular config, hyprpaper, hyprlock, scripts)
- **niri-stow** — Niri compositor config
- **wayle-stow** — Wayle bar/panel
- **waybar-stow** — Waybar panel
- **wofi-stow** — Wofi launcher (fallback)
- **vicinae-stow** — Vicinae launcher (install via Terra: `sudo dnf install vicinae`)
- **nwg-bar-stow** — nwg-bar power menu
- **fuzzel-stow** — Fuzzel launcher
- **ghostty-stow** — Ghostty terminal
- **mybash** — Bash config + Starship prompt
- **git-stow** — Global git configuration
- **fzf-stow** — fzf shell integration
- **fastfetch-stow** — Fastfetch system info config
- **scripts-stow** — Helper scripts (`sweep`, `wall`, `update`)
- **ssh-stow** — SSH config and public keys only
- **gtk-stow** — GTK themes, cursor, fonts
- **browser-flags-stow** — Chrome/Code Wayland flags
- **zed-stow** — Zed editor settings

## Install

```bash
git clone --recursive https://github.com/dacrab/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Core
stow mybash git-stow fzf-stow scripts-stow ssh-stow \
     ghostty-stow fastfetch-stow browser-flags-stow \
     gtk-stow zed-stow

# Hyprland desktop
stow hypr-stow wayle-stow waybar-stow vicinae-stow wofi-stow nwg-bar-stow

# Niri desktop
stow niri-stow fuzzel-stow
```

- Re-stow after updates: `stow -R <package>`
- Unstow to remove: `stow -D <package>`
- Preview changes: `stow --simulate <package>`

## Scripts

| Alias | Script | What it does |
|-------|--------|--------------|
| `sweep` | sweep.sh | Cleans caches, logs, trash, dev artifacts, containers |
| `wall` | random-wall.sh | Sets a random wallpaper (supports Hyprland/Niri/GNOME) |
| `update` | update.sh | System-wide updater (packages, runtimes, tools) |

## License

MIT
