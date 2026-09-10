-- Tema Nanuk — colores de Hyprland.
-- Único sitio con acento: el borde de la ventana ACTIVA (hielo). El resto,
-- negro. Se carga tras default/hypr/looknfeel.lua y antes de tu capa user/.

local active_border = "rgb(9fd8ff)"        -- hielo: la ventana con foco
local inactive_border = "rgba(1a1a1aff)"   -- negro: el resto

hl.config({
  general = {
    col = {
      active_border = active_border,
      inactive_border = inactive_border,
    },
  },
  group = {
    col = {
      border_active = active_border,
      border_inactive = inactive_border,
    },
  },
})
