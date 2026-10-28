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

    -- Trimmed for the Vega 3 iGPU: one blur pass, smaller kernel, no noise.
    blur = {
      enabled = true,
      size = 3,
      passes = 1,
      new_optimizations = true,
      noise = 0,
    },

    -- Softer and cheaper than 12/3: the wider the range and the higher the
    -- render power, the more of the frame budget the shadow eats while
    -- windows are animating on the Vega 3.
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

-- Curves
--
-- Two curves cover every motion; unset leaves fall back to Hyprland's
-- `default` (0, 0.75, 0.15, 1), which is already a good decelerating curve.
-- Times are deciseconds (1 = 100ms). This panel runs at 74.97Hz, so anything
-- above ~3ds (30 frames) visibly steps instead of glides.
hl.curve("smooth", { type = "bezier", points = { { 0.2, 0.0 }, { 0.0, 1.0 } } }) -- fast start, long settle
hl.curve("soft", { type = "bezier", points = { { 0.4, 0.0 }, { 0.2, 1.0 } } })   -- gentler, for fades

-- Windows
-- `popin 92%` keeps the open/close motion almost imperceptible; no overshoot
-- curve on close, so windows shrink away instead of dipping past their size.
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "smooth", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "smooth", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "smooth" })

-- Fades: all in lockstep at 250ms so open/close/switch read as one motion.
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.5, bezier = "soft" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.5, bezier = "soft" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 2.5, bezier = "soft" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 3, bezier = "soft" })

-- Popups (GTK4 menus, tooltips, Zed/Vicinae dropdowns) are alpha-only in
-- Hyprland, so a long fade just feels laggy. Left unset they inherit `global`
-- (8ds = 800ms).
hl.animation({ leaf = "fadePopups", enabled = true, speed = 2, bezier = "soft" })

-- Workspaces: shorter slide and less travel; 4ds/20% read as a glide here.
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "smooth", style = "slidefade 12%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "smooth", style = "slidefadevert -12%" })

-- Border: must not lag behind fadeSwitch, or focus looks half-updated.
hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "soft" })

-- Layer surfaces (ashell bar/menus/OSD/toasts, vicinae, notifications).
-- ashell animates its own content with iced_anim, so scaling the surface
-- itself (popin 80%) made the two animations fight. Hyprland only fades the
-- surface in; the shell owns the motion inside it.
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "soft", style = "fade" })

-- fadeLayers is separate from `layers` and unset by default: it inherits the
-- `fade` branch (3ds), which stacked on top of the 2ds layer fade and made
-- ashell surfaces settle twice. Keep it at a single frame.
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 1, bezier = "linear" })
