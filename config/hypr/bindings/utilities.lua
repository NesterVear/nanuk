-- Nanuk — utilidades: capturas, portapapeles, bloqueo, apagado, barra.

-- Chuleta de atajos de teclado (también en el icono 󰌌 de la barra).
n.bind("SUPER + K", "Atajos de teclado", "nanuk-keys")

-- Sistema.
n.bind("SUPER + ESCAPE", "Menú de energía", n.apps.power_menu)
n.bind("SUPER + CTRL + L", "Bloquear pantalla", "hyprlock")

-- Capturas (hyprshot guarda en ~/Pictures y copia al portapapeles).
n.bind("PRINT", "Captura de región", "hyprshot -m region")
n.bind("SHIFT + PRINT", "Captura de pantalla completa", "hyprshot -m output")
n.bind("SUPER + PRINT", "Selector de color", "pkill hyprpicker || hyprpicker -a")

-- Portapapeles con historial (cliphist), elegido con fuzzel. cliphist da
-- "id<TAB>texto": se muestra solo el texto y fuzzel devuelve la línea entera.
n.bind("SUPER + CTRL + V", "Historial del portapapeles",
  "cliphist list | fuzzel --dmenu --with-nth 2 --prompt 'portapapeles ❯ ' | cliphist decode | wl-copy")

-- Notificaciones (mako).
n.bind("SUPER + comma", "Cerrar última notificación", "makoctl dismiss")
n.bind("SUPER + SHIFT + comma", "Cerrar todas las notificaciones", "makoctl dismiss --all")
n.bind("SUPER + CTRL + comma", "Silenciar / reactivar notificaciones", "makoctl mode -t silent")

-- Fondo de pantalla: rota entre los del tema y los tuyos (nanuk bg).
n.bind("SUPER + SHIFT + B", "Siguiente fondo de pantalla", "nanuk-bg next")

-- Barra: SIGUSR1 muestra/oculta waybar.
n.bind("SUPER + SHIFT + SPACE", "Mostrar/ocultar barra", "pkill -SIGUSR1 waybar")

-- Luz nocturna (hyprsunset): ~4000K o desactivar.
n.bind("SUPER + CTRL + N", "Luz nocturna on/off", "pkill hyprsunset || hyprsunset -t 4000")

-- Zoom de pantalla (accesibilidad / presentaciones).
n.bind("SUPER + CTRL + Z", "Zoom +", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)
n.bind("SUPER + CTRL + ALT + Z", "Zoom reset", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end)
