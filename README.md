# dotfiles

My Linux desktop setup, kept in one place and managed with [Stow](https://www.gnu.org/software/stow/). It covers the window managers I use (Hyprland and Niri), terminals, shell, and a few helper scripts for everyday tasks.

## What's here

| Package | What it is |
|---------|-----------|
| `mybash` | Shell setup + Starship prompt (separate repo, see below) |
| `hypr-stow` | Hyprland window manager config |
| `niri-stow` | Niri window manager config |
| `wayle-stow` / `waybar-stow` | Top panels for Hyprland / Niri |
| `wofi-stow` / `vicinae-stow` / `fuzzel-stow` | App launchers |
| `nwg-bar-stow` | Power menu |
| `ghostty-stow` | Terminal |
| `git-stow` | Git settings |
| `fzf-stow` | fzf shell integration |
| `fastfetch-stow` | System info on terminal start |
| `scripts-stow` | Helper scripts (`sweep`, `wall`, `update`) |
| `ssh-stow` | SSH config and public keys |
| `gtk-stow` | GTK themes, cursor, fonts |
| `browser-flags-stow` | Wayland flags for Chrome/VS Code |
| `zed-stow` | Zed editor settings |

## Install

```bash
git clone --recursive https://github.com/dacrab/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Core shell + tools
stow mybash git-stow fzf-stow scripts-stow ssh-stow \
     ghostty-stow fastfetch-stow browser-flags-stow \
     gtk-stow zed-stow

# Hyprland desktop
stow hypr-stow wayle-stow vicinae-stow wofi-stow nwg-bar-stow

# Niri desktop
stow niri-stow waybar-stow fuzzel-stow
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
| `sweep` | Frees disk space by cleaning caches, logs, trash, and containers |
| `wall` | Sets a random wallpaper (Hyprland, Niri, GNOME) |
| `update` | Updates your system, runtimes, and tools |

### Customizing the scripts

You can tweak how the scripts behave by setting a variable before running them. For example:

```bash
SWEEP_JOURNAL_DAYS=7 sweep           # keep a week of system logs
DISPLAY_RES=2560x1440@60 display toggle
```

| Script | Variable | What it does | Default |
|--------|----------|--------------|---------|
| sweep | `SWEEP_MIN_KB` | Skip cleaning anything under this size (KB) | `100` |
| | `SWEEP_JOURNAL_DAYS` | Keep system logs for this many days | `3` |
| | `SWEEP_TRASH_DAYS` | Empty trash older than this many days | `7` |
| | `SWEEP_TOOL_CACHES` | Tool cache folders to clean | `node-gyp deno biome gopls typescript prisma` |
| | `SWEEP_EDITORS` | Editor config folders to clean | `Code Cursor Windsurf VSCodium` |
| | `SWEEP_STATE_DIRS` | State folders to clean | `less vimundo nvim/undo nvim/swap nvim/shada` |
| update | `REPOS_DIR` | Where to look for git repos to update | `$HOME/Documents/GitHub` |
| wall | `WALLPAPER_DIR` | Where your wallpapers live | `$HOME/Pictures/wallpapers` |
| | `WALL_EXT` | Image types to pick from | `jpg jpeg png webp` |
| display | `BUILTIN_PREFIX` | How your laptop's built-in screen appears to Hyprland | `eDP-` |
| | `DISPLAY_RES` | Resolution used when turning a screen back on | `1920x1080@60` |
| | `DISPLAY_POS` | Screen position | `0x0` |
| mybash | `DOTFILES_DIR` | Where this repo lives (used by `dot` and `eb`) | `$HOME/dotfiles` |
| | `DEV_DIR` | Where you keep your projects (used by `dev`) | `$HOME/Documents/GitHub` |

## Notes

- `mybash` lives in its own repo: [dacrab/mybash](https://github.com/dacrab/mybash)

## License

MIT