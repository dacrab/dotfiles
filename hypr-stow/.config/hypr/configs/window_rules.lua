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

-- Minecraft (native Wayland via GLFW): let the game manage its own fullscreen
hl.window_rule({
  name = "minecraft-fullscreen",
  match = {
    class = "^(minecraft|MC26\.2)$",
  },
  suppress_event = "fullscreen maximize",
})

-- Float dialogs & popups
hl.window_rule({
  name = "float-dialogs",
  match = {
    class = "^(pavucontrol|file_progress|confirm|dialog|download|notification|error|splash|confirmreset)$",
  },
  float = true,
})

hl.window_rule({
  name = "float-titles",
  match = {
    title = "^(Open File|Select a file|Choose Files|Save As|Library Preferences|Settings|Preferences|About)$",
  },
  float = true,
})

hl.window_rule({
  name = "float-cursor",
  match = {
    class = "^(\\(Cursor\\))$",
  },
  float = true,
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

-- Effects
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
