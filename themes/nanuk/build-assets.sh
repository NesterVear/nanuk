#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Genera los PNG del tema Nanuk a partir de wordmark.svg y de formas
# simples. Los PNG resultantes SE COMMITEAN al repo: el instalador no
# necesita rsvg ni imagemagick, solo esta máquina de desarrollo.
#
# Requiere: rsvg-convert (librsvg), magick (imagemagick),
#           y la fuente "iA Writer Quattro S" instalada (paquete ttf-ia-writer).
#
# Uso:  bash themes/nanuk/build-assets.sh
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLY="$HERE/plymouth"
ACCENT="#9fd8ff"
mkdir -p "$PLY"

for tool in rsvg-convert magick; do
  command -v "$tool" >/dev/null || { echo "falta $tool" >&2; exit 1; }
done
# Sin `grep -q`: cerraría la tubería antes de que fc-list termine y, con
# pipefail, eso se contaría como fallo aunque la fuente exista.
if ! fc-list : family | grep -i "iA Writer Quattro S" >/dev/null; then
  echo "⚠ fuente iA Writer Quattro S no encontrada: se usará la de respaldo" >&2
fi

# ── Wordmark ────────────────────────────────────────────────────────
# La MISMA imagen para el splash (plymouth/logo.png) y para el lock
# (wordmark.png, que hyprlock lee de ~/.config/nanuk/theme/). Se renderiza
# grande (1400 px): Plymouth la escala a ~62% del ancho de la pantalla y
# hyprlock a 850 px (config/hypr/hyprlock.conf), así se ve rotunda en ambos.
rsvg-convert -w 1400 "$HERE/wordmark.svg" -o "$HERE/wordmark.png"
rsvg-convert -w 1400 "$HERE/wordmark.svg" -o "$PLY/logo.png"

# Fondo del lock (lock.png): pantalla 16:9 negra con el wordmark centrado al
# 58% del ancho. hyprlock escala el fondo en modo "cover" (llena y recorta
# centrado), así que funciona en cualquier resolución y proporción: en 16:10
# o 4:3 solo se recortan bordes negros. NO usar el widget `image` de hyprlock
# para el wordmark: escala por el lado MENOR y recorta en cuadrado (pensado
# para avatares) y un logo ancho sale como una letra gigante.
magick -size 3840x2160 xc:black \( "$HERE/wordmark.png" -resize 2227x \) \
  -gravity center -composite -depth 8 -strip -define png:compression-level=9 "$HERE/lock.png"

# ── Assets del splash (Plymouth) ────────────────────────────────────
# Caja del campo de contraseña: solo un borde fino de hielo, sin relleno.
magick -size 420x52 xc:none \
  -fill none -stroke "$ACCENT" -strokewidth 2 \
  -draw 'rectangle 1,1 418,50' \
  "$PLY/entry.png"

# Bullet (●) por cada carácter tecleado. El script lo escala a 7x7.
magick -size 14x14 xc:none -fill white -draw 'circle 7,7 7,1' "$PLY/bullet.png"

# ── Barra de progreso del arranque: una línea ───────────────────────
# Pista gris (#333333) y línea blanca que el script estira según el progreso
# real del boot. 520x2 px, sobria. (El Pac-Man se queda solo en la terminal:
# ILoveCandy en pacman.conf, ver install/02-pacman.sh.)
magick -size 520x2 xc:'#333333' "$PLY/progress_box.png"
magick -size 520x2 xc:'#ffffff' "$PLY/progress_bar.png"

echo "✔ assets generados en $HERE y $PLY"
ls -la "$HERE/wordmark.png" "$PLY"/*.png
