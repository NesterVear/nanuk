-- Nanuk — lanzar aplicaciones.
-- Las apps se leen de n.apps (default/hypr/helpers.lua), que tú puedes
-- cambiar en user/hypr/apps.lua ANTES de que este archivo se cargue.

local apps = n.apps

n.bind("SUPER + RETURN", "Terminal", n.launch(apps.terminal))
n.bind("SUPER + CTRL + RETURN", "Terminal alternativa (kitty)", n.launch(apps.terminal_alt))
n.bind("SUPER + ALT + RETURN", "Terminal con tmux", n.launch(apps.terminal .. " tmux new"))
n.bind("SUPER + SPACE", "Launcher", apps.launcher)
n.bind("SUPER + B", "Navegador", n.launch(apps.browser))
n.bind("SUPER + E", "Archivos", n.launch(apps.files))
n.bind("SUPER + N", "Editor", n.launch(apps.editor))
n.bind("SUPER + SHIFT + T", "Monitor del sistema (btop)", n.launch(apps.terminal .. " btop"))
n.bind("SUPER + SHIFT + D", "Docker (lazydocker)", n.launch(apps.terminal .. " lazydocker"))
