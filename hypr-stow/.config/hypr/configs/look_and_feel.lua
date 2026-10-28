local colors = require("hyprland/colors")

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

  decoration = {
    rounding = 10,
    rounding_power = 2.0,
    inactive_opacity = 0.92,
    dim_inactive = true,
    dim_strength = 0.1,

    -- Tuned down for the Vega 3 iGPU: one blur pass, smaller kernel, no noise.
    blur = {
      enabled = true,
      size = 3,
      passes = 1,
      new_optimizations = true,
      noise = 0,
    },

    -- Cheaper than 12/3; the shadow competes with window animation for frames.
    shadow = {
      enabled = true,
      range = 8,
      render_power = 2,
      color = "rgba(00000040)",
    },
  },

  animations = {
    enabled = true,
  },
})

-- Times are deciseconds. Unset leaves fall back to `default` (0, 0.75, 0.15, 1).
-- This panel is 74.97Hz, so anything above ~3ds visibly steps.
hl.curve("smooth", { type = "bezier", points = { { 0.2, 0.0 }, { 0.0, 1.0 } } })
hl.curve("soft", { type = "bezier", points = { { 0.4, 0.0 }, { 0.2, 1.0 } } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "smooth", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "smooth", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "smooth" })

-- Fades in lockstep at 250ms so open/close/switch read as one motion.
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.5, bezier = "soft" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.5, bezier = "soft" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 2.5, bezier = "soft" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 3, bezier = "soft" })

-- Popups are alpha-only; unset they inherit `global` (8ds = 800ms), which lags.
hl.animation({ leaf = "fadePopups", enabled = true, speed = 2, bezier = "soft" })

hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "smooth", style = "slidefade 12%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "smooth", style = "slidefadevert -12%" })

-- Must not lag behind fadeSwitch, or focus looks half-updated.
hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "soft" })

-- Fade only: ashell animates its own content, so scaling the surface too made
-- the two animations fight.
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "soft", style = "fade" })

-- Separate from `layers` and unset by default; it would inherit the 3ds fade
-- branch and make ashell surfaces settle twice.
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 1, bezier = "linear" })
