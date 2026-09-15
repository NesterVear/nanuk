#!/usr/bin/env bash
# Clima para waybar, desde wttr.in. Salida JSON (return-type=json).
# En la barra se ve el estado general (soleado, nublado, lluvia...); la
# temperatura y la sensación quedan en el tooltip. Sin red → no muestra nada.
# Ubicación: por IP (automática). Fíjala con NANUK_WEATHER_LOCATION=Ciudad.
set -uo pipefail

loc="${NANUK_WEATHER_LOCATION:-}"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/nanuk-weather.json"

# Cache de 30 min salvo --refresh (clic en el módulo).
if [[ "${1:-}" != "--refresh" && -f "$cache" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0) ))
  (( age < 1800 )) && { cat "$cache"; exit 0; }
fi

# %c = icono, %C = estado (español), %t = temperatura, %f = sensación, %l = lugar.
data=$(curl -sf --max-time 8 "https://wttr.in/${loc}?format=%c|%C|%t|%f|%l&lang=es" 2>/dev/null || true)
if [[ -z "$data" ]]; then
  [[ -f "$cache" ]] && cat "$cache" || echo '{"text":""}'
  exit 0
fi

IFS='|' read -r icon cond temp feel place <<<"$data"
icon=$(xargs <<<"$icon")
cond=$(xargs <<<"$cond")
temp=$(tr -d '+' <<<"$temp" | xargs)
feel=$(tr -d '+' <<<"$feel" | xargs)
place=$(xargs <<<"$place")

printf '{"text":"%s %s","tooltip":"%s: %s, %s (sensación %s)"}\n' \
  "$icon" "$cond" "${place:-$cond}" "$cond" "$temp" "$feel" | tee "$cache"
