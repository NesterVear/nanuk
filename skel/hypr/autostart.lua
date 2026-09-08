-- Nanuk — tus programas al iniciar sesión (una sola vez).
-- n.launch_on_start lanza con uwsm-app (unidad de systemd de usuario).

-- Ejemplos reales:
-- n.launch_on_start("sleep 20 && rclone mount gdrive: ~/Drive --vfs-cache-mode writes --daemon")
-- n.launch_on_start("sleep 30 && keepassxc")
-- n.launch_on_start("hyprsunset -t 4000")   -- luz nocturna siempre
