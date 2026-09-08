-- Nanuk — TU capa de Hyprland. Este archivo se creó una vez al instalar y
-- el instalador NUNCA lo vuelve a tocar. Se carga al final, así que todo lo
-- que pongas aquí (o en los archivos que carga) gana sobre los defaults.
--
-- Recarga con:  hyprctl reload
-- Autocompletado en el editor: hay un .luarc.json en ~/.config/nanuk/.

n.require_optional("user.hypr.monitors")
n.require_optional("user.hypr.input")
n.require_optional("user.hypr.looknfeel")
n.require_optional("user.hypr.windows")
n.require_optional("user.hypr.bindings")
n.require_optional("user.hypr.autostart")

-- ¿Un archivo nuevo? Créalo en esta carpeta y añade su require aquí:
-- n.require_optional("user.hypr.trabajo")
