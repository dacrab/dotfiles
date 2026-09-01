local colors = require("hyprland/colors")

-- General
hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,
    resize_on_border = true,
    hover_icon_on_border = true,
    extend_border_grab_area = 15,
    layout = "dwindle",

    col = {
      active_border = colors.color4,
      inactive_border = colors.color0,
      nogroup_border = colors.color8,
    },
  },
})

-- Decoration
hl.config({
  decoration = {
    rounding = 10,
    rounding_power = 2.0,
    inactive_opacity = 0.92,
    dim_inactive = true,
    dim_strength = 0.1,

    blur = {
      enabled = true,
      size = 4,
      passes = 2,
      new_optimizations = true,
      noise = 0.02,
    },

    shadow = {
      enabled = true,
      range = 12,
      render_power = 3,
      color = "rgba(00000055)",
    },
  },
})

-- Animations
hl.config({
  animations = {
    enabled = true,
  },
})

hl.curve("snappy", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.0 } } })
hl.curve("smooth", { type = "bezier", points = { { 0.25, 1.0 }, { 0.5, 1.0 } } })
hl.curve("softOut", { type = "bezier", points = { { 0.36, 0.0 }, { 0.66, -0.56 } } })
hl.curve("popIn", { type = "bezier", points = { { 0.0, 0.8 }, { 0.2, 1.0 } } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "popIn", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "softOut", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "smooth" })

hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "smooth" })

hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "snappy", style = "slidefade 20%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "snappy", style = "slidefadevert -20%" })

hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "smooth" })

hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "popIn", style = "popin 80%" })
