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
# Versión grande para lock screen / fastfetch / web, y la del splash.
rsvg-convert -w 1040 "$HERE/wordmark.svg" -o "$HERE/wordmark.png"
rsvg-convert -w 520  "$HERE/wordmark.svg" -o "$PLY/logo.png"

# ── Assets del splash (Plymouth) ────────────────────────────────────
# Caja del campo de contraseña: solo un borde fino de hielo, sin relleno.
magick -size 420x52 xc:none \
  -fill none -stroke "$ACCENT" -strokewidth 2 \
  -draw 'rectangle 1,1 418,50' \
  "$PLY/entry.png"

# Bullet (●) por cada carácter tecleado. El script lo escala a 7x7.
magick -size 14x14 xc:none -fill white -draw 'circle 7,7 7,1' "$PLY/bullet.png"

# Barra de progreso: fondo gris casi negro y barra de hielo, 2 px de alto.
magick -size 420x2 xc:'#1a1a1a' "$PLY/progress_box.png"
magick -size 420x2 xc:"$ACCENT" "$PLY/progress_bar.png"

echo "✔ assets generados en $HERE y $PLY"
ls -la "$HERE/wordmark.png" "$PLY"/*.png
