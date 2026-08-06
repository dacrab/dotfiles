# dotfiles

My Linux environment, managed with GNU Stow. Covers my desktop (Hyprland/Niri), terminals, shell, and the little scripts I run daily.

## What's here

| Package | What it is |
|---------|-----------|
| `mybash` | Bash config + Starship prompt (separate repo, see below) |
| `hypr-stow` | Hyprland compositor config |
| `niri-stow` | Niri compositor config |
| `wayle-stow` / `waybar-stow` | Panels for Hyprland / Niri |
| `wofi-stow` / `vicinae-stow` / `fuzzel-stow` | App launchers |
| `nwg-bar-stow` | Power menu |
| `ghostty-stow` | Terminal |
| `git-stow` | Global git config |
| `fzf-stow` | fzf shell integration |
| `fastfetch-stow` | System info at shell start |
| `scripts-stow` | Helper scripts (`sweep`, `wall`, `update`) |
| `ssh-stow` | SSH config and public keys |
| `gtk-stow` | GTK themes, cursor, fonts |
| `browser-flags-stow` | Chrome/VS Code Wayland flags |
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

- Refresh a package after changes: `stow -R <package>`
- Remove it: `stow -D <package>`
- Dry run first: `stow --simulate <package>`

## Helper scripts

| Alias | Script | What it does |
|-------|--------|--------------|
| `sweep` | sweep.sh | Cleans caches, logs, trash, dev artifacts, containers |
| `wall` | random-wall.sh | Sets a random wallpaper (Hyprland, Niri, GNOME) |
| `update` | update.sh | Updates packages, runtimes, and tools |

## Notes

- `mybash` lives in its own repo: [dacrab/mybash](https://github.com/dacrab/mybash)

## License

MIT
