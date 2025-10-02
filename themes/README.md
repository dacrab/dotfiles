Dotfiles Theming

Structure per theme directory (examples):

- hypr/
  - hyprland.colors.conf
  - hyprlock.colors.conf
- rofi/
  - override.rasi
- hyprpanel/
  - modules.scss (optional)
- backgrounds/
  - 1-sample.jpg (optional)

Switching themes updates `~/.config/dotfiles/current/theme` and links Hypr color files and optional Hyprpanel stylesheet, then reloads Hypr.


