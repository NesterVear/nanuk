-- Nanuk — entrada de la configuración de Hyprland. NO EDITAR ESTE ARCHIVO:
-- se reemplaza en cada update. Personaliza en ~/.config/nanuk/user/hypr/,
-- que se carga al final y por tanto gana sobre todo lo demás.
--
-- Orden de carga (ver default/hypr/init.lua):
--   default/hypr/*  →  theme/hyprland.lua  →  user/hypr/init.lua

local home = os.getenv("HOME")
local nanuk = home .. "/.config/nanuk"

-- Al recargar (hyprctl reload), Hyprland vuelve a ejecutar este archivo, pero
-- `require` cachea cada módulo en package.loaded y NO lo re-ejecutaría. Vaciamos
-- la caché de nuestros prefijos para que los cambios se apliquen al recargar.
for name in pairs(package.loaded) do
  if name:match("^default%.") or name:match("^user%.") or name:match("^theme%.") then
    package.loaded[name] = nil
  end
end

-- Dónde busca `require`:  require("default.hypr.init")
--   → ~/.config/nanuk/default/hypr/init.lua
-- El symlink ~/.config/nanuk/theme hace que "theme.hyprland" apunte al tema activo.
package.path = nanuk .. "/?.lua;" .. nanuk .. "/?/init.lua;" .. package.path

require("default.hypr.init")
