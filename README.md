# dotfiles

My Linux desktop setup, kept in one place and managed with [Stow](https://www.gnu.org/software/stow/). It covers the window manager I use (Hyprland), terminals, shell, and a few helper scripts for everyday tasks.

## What's here

| Package | What it is |
|---------|-----------|
| `mybash` | Shell setup + Starship prompt (separate repo, see below) |
| `hypr-stow` | Hyprland window manager config |
| `vicinae-stow` | App launcher |
| `nwg-bar-stow` | Power menu |
| `ghostty-stow` | Terminal |
| `git-stow` | Git settings |
| `fzf-stow` | fzf shell integration |
| `fastfetch-stow` | System info on terminal start |
| `scripts-stow` | Helper scripts (`sweep`, `random-wall.sh`) |
| `gtk-stow` | GTK themes, cursor, fonts |
| `browser-flags-stow` | Wayland flags for Chrome/VS Code |
| `zed-stow` | Zed editor settings |
| `yazi-stow` | yazi TUI file manager |
| `topgrade-stow` | Updates everything in one run (`update`) |

## Install

```bash
git clone --recursive https://github.com/dacrab/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Core shell + tools
stow mybash git-stow fzf-stow scripts-stow \
     ghostty-stow fastfetch-stow browser-flags-stow \
     gtk-stow zed-stow yazi-stow topgrade-stow

# Hyprland desktop
stow hypr-stow vicinae-stow nwg-bar-stow
```

### Stow basics

Each `*-stow` folder holds files that belong in your home folder. Stow links them in, so you keep one copy of your config.

- `stow <package>` — turn a package on
- `stow -R <package>` — refresh after you change a file
- `stow -D <package>` — turn a package off
- `stow --simulate <package>` — preview what would happen

## Helper scripts

| Alias | What it does |
|-------|--------------|
| `sweep` | Frees disk space by cleaning caches, logs, and trash |
| `random-wall.sh` | Sets a random wallpaper (Hyprland) |
| `update` | Runs topgrade (system, runtimes, tools, git repos) |

### Customizing the scripts

A few scripts read a variable from the environment before running. For example:

```bash
DISPLAY_RES=2560x1440@60 display toggle
```

| Script | Variable | What it does | Default |
|--------|----------|--------------|---------|
| random-wall.sh | `WALLPAPER_DIR` | Where your wallpapers live | `$HOME/Pictures/wallpapers` |
| | `WALL_EXT` | Image types to pick from | `jpg jpeg png webp` |
| display | `BUILTIN_PREFIX` | How your laptop's built-in screen appears to Hyprland | `eDP-` |
| | `DISPLAY_RES` | Resolution used when turning a screen back on | `1920x1080@60` |
| mybash | `DOTFILES_DIR` | Where this repo lives (used by `dot` and `dev`) | `$HOME/dotfiles` |
| | `DEV_DIR` | Where you keep your projects (used by `dev`) | `$HOME/Documents/GitHub` |

## Notes

- `mybash` lives in its own repo: [dacrab/mybash](https://github.com/dacrab/mybash)

## License

MIT