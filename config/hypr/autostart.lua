-- Nanuk — programas que arrancan con Hyprland (una sola vez).
-- Cada uno va con uwsm-app: se convierte en unidad de systemd de usuario,
-- sobrevive a `hyprctl reload` y se ve en `systemctl --user status`.
-- Tus propios autostart: user/hypr/autostart.lua (hay plantilla).

hl.on("hyprland.start", function()
  -- Que los servicios de usuario (polkit, pipewire) vean las variables de la sesión.
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  -- "Pantalla de inicio de sesión": hyprlock nada más entrar (ver helpers.lua).
  if n.lock_on_start then
    hl.exec_cmd(n.launch("hyprlock"))
  end

  hl.exec_cmd(n.launch("waybar"))
  hl.exec_cmd(n.launch("mako"))
  hl.exec_cmd(n.launch("hypridle"))

  -- Fondo de pantalla: arranca hyprpaper con la imagen elegida en
  -- user/background (o nada, si elegiste negro puro). Ver `nanuk bg`.
  hl.exec_cmd("nanuk-bg apply")

  -- Portapapeles: que sobreviva al cerrar la app de origen + historial.
  hl.exec_cmd(n.launch("wl-clip-persist --clipboard regular"))
  hl.exec_cmd(n.launch("wl-paste --watch cliphist store"))

  -- Montar USB automáticamente, sin icono de bandeja.
  hl.exec_cmd(n.launch("udiskie --automount --no-notify --no-tray"))
end)
