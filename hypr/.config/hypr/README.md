# 🖼️ Hyprland Configuration

This directory contains the organized Hyprland configuration files for a clean and maintainable setup.

## 📁 Structure

```
hypr/.config/hypr/
├── hyprland.conf          # Main configuration file (sources all others)
├── configs/               # Configuration files organized by category
│   ├── monitors.conf      # Monitor setup and positioning
│   ├── programs.conf      # Application variables and commands
│   ├── environment.conf   # Environment variables
│   ├── autostart.conf     # Applications to start on boot
│   ├── look_and_feel.conf # Visual appearance, animations, decorations
│   ├── layout.conf        # Window layout settings (dwindle, master)
│   ├── input.conf         # Keyboard, mouse, and touchpad settings
│   ├── gestures.conf      # Touchpad gestures configuration
│   ├── devices.conf       # Specific device configurations
│   ├── keybindings.conf   # All keyboard shortcuts and bindings
│   ├── window_rules.conf  # Window-specific rules and behaviors
│   ├── hyprpaper.conf     # Wallpaper configuration
│   └── last_wallpaper     # Current wallpaper state file
└── scripts/               # Utility scripts
    ├── wallpaper          # Wallpaper management (cycle, restore, list, etc.)
    └── display            # Display management (toggle, status, list, etc.)
```

## 🎯 Benefits of This Organization

### ✅ **Modularity**
- Each configuration aspect is in its own file
- Easy to find and modify specific settings
- Reduces conflicts when multiple people work on configs

### ✅ **Maintainability**
- Clear separation of concerns
- Easy to backup individual configuration sections
- Simple to disable/enable specific features

### ✅ **Readability**
- Main `hyprland.conf` is clean and shows the overall structure
- Each config file focuses on one specific area
- Better documentation and comments per section

### ✅ **Version Control**
- Easier to track changes in specific areas
- Better git diffs and conflict resolution
- Cleaner commit history

## 🛠️ Usage

### Editing Configurations
- **Main config**: Edit `hyprland.conf` to change the overall structure
- **Specific settings**: Edit individual files in `configs/` directory
- **Scripts**: Modify scripts in `scripts/` directory

### Adding New Configurations
1. Create a new `.conf` file in `configs/` directory
2. Add `source = ~/.config/hypr/configs/your_file.conf` to `hyprland.conf`
3. Test with `hyprctl reload`

### Reloading Configuration
```bash
# Reload Hyprland configuration
hyprctl reload

# Or restart Hyprland completely
hyprctl dispatch exit
```

## 📝 Configuration Files Explained

### `monitors.conf`
- Monitor detection and positioning
- Resolution and refresh rate settings
- Multi-monitor setup

### `programs.conf`
- Application variables (`$terminal`, `$fileManager`, etc.)
- Command shortcuts and aliases

### `environment.conf`
- Environment variables for Wayland
- Cursor settings and themes
- Hardware acceleration settings

### `autostart.conf`
- Applications to start automatically
- System services and portals
- Environment setup scripts

### `look_and_feel.conf`
- Visual appearance settings
- Window decorations and borders
- Animations and effects
- Blur and transparency settings

### `layout.conf`
- Window layout algorithms (dwindle, master)
- Split behavior and ratios
- Resizing and tiling rules

### `input.conf`
- Keyboard layout and options
- Mouse sensitivity and behavior
- Touchpad settings and gestures

### `gestures.conf.disabled`
- **Note**: Gestures configuration is disabled in Hyprland 0.51.0
- Touchpad gestures are not supported in this version
- File renamed to indicate it's not currently used

### `devices.conf`
- Specific device configurations
- Mouse sensitivity per device
- Custom device settings

### `keybindings.conf`
- All keyboard shortcuts
- Application launchers
- Window management keys
- Media and system controls

### `window_rules.conf`
- Window-specific behaviors
- Floating window rules
- Size and position constraints
- Application-specific settings

## 🚀 Scripts

### `wallpaper` - Wallpaper Management
A unified script for all wallpaper operations:

**Commands:**
- `wallpaper cycle` - Cycle to the next wallpaper (bound to `Super + W`)
- `wallpaper restore` - Restore last wallpaper on startup
- `wallpaper list` - List all available wallpapers
- `wallpaper current` - Show current wallpaper
- `wallpaper set <path>` - Set a specific wallpaper

**Features:**
- Colorized output with status indicators
- Error handling and retry logic
- Support for multiple image formats (PNG, JPG, WEBP)
- Maintains wallpaper state across sessions
- Automatic hyprpaper initialization
- **Material You theming** - Automatically generates colors from wallpapers
- **Dynamic color updates** - Hyprland colors change with each wallpaper

### `display` - Display Management
A unified script for all display operations:

**Commands:**
- `display toggle` - Toggle eDP-1 display on/off (bound to `Super + P`)
- `display status` - Show current display status
- `display list` - List all available displays
- `display enable <name>` - Enable a specific display
- `display disable <name>` - Disable a specific display

**Features:**
- Persistent state management
- Automatic config file updates
- Colorized output with status indicators
- Support for multiple displays
- Backup creation for safety

## 🎨 Material You Theming

This configuration includes **Material You theming** powered by [matugen](https://github.com/InioX/matugen):

### ✨ Features:
- **Dynamic colors** generated from your current wallpaper
- **Automatic theme updates** when cycling wallpapers
- **Material Design 3** color schemes
- **Seamless integration** with Hyprland

### 🔧 How It Works:
1. **Wallpaper changes** trigger matugen color generation
2. **Colors are extracted** from the wallpaper using Material You algorithms
3. **Hyprland colors.conf** is automatically updated
4. **Configuration reloads** to apply new colors instantly

### 🎯 Color Sources:
- **Active borders** - Primary accent color from wallpaper
- **Inactive borders** - Muted variant for inactive windows
- **Background** - Dark surface color
- **Text colors** - High contrast text for readability

### 🛠️ Customization:
- **Color scheme type**: Edit wallpaper script to change `--type` (default: `scheme-tonal-spot`)
- **Theme mode**: Change `--mode` between `dark` and `light`
- **Templates**: Modify `~/.config/matugen/templates/hyprland/colors.conf`

## 🔧 Customization

### Adding New Keybindings
1. Edit `configs/keybindings.conf`
2. Add your binding following the existing format
3. Reload with `hyprctl reload`

### Modifying Animations
1. Edit `configs/look_and_feel.conf`
2. Adjust the `animations` section
3. Test different bezier curves and timing

### Changing Window Rules
1. Edit `configs/window_rules.conf`
2. Add new `windowrulev2` entries
3. Use `hyprctl` to test rules

## 📚 Resources

- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Configuration Reference](https://wiki.hyprland.org/Configuring/Variables/)
- [Keybindings Guide](https://wiki.hyprland.org/Configuring/Binds/)
- [Window Rules](https://wiki.hyprland.org/Configuring/Window-Rules/)

---

**Happy tiling! 🎨**
