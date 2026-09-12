-- Nanuk — tus programas al iniciar sesión (una sola vez).
-- n.launch_on_start lanza con uwsm-app (unidad de systemd de usuario).

-- Ejemplos reales:
-- n.launch_on_start("sleep 20 && rclone mount gdrive: ~/Drive --vfs-cache-mode writes --daemon")
-- n.launch_on_start("sleep 30 && keepassxc")
-- n.launch_on_start("hyprsunset -t 4000")   -- luz nocturna siempre

-- Pantalla de inicio de sesión: Nanuk bloquea con hyprlock nada más entrar
-- (wordmark + contraseña; esa contraseña abre también el keyring).
-- Para entrar directo, sin contraseña:
-- n.lock_on_start = false
