-- Nanuk — variables de entorno de la sesión.
-- Cambiarlas requiere relanzar Hyprland (no basta con recargar).

-- Cursor (Adwaita: blanco/negro, sin color; viene con adwaita-icon-theme).
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Forzar Wayland nativo en cada toolkit (con X11 de respaldo en GTK/Qt).
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- ~/.local/bin al frente del PATH que ven los programas lanzados por Hyprland
-- (atajos y autostart): ahí viven nanuk, nanuk-bg, nanuk-keys, nanuk-power-menu.
-- uwsm arranca Hyprland como unidad de systemd, y ese PATH no es el de tu shell.
do
  local home = os.getenv("HOME") or ""
  local bin = home .. "/.local/bin"
  local kept = {}
  for entry in (os.getenv("PATH") or "/usr/local/bin:/usr/bin"):gmatch("[^:]+") do
    if entry ~= bin then table.insert(kept, entry) end
  end
  table.insert(kept, 1, bin)
  hl.env("PATH", table.concat(kept, ":"))
end

-- Compartir pantalla (portales) y apps que preguntan qué escritorio es.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.config({
  xwayland = {
    -- Apps X11 sin escalado borroso: que Hyprland no las escale.
    force_zero_scaling = true,
  },

  ecosystem = {
    -- Sin la notificación de novedades al actualizar Hyprland.
    no_update_news = true,
  },
})
