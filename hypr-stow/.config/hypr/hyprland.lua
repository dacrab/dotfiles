-- Hyprland main config — modular: ./configs/*.lua, with colors required by
-- look_and_feel.lua.

require("configs/environment")
require("configs/input")
require("configs/keybindings")
require("configs/look_and_feel")
require("configs/window_rules")

-- Monitors (hardware-specific)
--
-- HDMI-A-1: Philips PHL 271V8, 27". Native max is 1920x1080@74.97.
-- Primary output, pinned at the origin.
hl.monitor({
  output = "HDMI-A-1",
  mode = "1920x1080@74.97",
  position = "0x0",
  scale = 1,
})

-- eDP-1: BOE 0x08E7 laptop panel. Max is 1920x1080@60 (60Hz is its ceiling),
-- scaled to 1.5 for HiDPI since the panel is only ~15". Disabled by default;
-- toggle with SUPER+P, which re-applies this same mode/position/scale.
hl.monitor({
  output = "eDP-1",
  mode = "1920x1080@60",
  position = "1920x0",
  scale = 1.5,
  disabled = true,
})

-- Autostart
hl.on("hyprland.start", function()
  hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/session-init")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/random-wall")
  hl.exec_cmd("vicinae server --replace")
  hl.exec_cmd("ashell")
end)
