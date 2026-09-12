-- Nanuk — ventanas y workspaces.
-- SUPER = tecla Windows. Los dispatchers vienen de hl.dsp.* (ver stubs).

local dsp = hl.dsp

-- ── Ventana activa ──────────────────────────────────────────────────
n.bind("SUPER + W", "Cerrar ventana", dsp.window.close())
-- SUPER+T estilo Windows: una ventana en mosaico pasa a flotante MEDIANA
-- (60% x 65% del monitor) y centrada, en vez de quedarse con el tamaño raro
-- que tuviera; una flotante vuelve al mosaico. Mismas medidas que la talla
-- "float-md" de windows.lua.
n.bind("SUPER + T", "Flotante mediana y centrada / en mosaico", function()
  local win = hl.get_active_window()
  if not win then return end
  local was_floating = win.floating
  hl.dispatch(dsp.window.float({ action = "toggle" }))
  if was_floating then return end
  local mon = win.monitor
  if mon then
    local scale = (mon.scale and mon.scale > 0) and mon.scale or 1
    -- resize({ x, y }) sin relative = tamaño exacto, en píxeles lógicos.
    hl.dispatch(dsp.window.resize({ x = math.floor(mon.width / scale * 0.6), y = math.floor(mon.height / scale * 0.65) }))
  end
  hl.dispatch(dsp.window.center())
end)
n.bind("SUPER + F", "Pantalla completa", dsp.window.fullscreen({ mode = "fullscreen" }))
n.bind("SUPER + ALT + F", "Maximizar (sin tapar la barra)", dsp.window.fullscreen({ mode = "maximized" }))
n.bind("SUPER + P", "Pseudo-mosaico (tamaño fijo)", dsp.window.pseudo())
n.bind("SUPER + J", "Cambiar dirección del split", dsp.layout("togglesplit"))
n.bind("SUPER + O", "Fijar ventana flotante (visible en todos los workspaces)", dsp.window.pin())

-- ── Estilo Windows: minimizar ───────────────────────────────────────
-- Hyprland no tiene "minimizar". Lo simulamos con un workspace especial
-- llamado "minimized": SUPER+M manda la ventana ahí sin seguirla;
-- SUPER+SHIFT+M muestra/oculta ese cajón para recuperarlas.
n.bind("SUPER + M", "Minimizar ventana", dsp.window.move({ workspace = "special:minimized", follow = false }))
n.bind("SUPER + SHIFT + M", "Ver ventanas minimizadas", dsp.workspace.toggle_special("minimized"))

-- ── Foco ────────────────────────────────────────────────────────────
n.bind("SUPER + LEFT", "Foco a la izquierda", dsp.focus({ direction = "l" }))
n.bind("SUPER + RIGHT", "Foco a la derecha", dsp.focus({ direction = "r" }))
n.bind("SUPER + UP", "Foco arriba", dsp.focus({ direction = "u" }))
n.bind("SUPER + DOWN", "Foco abajo", dsp.focus({ direction = "d" }))

-- Alt+Tab como en Windows: ciclar ventanas del workspace.
n.bind("ALT + TAB", "Siguiente ventana", dsp.window.cycle_next())
n.bind("ALT + TAB", "Traer al frente", dsp.window.bring_to_top())
n.bind("ALT + SHIFT + TAB", "Ventana anterior", dsp.window.cycle_next({ next = false }))
n.bind("ALT + SHIFT + TAB", "Traer al frente", dsp.window.bring_to_top())

-- ── Mover ventanas ──────────────────────────────────────────────────
n.bind("SUPER + SHIFT + LEFT", "Intercambiar con la izquierda", dsp.window.swap({ direction = "l" }))
n.bind("SUPER + SHIFT + RIGHT", "Intercambiar con la derecha", dsp.window.swap({ direction = "r" }))
n.bind("SUPER + SHIFT + UP", "Intercambiar con arriba", dsp.window.swap({ direction = "u" }))
n.bind("SUPER + SHIFT + DOWN", "Intercambiar con abajo", dsp.window.swap({ direction = "d" }))

-- Arrastrar (botón izq) y redimensionar (botón der) con SUPER + ratón.
n.bind("SUPER + mouse:272", "Mover ventana con el ratón", dsp.window.drag(), { mouse = true })
n.bind("SUPER + mouse:273", "Redimensionar con el ratón", dsp.window.resize(), { mouse = true })

-- Redimensionar con teclado: SUPER + - / =  (code:20 y code:21 en cualquier layout).
n.bind("SUPER + code:20", "Encoger a la izquierda", dsp.window.resize({ x = -100, y = 0, relative = true }))
n.bind("SUPER + code:21", "Crecer a la derecha", dsp.window.resize({ x = 100, y = 0, relative = true }))
n.bind("SUPER + SHIFT + code:20", "Encoger hacia arriba", dsp.window.resize({ x = 0, y = -100, relative = true }))
n.bind("SUPER + SHIFT + code:21", "Crecer hacia abajo", dsp.window.resize({ x = 0, y = 100, relative = true }))

-- ── Workspaces ──────────────────────────────────────────────────────
-- code:10..19 son las teclas 1..9,0 de la fila superior, en cualquier layout.
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  n.bind("SUPER + " .. key, "Ir al workspace " .. workspace, dsp.focus({ workspace = tostring(workspace) }))
  n.bind("SUPER + SHIFT + " .. key, "Mover ventana al workspace " .. workspace, dsp.window.move({ workspace = tostring(workspace) }))
  n.bind("SUPER + SHIFT + ALT + " .. key, "Mover ventana sin seguirla " .. workspace, dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

n.bind("SUPER + TAB", "Workspace siguiente", dsp.focus({ workspace = "e+1" }))
n.bind("SUPER + SHIFT + TAB", "Workspace anterior", dsp.focus({ workspace = "e-1" }))
n.bind("SUPER + CTRL + TAB", "Último workspace", dsp.focus({ workspace = "previous" }))
n.bind("SUPER + mouse_down", "Workspace siguiente (rueda)", dsp.focus({ workspace = "e+1" }))
n.bind("SUPER + mouse_up", "Workspace anterior (rueda)", dsp.focus({ workspace = "e-1" }))

-- Scratchpad: un workspace especial que aparece encima con SUPER+S.
n.bind("SUPER + S", "Mostrar/ocultar scratchpad", dsp.workspace.toggle_special("scratchpad"))
n.bind("SUPER + ALT + S", "Mandar ventana al scratchpad", dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Monitores.
n.bind("SUPER + SHIFT + ALT + LEFT", "Workspace al monitor izquierdo", dsp.workspace.move({ monitor = "l" }))
n.bind("SUPER + SHIFT + ALT + RIGHT", "Workspace al monitor derecho", dsp.workspace.move({ monitor = "r" }))
n.bind("CTRL + ALT + TAB", "Foco al siguiente monitor", dsp.focus({ monitor = "+1" }))

-- Grupos (pestañas de ventanas).
n.bind("SUPER + G", "Agrupar / desagrupar", dsp.group.toggle())
n.bind("SUPER + ALT + TAB", "Siguiente ventana del grupo", dsp.group.next())
n.bind("SUPER + ALT + SHIFT + TAB", "Ventana anterior del grupo", dsp.group.prev())
