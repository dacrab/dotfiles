# dotfiles

My Linux desktop setup, kept in one place and managed with [Stow](https://www.gnu.org/software/stow/). It covers the window manager I use (Hyprland), my terminal, shell, and a few helper scripts for everyday tasks.

## What's here

| Package | What it is |
| ------- | ---------- |
| `mybash` | Shell setup + prompt (separate repo, see below) |
| `hypr-stow` | Hyprland window manager |
| `wayle-stow` | Desktop bar/shell |
| `vicinae-stow` | App launcher |
| `nwg-bar-stow` | Power menu (logout/reboot/shutdown) |
| `ghostty-stow` | Terminal |
| `git-stow` | Git settings |
| `gh-stow` | GitHub CLI settings |
| `fastfetch-stow` | System info shown when a terminal opens |
| `scripts-stow` | Helper scripts (`sweep`, `random-wall.sh`) |
| `gtk-stow` | GTK theme, cursor, fonts |
| `atuin-stow` | Shell history settings |
| `zed-stow` | Zed editor |
| `editor-stow` | VS Code settings (kept for backup) |
| `yazi-stow` | Terminal file manager |
| `opencode-stow` | opencode (AI coding agent) config |
| `mimocode-stow` | mimocode (AI coding agent) config |
| `topgrade-stow` | One-command system updater |

## Install

```bash
git clone --recursive https://github.com/dacrab/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Core shell + tools
stow mybash git-stow gh-stow scripts-stow \
     ghostty-stow fastfetch-stow atuin-stow \
     gtk-stow zed-stow yazi-stow topgrade-stow \
     editor-stow opencode-stow mimocode-stow

# Hyprland desktop
stow hypr-stow wayle-stow vicinae-stow nwg-bar-stow
```

Each `*-stow` folder links its files into your home folder, so you keep one copy of every config and it stays under version control:

- `stow <package>` — turn a package on
- `stow -R <package>` — refresh links after you add/remove files
- `stow -D <package>` — turn a package off
- `stow --simulate <package>` — preview before doing anything

## Helper scripts

| Alias | What it does |
| ----- | ------------ |
| `sweep` | Frees disk space by clearing caches, logs, and old trash. Use `sweep --dry-run` to preview first |
| `update` | Updates everything in one run (system packages, flatpaks, tools, git repos) |
| `random-wall.sh` | Sets a random wallpaper (Hyprland and GNOME) |

### Tweaking their behavior

The scripts read a few variables from the environment if you want to change how they behave. For example:

```bash
DISPLAY_RES=2560x1440@60 display toggle
```

| Script | Variable | What it controls | Default |
| ------ | -------- | ---------------- | ------- |
| sweep | `SWEEP_TRASH_DAYS` | Empty the trash only after N days (0 = never) | `7` |
| | `SWEEP_JOURNAL_AGE` | How old system logs can get before they're removed | `3d` |
| | `SWEEP_COREDUMP_DAYS` | How old crash reports can get before they're removed | `7` |
| | `SWEEP_DOCKER` | `1` = also clean up stopped Docker containers | off |
| random-wall.sh | `WALLPAPER_DIR` | Folder to pick wallpapers from | `~/Pictures/wallpapers` |
| | `WALL_EXT` | File types to pick from | `jpg jpeg png webp` |
| display | `BUILTIN_PREFIX` | Name of the laptop's built-in screen | `eDP-` |
| | `DISPLAY_RES` | Screen resolution when turning it back on | `1920x1080@60` |
| mybash | `DOTFILES_DIR` | Where this repo lives (used by `dot` and `dev`) | `~/dotfiles` |
| | `DEV_DIR` | Where your projects live (used by `dev`) | `~/Documents/GitHub` |

## Notes

- `mybash` lives in its own repo: [dacrab/mybash](https://github.com/dacrab/mybash)

## License

MIT
