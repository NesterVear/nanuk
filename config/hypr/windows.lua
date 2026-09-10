-- Nanuk — reglas de ventanas. Aquí vive el "estilo Windows".
-- Referencia: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--
-- Cómo funciona: n.window(<match>, <propiedades>). Usamos TAGS como capa
-- intermedia: primero etiquetamos ventanas ("+dialog"), luego una sola regla
-- dice qué hacer con esa etiqueta. Así añadir una app nueva es una línea.

-- ── Base ────────────────────────────────────────────────────────────

-- Ignorar la petición "maximízame" de las apps: el layout manda.
n.window(".*", { suppress_event = "maximize" })

-- Video a pantalla completa no debe activar el bloqueo por inactividad.
n.window(".*", { idle_inhibit = "fullscreen" })

-- Arreglo de arrastre en ventanas X11 sin clase ni título.
n.window({ class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, {
  no_focus = true,
})

-- Etiqueta "terminal": una sola lista de terminales para todas las reglas.
n.window("^(foot|kitty|Alacritty|com\\.mitchellh\\.ghostty)$", { tag = "+terminal" })
-- Scroll de touchpad más cómodo en terminales. (Va DESPUÉS de la etiqueta:
-- Hyprland evalúa las reglas en orden y la etiqueta tiene que existir ya.)
n.window({ tag = "terminal" }, { scroll_touchpad = 1.5 })

-- ── Diálogos y pop-ups: flotando y centrados (estilo Windows) ───────
-- En un tiling WM los diálogos se abren como una ventana más y se ven mal.
-- Etiquetamos como "dialog" todo lo que reconocemos como diálogo:

-- 1. Por título, en inglés y español. Regex: ^ = empieza por, $ = termina.
n.window({ title = "^(Open|Save|Save As|Export|Import|Select|Choose|Rename|Print)( .*)?$" }, { tag = "+dialog" })
n.window({ title = "^(Abrir|Guardar|Guardar como|Exportar|Importar|Seleccionar|Elegir|Renombrar|Imprimir)( .*)?$" }, { tag = "+dialog" })
n.window({ title = "^(Preferences|Settings|Properties|Options|About|Confirm|Error|Warning)( .*)?$" }, { tag = "+dialog" })
n.window({ title = "^(Preferencias|Ajustes|Configuración|Propiedades|Opciones|Acerca de|Confirmar|Advertencia)( .*)?$" }, { tag = "+dialog" })
n.window({ title = ".*(wants to|quiere) (open|save|abrir|guardar).*" }, { tag = "+dialog" })

-- 2. Por clase: apps que SOLO muestran diálogos (portales, polkit, selectores).
n.window("^(xdg-desktop-portal-gtk|xdg-desktop-portal-hyprland|hyprpolkitagent|org\\.freedesktop\\.impl\\.portal\\.desktop\\.gtk)$", { tag = "+dialog" })
n.window("^(nm-connection-editor|blueman-manager|pavucontrol|org\\.pulseaudio\\.pavucontrol|zenity|yad)$", { tag = "+dialog" })

-- 3. Apps pequeñas que se usan mejor flotando.
n.window("^(org\\.gnome\\.NautilusPreviewer|org\\.gnome\\.FileRoller|file-roller|imv|org\\.gnome\\.Calculator|qalculate-gtk)$", { tag = "+dialog" })

-- Y lo que hacemos con todo lo etiquetado "dialog":
n.window({ tag = "dialog" }, { float = true })
n.window({ tag = "dialog" }, { center = true })

-- ── Picture-in-Picture: siempre visible, abajo a la derecha ─────────
n.window({ title = "(Picture.?in.?[Pp]icture)" }, { tag = "+pip" })
n.window({ tag = "pip" }, {
  float = true,
  pin = true,                       -- visible en todos los workspaces
  size = { 600, 338 },
  keep_aspect_ratio = true,
  border_size = 0,
  no_initial_focus = true,
  move = { "(monitor_w-window_w-40)", "(monitor_h-window_h-40)" },
})

-- ── Media sin transparencia ni dim (aquí ya no hay, pero por si el user lo activa)
n.window("^(mpv|vlc|imv|org\\.kde\\.kdenlive|com\\.obsproject\\.Studio)$", { opacity = "1 1" })

-- ── Capas (barra, launcher, notificaciones): sin animación ──────────
hl.layer_rule({ match = { namespace = ".*" }, no_anim = true })
