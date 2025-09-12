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
    ├── cycle_wallpaper.sh # Cycle through wallpapers
    ├── restore_wallpaper.sh # Restore last wallpaper on startup
    └── toggle-edp.sh      # Toggle external display on/off
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

### `gestures.conf`
- Touchpad gesture recognition
- Workspace switching gestures
- Scroll and navigation gestures

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

### `cycle_wallpaper.sh`
- Cycles through wallpapers in the configured directory
- Bound to `Super + W`
- Maintains wallpaper state across sessions

### `restore_wallpaper.sh`
- Restores the last used wallpaper on startup
- Runs automatically when Hyprland starts
- Handles hyprpaper initialization

### `toggle-edp.sh`
- Toggles the built-in display (eDP-1) on/off
- Bound to `Super + P`
- Useful for external monitor setups

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
