# dacrab’s Dotfiles

Stow‑managed configs for my Linux environment: Hyprland, panels/launchers, shell, SSH, and helper scripts. Packages are symlinked into $HOME using GNU Stow.

## Contents

- hypr — Hyprland config (hyprland.conf, keybindings, hyprpaper integration)
- hyprpanel — Panel for Hyprland
- ashell — Alternative shell/panel setup (optional)
- fuzzel, rofi, wofi — Launchers and themes
- gtk — GTK configuration
- mybash-stow — Bash config (.bashrc) and Starship prompt
- scripts-stow — Helper scripts (e.g., random-wall.sh)
- ssh-stow — Safe SSH files (config and public keys only)

## Requirements

- GNU Stow
- For Hyprland packages: Hyprland (and hyprpaper if configured)
- For random-wall.sh: gsettings (GNOME) or adapt the “apply wallpaper” step
- Starship (for mybash-stow) and bash

## Install

```bash
git clone https://github.com/dacrab/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Common setup
stow hypr hyprpanel fuzzel gtk rofi wofi mybash-stow scripts-stow

# Optional: use ashell instead of hyprpanel
stow ashell

# SSH (only safe files are tracked: config, *.pub)
stow ssh-stow
```

Tips:
- Re‑stow after updates: `stow -R <package>`
- Unstow to remove: `stow -D <package>`
- Preview changes: `stow --simulate <package>`

## Scripts

### random-wall.sh

Sets a random wallpaper from a directory, avoiding immediate repeats and using XDG/$HOME paths.

- Location: `scripts-stow/random-wall.sh` (symlinked to `$HOME/random-wall.sh` when stowed)
- One‑off directory:
  ```bash
  WALLPAPER_DIR="$HOME/Pictures/wallpapers/nord" random-wall.sh
  ```
- Permanent directory:
  ```bash
  echo 'export WALLPAPER_DIR="$HOME/Pictures/wallpapers/nord"' >> ~/.bashrc
  source ~/.bashrc
  ```
- Defaults: detects Pictures via `xdg-user-dir`, falls back to `$HOME/Pictures`; uses `$PICTURES_DIR/wallpapers` if `WALLPAPER_DIR` is unset; remembers last selection in `${XDG_STATE_HOME:-$HOME/.local/state}/random-wall/last_wallpaper`.

Note: Uses `gsettings` (GNOME). For other desktops/compositors, replace the apply step.

## SSH Notes

- Repo tracks only `ssh-stow/.ssh/config` and `ssh-stow/.ssh/*.pub`.
- Private keys, known_hosts, etc. are ignored via `.gitignore` and must never be committed.

## Troubleshooting

- Stow conflicts: back up the conflicting files (e.g., `~/.ssh/config`) and re‑run stow. Consider `stow --adopt` only if you understand its effects.
- Config not taking effect: ensure the package is stowed and required programs are installed.

## Updating

```bash
cd ~/dotfiles
git pull
stow -R hypr hyprpanel ashell fuzzel gtk rofi wofi mybash-stow scripts-stow ssh-stow
```

## License

MIT — see [LICENSE](LICENSE).