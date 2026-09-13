-- Nanuk — lanzar aplicaciones.
-- Las apps se leen de n.apps (default/hypr/helpers.lua), que tú puedes
-- cambiar en user/hypr/apps.lua ANTES de que este archivo se cargue.

local apps = n.apps

n.bind("SUPER + RETURN", "Terminal", n.launch(apps.terminal))
n.bind("SUPER + ALT + RETURN", "Terminal con tmux", n.launch(apps.terminal .. " tmux new"))
n.bind("SUPER + SPACE", "Launcher", apps.launcher)
n.bind("SUPER + B", "Navegador", n.launch(apps.browser))
n.bind("SUPER + E", "Archivos", n.launch(apps.files))
n.bind("SUPER + N", "Editor", n.launch(apps.editor))
n.bind("SUPER + C", "VS Code", n.launch(apps.code))
n.bind("SUPER + SHIFT + T", "Monitor del sistema (btop)", n.launch(apps.tui .. " btop"))
n.bind("SUPER + SHIFT + D", "Docker (lazydocker)", n.launch(apps.terminal .. " lazydocker"))
n.bind("SUPER + SHIFT + I", "Menú Nanuk: paquetes, tema, fondo, actualizar", n.launch(apps.tui .. " nanuk menu"))

-- Apps web (ventana propia en Brave, ver bin/nanuk-webapp). Con --focus, si
-- ya está abierta la enfoca. Las tuyas: user/webapps/*.desktop + user/hypr/bindings.lua
n.bind("SUPER + SHIFT + G", "WhatsApp (app web)", "nanuk-webapp https://web.whatsapp.com --focus")
n.bind("SUPER + SHIFT + U", "Tidal (app web)", "nanuk-webapp https://listen.tidal.com --focus")
