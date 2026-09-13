#!/usr/bin/env bash
# Rueda de actualizaciones para waybar (custom/updates). Salida JSON.
# Nada pendiente, sin red o sin nanuk → texto vacío: el módulo no se ve.
#
# Todo lo hace `nanuk check --json`. Waybar lo llama cada 10 min, pero a
# internet se va UNA vez por arranque, una hora después de encender (paquetes
# de repos/AUR/flatpak + si se movió la bandera "estable" de Nanuk), y otra si
# la sesión pasa de 24 h. El resto de llamadas solo leen lo guardado.
command -v nanuk &>/dev/null || { echo '{"text":""}'; exit 0; }
nanuk check --json 2>/dev/null || echo '{"text":""}'
