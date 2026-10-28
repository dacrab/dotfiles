# dotfiles

My Linux desktop, managed with [Stow](https://www.gnu.org/software/stow/).

| Package | What it is |
| ------- | ---------- |
| `hypr-stow` | Hyprland window manager |
| `ashell-stow` | Desktop bar + notifications |
| `vicinae-stow` | App launcher |
| `nwg-bar-stow` | Power menu (logout/reboot/shutdown) |
| `ghostty-stow` | Terminal |
| `gtk-stow` | GTK theme, cursor, fonts |
| `git-stow` | Git settings |
| `gh-stow` | GitHub CLI settings |
| `fastfetch-stow` | System info shown when a terminal opens |
| `atuin-stow` | Shell history settings |
| `zed-stow` | Zed editor |
| `editor-stow` | VS Code settings (kept for backup) |
| `yazi-stow` | Terminal file manager |
| `opencode-stow` | opencode (AI coding agent) config |
| `mimocode-stow` | mimocode (AI coding agent) config |
| `pi-stow` | Pi (oh-my-pi) config; credentials and runtime state stay outside the repo |
| `topgrade-stow` | One-command system updater |
| `scripts-stow` | Helper scripts (see below) |
| `mybash` | Shell setup + prompt (separate repo) |

## Install

```bash
git clone --recursive https://github.com/dacrab/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow mybash git-stow gh-stow scripts-stow ghostty-stow fastfetch-stow \
     atuin-stow gtk-stow zed-stow yazi-stow topgrade-stow editor-stow \
     opencode-stow mimocode-stow pi-stow
stow hypr-stow ashell-stow vicinae-stow nwg-bar-stow   # desktop
```

Each `*-stow` folder links its files into `$HOME`, so there is one copy of
every config and it stays under version control.

- `stow <package>` turns a package on; `stow -D <package>` turns it off
- `stow -R <package>` refreshes links after adding or removing files
- `stow --simulate <package>` previews without changing anything

## Helper scripts

| Script | What it does |
| ------ | ------------ |
| `sweep` | Frees disk space: caches, logs, old trash. `sweep --dry-run` previews |
| `random-wall` | Sets a random wallpaper (Hyprland, GNOME, Cinnamon, XFCE, sway) |
| `display` | Toggle/enable/disable a monitor, e.g. `display toggle` for the laptop panel |
| `update` | Updates everything in one run (system packages, flatpaks, tools, git repos) |
| `update-*` | Per-tool updaters called by `update`; each one works standalone |

Every script detects what is installed and skips the rest, so they behave the
same on another distro or desktop. Behaviour can be overridden by environment:

| Variable | Used by | Controls | Default |
| -------- | ------- | -------- | ------- |
| `SWEEP_TRASH_DAYS` | sweep | Empty trash only after N days (0 = never) | `7` |
| `SWEEP_JOURNAL_AGE` | sweep | Age before system logs are vacuumed | `3d` |
| `SWEEP_COREDUMP_DAYS` | sweep | Age before crash dumps are deleted | `7` |
| `SWEEP_CONTAINERS` | sweep | `1` = also prune stopped containers | off |
| `SWEEP_FLATPAK_UNUSED` | sweep | `0` = keep unused runtimes | `1` |
| `WALLPAPER_DIR` | random-wall | Where wallpapers live | `~/Pictures/wallpapers` |
| `WALL_EXT` | random-wall | File types to pick from | `jpg jpeg png webp` |
| `BUILTIN_PREFIX` | display | Name of the laptop panel | `eDP-` |
| `DISPLAY_MODE` / `DISPLAY_SCALE` | display | Override mode/scale when re-enabling | panel max |
| `HYPR_MONITOR_MAIN` / `HYPR_MONITOR_INTERNAL` | hyprland.lua | Output names | `HDMI-A-1` / `eDP-1` |

`mybash` reads `DOTFILES_DIR` (default `~/dotfiles`) and `DEV_DIR` (default
`~/Documents/GitHub`) for the `dot` and `dev` aliases.

## Notes

- `mybash` lives in its own repo: [dacrab/mybash](https://github.com/dacrab/mybash)

## License

MIT
