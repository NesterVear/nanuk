-- Nanuk — tus atajos. n.rebind quita el default y pone el tuyo;
-- n.bind añade uno nuevo; hl.unbind quita uno sin reemplazo.
-- Lista de defaults: ~/.config/nanuk/default/hypr/bindings/*.lua

-- Ejemplos reales:
-- n.bind("SUPER + SHIFT + O", "Obsidian", n.launch("obsidian"))
-- n.bind("SUPER + SHIFT + O", "Obsidian", n.launch("obsidian"))
-- n.bind("SUPER + SHIFT + K", "KeePassXC", n.launch("keepassxc"))
-- n.bind("SUPER + SHIFT + G", "Modo fantasma", "~/.local/bin/ghost")

-- Web apps en ventana propia (Brave/Chromium con --app=URL):
-- n.bind("SUPER + SHIFT + A", "ChatGPT", n.launch("brave --app=https://chatgpt.com"))
-- n.bind("SUPER + SHIFT + Y", "YouTube", n.launch("brave --app=https://youtube.com"))

-- Cambiar un default:
-- n.rebind("SUPER + RETURN", "Terminal", n.launch("foot"))
-- hl.unbind("SUPER + O")

-- Apps web con nanuk-webapp (ventana propia en Brave; --focus = enfocar si ya
-- está abierta). Para que salga también en el launcher, un .desktop en
-- ~/.config/nanuk/user/webapps/ (copia uno de ../default/webapps/ de plantilla).
-- n.bind("SUPER + SHIFT + A", "ChatGPT", "nanuk-webapp https://chatgpt.com")
-- n.bind("SUPER + SHIFT + Y", "YouTube", "nanuk-webapp https://youtube.com --focus")
