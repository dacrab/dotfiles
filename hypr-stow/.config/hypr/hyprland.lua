-- Hyprland main config; the modules live in ./configs.

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
  output = os.getenv("HYPR_MONITOR_MAIN") or "HDMI-A-1",
  mode = "1920x1080@74.97",
  position = "0x0",
  scale = 1,
})

-- eDP-1: BOE 0x08E7 laptop panel. Max is 1920x1080@60 (60Hz is its ceiling),
-- scaled to 1.5 for HiDPI since the panel is only ~15". Disabled by default;
-- toggle with SUPER+P, which re-applies this same mode/position/scale.
hl.monitor({
  output = os.getenv("HYPR_MONITOR_INTERNAL") or "eDP-1",
  mode = "1920x1080@60",
  position = "1920x0",
  scale = 1.5,
  disabled = true,
})

-- Autostart. Each entry is skipped when the program is missing, so this
-- config still starts on a machine without vicinae/ashell/hyprpaper.
local function autostart(program, args)
  hl.exec_cmd(
    "command -v " .. program .. " >/dev/null && exec " .. program .. (args and (" " .. args) or "")
  )
end

hl.on("hyprland.start", function()
  hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/session-init")
  autostart("hyprpaper")
  autostart(os.getenv("HOME") .. "/.local/bin/random-wall")
  autostart("vicinae", "server --replace")
  autostart("ashell")
end)
