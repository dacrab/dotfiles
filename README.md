# 🎨 dacrab's Dotfiles

> A clean and organized collection of my system configuration files, managed with GNU Stow

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GNU Stow](https://img.shields.io/badge/Managed%20with-GNU%20Stow-blue.svg)](https://www.gnu.org/software/stow/)

## 📋 Overview

This repository contains my personal dotfiles for a Linux desktop environment, featuring configurations for:

- **🖼️ Hyprland** - Dynamic tiling Wayland compositor
- **🎛️ Hyprpanel** - Modern panel for Hyprland
- **🔍 Rofi** - Application launcher and window switcher
- **🐚 MyBash** - Custom bash configuration with Starship prompt

All configurations are managed using [GNU Stow](https://www.gnu.org/software/stow/) for clean symlink management.

## 🚀 Quick Start

### Prerequisites

- GNU Stow (install with your package manager)
- Linux system with Wayland support (for Hyprland)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/dacrab/dotfiles.git
   cd dotfiles
   ```

2. **Install all configurations:**
   ```bash
   stow hypr hyprpanel rofi mybash-stow
   ```

3. **Or install specific packages:**
   ```bash
   stow hypr        # Hyprland configuration
   stow hyprpanel   # Hyprpanel configuration
   stow rofi        # Rofi configuration
   stow mybash-stow # Bash configuration with Starship
   ```

## 📁 Structure

```
dotfiles/
├── hypr/
│   └── .config/
│       └── hypr/
│           ├── hyprland.conf      # Main Hyprland configuration
│           ├── hyprpaper.conf     # Wallpaper configuration
│           ├── last_wallpaper     # Current wallpaper tracking
│           └── scripts/           # Custom scripts
│               ├── cycle_wallpaper.sh
│               ├── restore_wallpaper.sh
│               └── toggle-edp.sh
├── hyprpanel/
│   └── .config/
│       └── hyprpanel/
│           ├── config.json        # Panel configuration
│           ├── modules.json       # Module definitions
│           └── modules.scss       # Styling
├── rofi/
│   └── .config/
│       └── rofi/
│           └── config.rasi        # Rofi theme and configuration
├── themes/
│   ├── tokyo-night/               # Sample theme (Hypr + Rofi overrides)
│   └── nord/                      # Sample theme
├── bin/
│   ├── dotfiles-theme-set         # Switch to a named theme
│   ├── dotfiles-theme-next        # Cycle to next theme
│   └── dotfiles-theme-setup       # Initialize theme links
├── mybash-stow/
│   ├── .bashrc                    # Custom bash configuration
│   └── .config/
│       └── starship/
│           └── starship.toml      # Starship prompt configuration
├── mybash/                        # Git submodule (original mybash repo)
│   └── [original mybash files]
└── README.md
```

## 🛠️ Management Commands

### Install Packages
```bash
# Install all packages
stow hypr hyprpanel rofi mybash-stow

# Install specific package
stow hypr
stow mybash-stow
```

### Uninstall Packages
```bash
# Uninstall specific package
stow -D hypr

# Uninstall all packages
stow -D hypr hyprpanel rofi mybash-stow
```

### Reinstall Packages
```bash
# Reinstall (useful after updates)
stow -R hypr hyprpanel rofi mybash-stow
```

### Dry Run (Preview Changes)
```bash
# See what would be installed without making changes
stow --simulate hypr
```

## 🎨 Features

### Hyprland Configuration
- **Dynamic tiling** with customizable layouts
- **Smooth animations** and transitions
- **Multi-monitor support** with proper workspace management
- **Custom keybindings** for productivity
- **Wallpaper management** with cycling scripts

### Hyprpanel
- **Modern design** with clean aesthetics
- **Customizable modules** for system information
- **Responsive layout** that adapts to different screen sizes
- **SCSS theming** for easy customization

### Rofi
- **Application launcher** with fuzzy search
- **Window switcher** for easy navigation
- **Custom theme** matching the overall design
- **Fast and lightweight** performance

## 🔧 Customization

Each configuration is designed to be easily customizable:

1. **Hyprland**: Edit `hypr/.config/hypr/hyprland.conf`
2. **Hyprpanel**: Modify `hyprpanel/.config/hyprpanel/config.json`
3. **Rofi**: Update `rofi/.config/rofi/config.rasi`

### Theming (Omarchy-style)

1. Initialize links:
   ```bash
   ~/dotfiles/bin/dotfiles-theme-setup
   ```
2. Switch theme by name:
   ```bash
   ~/dotfiles/bin/dotfiles-theme-set tokyo-night
   ```
3. Cycle themes:
   ```bash
   ~/dotfiles/bin/dotfiles-theme-next
   ```

What it does:
- Maintains `~/.config/dotfiles/current/theme -> ~/.config/dotfiles/themes/<name>`
- Links Hypr colors to `~/.config/hypr/hyprland/colors.conf` and reloads Hypr
- Rofi dynamically imports `~/.config/dotfiles/current/theme/rofi/override.rasi`
- Optionally links per-app theme files if present in a theme directory:
  - `waybar.css` via `~/.config/waybar/style.css` import
  - `kitty.conf` via `include ~/.config/dotfiles/current/theme/kitty.conf`
  - `ghostty.conf` via `config-file = ?"~/.config/dotfiles/current/theme/ghostty.conf"`
  - `mako.ini`, `eza.yml`, `btop.theme`
  - `icons.theme` (GNOME icon theme name), `light.mode` (toggle light/dark)
  - `backgrounds/` for wallpaper selection and cycling

GTK integration:
- GTK3/4 theme and color-scheme are set with `gsettings` to Adwaita/Adwaita-dark depending on presence of `light.mode` in the selected theme.
- GTK2 fallback is written to `~/.gtkrc-2.0` with Adwaita to give legacy apps a consistent look.

Background cycling:
- Use `~/dotfiles/bin/dotfiles-theme-bg-next` to cycle to the next background found in the current theme’s `backgrounds/` directory. The current background is symlinked to `~/.config/background`.

After making changes, reinstall the package:
```bash
stow -R <package-name>
```

## 📝 Scripts

The Hyprland configuration includes several useful scripts:

- **`cycle_wallpaper.sh`** - Cycle through wallpapers
- **`restore_wallpaper.sh`** - Restore the last wallpaper
- **`toggle-edp.sh`** - Toggle external display

## 🤝 Contributing

While this is a personal configuration, suggestions and improvements are welcome! Feel free to:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Hyprland](https://hyprland.org/) - Amazing Wayland compositor
- [GNU Stow](https://www.gnu.org/software/stow/) - Elegant symlink management
- The open-source community for inspiration and tools

---

**Happy coding! 🚀**

*Last updated: December 12, 2024*