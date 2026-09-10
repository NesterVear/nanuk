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

# ── Pac-Man para la barra de progreso del arranque ─────────────────
# El splash muestra a Pac-Man (amarillo) comiéndose una fila de monedas
# según avanza el progreso real del boot. Guiño al arcade; dura ~15 s y
# luego entras al escritorio sobrio. Colores ajustables aquí.
PAC="#ffd400"
PELLET="#e8b84b"

# Frame A: boca casi cerrada.  Frame B: boca abierta a la derecha.
# Se dibuja el círculo a 4x y se recorta una cuña con -compose DstOut.
magick -size 120x120 xc:none -fill "$PAC" -draw "circle 60,60 60,6" \
  \( -size 120x120 xc:none -fill white -draw "polygon 60,60 128,48 128,72" \) \
  -compose DstOut -composite -resize 30x30 "$PLY/pac_a.png"
magick -size 120x120 xc:none -fill "$PAC" -draw "circle 60,60 60,6" \
  \( -size 120x120 xc:none -fill white -draw "polygon 60,60 132,8 132,112" \) \
  -compose DstOut -composite -resize 30x30 "$PLY/pac_b.png"

# Moneda: puntito redondo, cálido.
magick -size 40x40 xc:none -fill "$PELLET" -draw "circle 20,20 20,13" \
  -resize 10x10 "$PLY/pellet.png"

echo "✔ assets generados en $HERE y $PLY"
ls -la "$HERE/wordmark.png" "$PLY"/*.png
