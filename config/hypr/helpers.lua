-- Nanuk — helpers `n.*` para la configuración Lua de Hyprland.
--
-- Hyprland expone su API en la tabla global `hl` (documentada en
-- /usr/share/hypr/stubs/hl.meta.lua). Estas funciones solo la envuelven para
-- escribir menos y leer más claro. Nada aquí es magia: cada una son 3 líneas.

n = n or {}

-- ── Apps por defecto ────────────────────────────────────────────────
-- Los bindings leen esta tabla. Para cambiar una app, en
-- ~/.config/nanuk/user/hypr/apps.lua escribe p. ej.:  n.apps.terminal = "kitty"
n.apps = {
  terminal = "kitty",
  launcher = "wofi",
  -- gtk-launch abre el .desktop del navegador por defecto (xdg-settings).
  browser = 'gtk-launch "$(xdg-settings get default-web-browser)"',
  files = "nautilus --new-window",
  editor = "kitty nvim",
  power_menu = "nanuk-power-menu",
}

-- ── Utilidades ──────────────────────────────────────────────────────

-- Envuelve un valor en comillas simples para el shell ('it''s' → 'it'\''s').
function n.shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

-- require que no falla si el módulo no existe (para las capas opcionales:
-- tema y user). Cualquier OTRO error (sintaxis, etc.) sí se propaga, para
-- que Hyprland lo muestre y no lo escondamos.
function n.require_optional(module)
  local ok, result = pcall(require, module)
  if ok then
    return result
  end
  if type(result) == "string" and result:find("module '" .. module .. "' not found", 1, true) then
    return nil
  end
  error(result, 0)
end

-- ── Lanzar programas ────────────────────────────────────────────────

-- uwsm-app lanza el programa como unidad de systemd de usuario: sobrevive a
-- recargas de Hyprland, tiene su propio cgroup y hereda el entorno correcto.
function n.launch(command)
  return "uwsm-app -- " .. command
end

-- Ejecutar algo una sola vez, cuando Hyprland arranca (equivale a exec-once).
function n.exec_on_start(command)
  hl.on("hyprland.start", function()
    hl.exec_cmd(command)
  end)
end

function n.launch_on_start(command)
  n.exec_on_start(n.launch(command))
end

-- ── Atajos ──────────────────────────────────────────────────────────

-- n.bind("SUPER + RETURN", "Terminal", "kitty")
-- n.bind("SUPER + W", "Cerrar", hl.dsp.window.close())
-- Si el tercer argumento es un string, se ejecuta como comando de shell;
-- si es un dispatcher de hl.dsp.*, se usa tal cual. La descripción queda
-- registrada en Hyprland (sirve para listar atajos).
function n.bind(keys, description, dispatcher, options)
  local opts = options or {}
  if description then
    opts.description = description
  end
  if type(dispatcher) == "string" then
    dispatcher = hl.dsp.exec_cmd(dispatcher)
  end
  return hl.bind(keys, dispatcher, opts)
end

-- Igual que n.bind pero quitando antes lo que hubiera en esa combinación.
-- Es lo que usarás en user/ para cambiar un atajo de los defaults.
function n.rebind(keys, description, dispatcher, options)
  hl.unbind(keys)
  return n.bind(keys, description, dispatcher, options)
end

-- ── Reglas de ventanas ──────────────────────────────────────────────

-- n.window("^kitty$", { float = true })                       -- por clase
-- n.window({ title = "^Preferencias$" }, { float = true })    -- por otros campos
-- n.window({ tag = "dialog" }, { center = true })             -- por tag
-- Campos de match: class, title, initial_class, initial_title, tag, xwayland,
-- float, fullscreen, pin, workspace. Todos los strings son regex.
function n.window(match, rules)
  rules.match = rules.match or {}
  if type(match) == "string" then
    rules.match.class = match
  else
    for key, value in pairs(match) do
      rules.match[key] = value
    end
  end
  return hl.window_rule(rules)
end
