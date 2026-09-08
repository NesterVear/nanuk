-- Nanuk — tus monitores. Lista los disponibles con:  hyprctl monitors all
-- Referencia: https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Ejemplo real: laptop a la izquierda, HDMI extendido a la derecha.
-- hl.monitor({ output = "eDP-1", mode = "1366x768@60", position = "0x0", scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "1366x0", scale = 1 })

-- Workspaces fijos por monitor (1 y 4 en la laptop, 2 y 3 en el externo):
-- hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true })
-- hl.workspace_rule({ workspace = "4", monitor = "eDP-1" })
-- hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", default = true })
-- hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1" })

-- Pantallas HiDPI (2x): descomenta y ajusta.
-- hl.env("GDK_SCALE", "2")
-- hl.monitor({ output = "eDP-1", mode = "2880x1920@120", position = "auto", scale = 2 })
