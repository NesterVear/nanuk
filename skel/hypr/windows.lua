-- Nanuk — tus reglas de ventanas.
-- Averigua la clase/título de una ventana con:  hyprctl clients
-- Referencia: https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Ejemplo real: KeePassXC flotante, centrado y de tamaño fijo.
-- n.window("^(org.keepassxc.KeePassXC)$", { float = true, center = true, size = { 800, 600 } })

-- Apps a workspaces fijos:
-- n.window("^(firefox|chromium|Brave-browser|brave-browser)$", { workspace = "1" })
-- n.window("^(code|Code|code-url-handler)$", { workspace = "2" })

-- Marcar algo más como diálogo (flota y se centra):
-- n.window({ title = "^Mi ventana$" }, { tag = "+dialog" })

-- Que una app NO se trate como diálogo aunque su título coincida:
-- n.window("^gimp$", { tag = "-dialog" })
