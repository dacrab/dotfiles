-- Hyprland main config — modular: requires ./hyprland/colors.lua and ./configs/*.lua.

-- Modules
require("hyprland/colors")
require("configs/environment")
require("configs/input")
require("configs/keybindings")
require("configs/look_and_feel")
require("configs/window_rules")

-- Monitors (hardware-specific)
hl.monitor({
  output = "HDMI-A-1",
  mode = "1920x1080@74.97",
  position = "0x0",
  scale = 1,
})

hl.monitor({
  output = "eDP-1",
  disabled = true,
})

-- Autostart
hl.on("hyprland.start", function()
  hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/session-init")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/random-wall.sh")
  hl.exec_cmd("vicinae server")
  hl.exec_cmd("wayle panel start")
end)
