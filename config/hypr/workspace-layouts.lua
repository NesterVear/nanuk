-- Nanuk — layout por workspace (SUPER + L alterna mosaico ↔ columnas).
--
-- "dwindle" es el mosaico de siempre: cada ventana nueva parte el hueco.
-- "scrolling" pone las ventanas en columnas, una tras otra; cuando no caben,
-- el workspace se desplaza de lado (como niri) en vez de encogerlas todas.
--
-- Lo que eliges con SUPER + L se guarda por workspace en
--   ~/.local/state/nanuk/workspace-layouts/<workspace>   (dentro, solo la palabra)
-- y aquí se vuelve a aplicar en cada recarga (hyprctl reload, nanuk update).
-- Se guarda solo el nombre del layout, no código: nada se ejecuta a ciegas.

local home = os.getenv("HOME") or ""
local state = os.getenv("XDG_STATE_HOME")
if not state or state == "" then state = home .. "/.local/state" end

n.workspace_layouts_dir = state .. "/nanuk/workspace-layouts"
n.valid_layouts = { dwindle = true, scrolling = true, master = true, monocle = true }
n.workspace_layout_rules = {}   -- regla activa por workspace, para poder cambiarla

-- Aplica <layout> al workspace <ws> y desactiva la regla que tuviera antes.
function n.set_workspace_layout(ws, layout)
  local key = tostring(ws)
  local previous = n.workspace_layout_rules[key]
  if previous and previous.set_enabled then
    pcall(previous.set_enabled, previous, false)
  end
  n.workspace_layout_rules[key] = hl.workspace_rule({ workspace = key, layout = layout })
end

-- Al cargar la config: una regla por cada archivo guardado.
local handle = io.popen("find " .. n.shell_quote(n.workspace_layouts_dir)
  .. " -maxdepth 1 -type f -printf '%f\\n' 2>/dev/null | sort")
if handle then
  for ws in handle:lines() do
    local file = io.open(n.workspace_layouts_dir .. "/" .. ws, "r")
    local layout = file and file:read("l")
    if file then file:close() end
    if layout and n.valid_layouts[layout] then
      n.set_workspace_layout(ws, layout)
    end
  end
  handle:close()
end
