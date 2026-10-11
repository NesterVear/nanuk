#!/usr/bin/env bash
# Rueda de actualizaciones para waybar (custom/updates). Salida JSON.
# Nada pendiente, sin red o sin nanuk → texto vacío: el módulo no se ve.
#
# Todo lo hace `nanuk check --json`, y SOLO mira Nanuk: la rueda se enciende
# cuando se mueve la bandera "estable" del repo, no por actualizaciones del
# sistema/AUR/flatpak (esas las aplica `nanuk update` igual, con -Syu). Waybar
# lo llama cada 10 min, pero a internet se va UNA vez por arranque, una hora
# después de encender, y otra si la sesión pasa de 24 h. El resto de llamadas
# solo leen lo guardado.
command -v nanuk &>/dev/null || { echo '{"text":""}'; exit 0; }
nanuk check --json 2>/dev/null || echo '{"text":""}'
