-- Nanuk — monitores (default: todos en su modo preferido, sin escalar).
-- Configura los tuyos en ~/.config/nanuk/user/hypr/monitors.lua (hay plantilla
-- con el ejemplo laptop + HDMI).
-- Lista lo que hay con:  hyprctl monitors all

hl.env("GDK_SCALE", "1")

hl.monitor({
  output = "",            -- "" = regla para cualquier monitor
  mode = "preferred",
  position = "auto",
  scale = 1,
})
