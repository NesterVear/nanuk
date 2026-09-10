#!/usr/bin/env bash
# Clima para waybar, desde wttr.in. Salida JSON (return-type=json).
# Sin red o sin respuesta → texto vacío: el módulo simplemente no se ve.
# Ubicación: por IP (automática). Fíjala con NANUK_WEATHER_LOCATION=Ciudad.
set -uo pipefail

loc="${NANUK_WEATHER_LOCATION:-}"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/nanuk-weather.json"

# Cache de 30 min salvo --refresh (clic en el módulo).
if [[ "${1:-}" != "--refresh" && -f "$cache" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0) ))
  (( age < 1800 )) && { cat "$cache"; exit 0; }
fi

temp=$(curl -sf --max-time 8 "https://wttr.in/${loc}?format=%t" 2>/dev/null | tr -d '+' | xargs || true)
if [[ -z "$temp" ]]; then
  [[ -f "$cache" ]] && cat "$cache" || echo '{"text":""}'
  exit 0
fi
tip=$(curl -sf --max-time 8 "https://wttr.in/${loc}?format=%l:+%C,+%t+(sensación+%f)" 2>/dev/null | tr -d '+' || true)

printf '{"text":"󰔏 %s","tooltip":"%s"}\n' "$temp" "${tip:-$temp}" | tee "$cache"
