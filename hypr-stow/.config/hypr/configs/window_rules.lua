-- Floats, sizes and layer effects.
local function float(name, match)
  hl.window_rule({ name = name, match = match, float = true })
end

-- Ignore ghost/transient XWayland windows
hl.window_rule({
  name = "ignore-ghost-xwayland",
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },
  no_focus = true,
})

-- Float dialogs & popups
float("float-dialogs", {
  class = "^(pavucontrol|file_progress|confirm|dialog|download|notification|error|splash|confirmreset)$",
})

float("float-titles", {
  title = "^(Open File|Select a file|Choose Files|Save As|Library Preferences|Settings|Preferences|About)$",
})

float("float-cursor", {
  class = "^\\(Cursor\\)$",
})

-- Size & position
hl.window_rule({
  name = "pavucontrol-size",
  match = {
    class = "^(pavucontrol)$",
  },
  size = { 800, 600 },
  center = true,
})

-- Effects: ashell needs no rule here (it publishes its own blur region via
-- ext-background-effect-v1, which Hyprland honours over any layerrule).
hl.layer_rule({
  name = "vicinae-blur",
  match = {
    namespace = "vicinae",
  },
  blur = true,
  ignore_alpha = 0,
})

hl.window_rule({
  name = "suppress-fullscreen-maximize",
  match = {
    float = true,
  },
  suppress_event = "fullscreen maximize",
})
