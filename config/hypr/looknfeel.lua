-- Nanuk — apariencia: gaps, bordes, esquinas, animaciones, layout.
-- Los COLORES no van aquí: los pone el tema (theme/hyprland.lua).
-- Referencia: https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 1,

    resize_on_border = true,        -- arrastrar el borde redimensiona
    extend_border_grab_area = 12,   -- ...con un margen cómodo
    allow_tearing = false,
    layout = "dwindle",

    -- Estilo Windows: al arrastrar una ventana flotante, se imanta a los
    -- bordes de otras ventanas y del monitor.
    snap = {
      enabled = true,
      window_gap = 10,
      monitor_gap = 10,
      border_overlap = false,
    },

    -- Estilo Windows: un diálogo modal bloquea a su ventana padre.
    modal_parent_blocking = true,
  },

  decoration = {
    rounding = 0,            -- esquinas rectas, como Vantablack
    active_opacity = 1.0,
    inactive_opacity = 1.0,

    shadow = { enabled = false },
    blur = { enabled = false },
  },

  animations = { enabled = true },

  dwindle = {
    preserve_split = true,   -- el split no cambia al cerrar ventanas
    force_split = 2,         -- nuevas ventanas siempre a la derecha/abajo
  },

  master = {
    new_status = "master",
  },

  misc = {
    -- Fondo negro puro pintado por Hyprland: no hace falta hyprpaper.
    background_color = "rgb(000000)",
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    disable_scale_notification = true,

    focus_on_activate = true,        -- una app que pide foco lo recibe
    on_focus_under_fullscreen = 1,
    initial_workspace_tracking = 0,
    anr_missed_pings = 3,
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
    allow_session_lock_restore = true,
  },

  cursor = {
    hide_on_key_press = true,
    warp_on_change_workspace = 1,
  },

  binds = {
    hide_special_on_workspace_change = true,
  },
})

-- ── Animaciones: cortas y sobrias ───────────────────────────────────
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 3.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "fadeSwitch", enabled = false })
hl.animation({ leaf = "layers", enabled = false })         -- barra/launcher: instantáneos
hl.animation({ leaf = "workspaces", enabled = false })     -- cambio de workspace: instantáneo
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidevert" })
