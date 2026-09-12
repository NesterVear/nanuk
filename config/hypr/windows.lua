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
n.window("^(foot|kitty|Alacritty|com\\.mitchellh\\.ghostty|nanuk\\.tui)$", { tag = "+terminal" })
-- Scroll de touchpad más cómodo en terminales. (Va DESPUÉS de la etiqueta:
-- Hyprland evalúa las reglas en orden y la etiqueta tiene que existir ya.)
n.window({ tag = "terminal" }, { scroll_touchpad = 1.5 })

-- ── Navegadores: siempre en mosaico ─────────────────────────────────
-- Brave/Chromium piden a veces abrir flotando (ventanas --app de las apps
-- web, restaurar sesión). Aquí mandan el layout. El PiP de más abajo lo
-- vuelve a sacar a flotante porque va después.
n.window("^(([Bb]rave-(browser|origin))|[Cc]hromium|google-chrome|brave-.*|chrome-.*)$", { tag = "+chromium" })
n.window({ tag = "chromium" }, { tile = true })
-- El aviso "X está compartiendo tu pantalla" de Chromium no ocupa sitio.
n.window({ title = ".*(is sharing|está compartiendo).*" }, { workspace = "special:minimized silent" })

-- ── Diálogos y pop-ups: flotando y centrados (estilo Windows) ───────
-- En un tiling WM los diálogos se abrirían como una ventana más y se verían
-- mal. Todo lo que es diálogo lleva la etiqueta "dialog".
--
-- OJO: size, center, move y float son efectos ESTÁTICOS: Hyprland los aplica
-- una sola vez, al abrir la ventana, con el título que tenga EN ESE MOMENTO.
-- Si una app cambia el título después, las reglas por título ya no la pillan.
-- Por eso la regla más fiable es la primera: el protocolo.

-- 0. Modales: la propia app declara que es un diálogo ("¿Seguro?",
--    "Propiedades", avisos de FreeCAD, OrcaSlicer, LibreOffice…). No depende
--    del idioma ni del título.
n.window({ modal = true }, { tag = "+dialog" })

-- 1. Por título, en inglés y español. Regex: ^ = empieza por, $ = termina.
n.window({ title = "^(Preferences|Settings|Properties|Options|About|Confirm|Error|Warning)( .*)?$" }, { tag = "+dialog" })
n.window({ title = "^(Preferencias|Ajustes|Configuración|Propiedades|Opciones|Acerca de|Confirmar|Advertencia)( .*)?$" }, { tag = "+dialog" })

-- 2. Por clase: apps que SOLO muestran diálogos pequeños (polkit, zenity).
n.window("^(hyprpolkitagent|xdg-desktop-portal-hyprland|zenity|yad|org\\.gnome\\.Calculator|qalculate-gtk)$", { tag = "+dialog" })

-- Lo que hacemos con todo lo etiquetado "dialog": flotar y centrar, con el
-- tamaño que pida la propia app (un "¿Seguro?" no debe estirarse).
n.window({ tag = "dialog" }, { float = true, center = true })

-- ── Tallas por defecto para ventanas flotantes ──────────────────────
-- Para que ninguna nazca diminuta ni tape la pantalla entera y no haya que
-- redimensionarla a mano. En % del monitor: se ve igual en 1366x768 que en
-- 4K. Solo al abrir: lo que tú redimensiones después se respeta.

-- "float-md" (60% x 65%): utilidades y ajustes que se consultan y se cierran.
--    nanuk.tui = btop, nanuk menu, nmtui y bluetoothctl (ver n.apps.tui).
n.window("^(nanuk\\.tui|org\\.pulseaudio\\.pavucontrol|pavucontrol|blueman-manager|nm-connection-editor|org\\.keepassxc\\.KeePassXC|org\\.gnome\\.FileRoller|file-roller|imv|org\\.gnome\\.NautilusPreviewer|torbrowser-launcher|com\\.github\\.wwmm\\.easyeffects)$", { tag = "+float-md" })
n.window({ tag = "float-md" }, { float = true, center = true, size = { "(monitor_w*0.6)", "(monitor_h*0.65)" } })

-- "float-lg" (72% x 80%): elegir o guardar archivos, donde se necesita ver
--    carpetas enteras. El selector de archivos de TODAS las apps (Brave,
--    VS Code, Obsidian, OrcaSlicer…) pasa por el portal de GTK.
n.window("^(xdg-desktop-portal-gtk|org\\.freedesktop\\.impl\\.portal\\.desktop\\.gtk)$", { tag = "+float-lg" })
n.window({ title = "^(Open|Save|Save As|Export|Import|Select|Choose|Rename|Print)( .*)?$" }, { tag = "+float-lg" })
n.window({ title = "^(Abrir|Guardar|Guardar como|Exportar|Importar|Seleccionar|Elegir|Renombrar|Imprimir)( .*)?$" }, { tag = "+float-lg" })
n.window({ title = ".*(wants to|quiere) (open|save|abrir|guardar).*" }, { tag = "+float-lg" })
n.window({ tag = "float-lg" }, { float = true, center = true, size = { "(monitor_w*0.72)", "(monitor_h*0.8)" } })

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
