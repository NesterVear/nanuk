-- Nanuk — teclado, ratón y touchpad (defaults neutros).
-- Tus ajustes van en ~/.config/nanuk/user/hypr/input.lua (hay plantilla).
-- Referencia: https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",

    follow_mouse = 1,     -- el foco sigue al ratón
    sensitivity = 0,      -- -1.0 a 1.0; 0 = sin cambio

    repeat_rate = 40,
    repeat_delay = 300,
    numlock_by_default = true,

    touchpad = {
      natural_scroll = false,
      clickfinger_behavior = true,   -- 2 dedos = clic derecho
      scroll_factor = 0.5,
    },
  },
})
