-- Nanuk — orden de carga de la configuración de Hyprland.
-- Cada módulo hace una cosa y está comentado. Lo último que se carga gana.

require("default.hypr.helpers")          -- define n.* (helpers de Nanuk) y n.apps

n.require_optional("user.hypr.apps")     -- tu elección de terminal/browser/etc.
                                         -- ANTES de que se creen los bindings

require("default.hypr.envs")             -- variables de entorno (Wayland, cursor)
require("default.hypr.looknfeel")        -- gaps, bordes, animaciones, layout
require("default.hypr.input")            -- teclado, ratón, touchpad
require("default.hypr.monitors")         -- monitores (default: auto)
require("default.hypr.windows")          -- reglas de ventanas (diálogos, PiP...)
require("default.hypr.bindings")         -- atajos de teclado
require("default.hypr.autostart")        -- waybar, mako, hypridle...

n.require_optional("theme.hyprland")     -- colores del tema activo
n.require_optional("user.hypr.init")     -- TU capa: sobreescribe lo que quieras
