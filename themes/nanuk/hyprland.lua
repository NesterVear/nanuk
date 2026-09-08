-- Tema Nanuk — colores de Hyprland.
-- Se carga DESPUÉS de default/hypr/looknfeel.lua y ANTES de tu capa user/,
-- así el tema solo aporta colores y tú puedes cambiar cualquiera después.
-- Ver colors.toml para la paleta completa.

local active_border = "rgb(9fd8ff)"       -- hielo: la ventana con foco
local inactive_border = "rgba(2a2a2aaa)"  -- casi negro: el resto

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
