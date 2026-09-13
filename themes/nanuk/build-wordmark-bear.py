#!/usr/bin/env python3
# ─────────────────────────────────────────────────────────────────────
# Oso polar en pixel art, de lado, caminando sobre la línea de hielo del
# wordmark (splash de arranque, lock y web).
#
#   python3 themes/nanuk/build-wordmark-bear.py   → reescribe el oso en wordmark.svg
#
# build-assets.sh lo llama antes de renderizar los PNG. La consola tiene su
# propio oso (de frente): build-console-bear.py.
#
# Cómo se dibuja, sin magia:
#   1. SPRITE es el dibujo tal cual: cada carácter es un píxel y PALETA dice
#      su color ("." = vacío). Mira a la derecha. Edítalo a mano y vuelve a
#      correr build-assets.sh.
#   2. Paso en diagonal, como camina un oso: trasera cercana atrás y delantera
#      cercana adelante; las lejanas, al revés y en gris, que quedan "detrás".
#   3. Luz desde arriba: panza, bajo el hocico y plantas en sombra; dos trazos
#      claros marcan muslo y paletilla. La nariz es gris muy oscuro, no negra:
#      en la punta del hocico, el negro se confundiría con el fondo.
#   4. Cada fila se parte en tramos del mismo color y cada tramo es un
#      rectángulo "M x y h n v1 h-n z", un <path> por color. Con
#      shape-rendering="crispEdges" no hay antialias: bordes de píxel nítidos.
#   5. PX unidades por píxel, con las patas sobre el borde superior de la
#      línea de hielo y pegado a su extremo derecho, bajo la K.
# ─────────────────────────────────────────────────────────────────────
from pathlib import Path

SVG = Path(__file__).resolve().parent / "wordmark.svg"
START, END = "<!-- oso:inicio -->", "<!-- oso:fin -->"

PX = 3                  # 40x17 píxeles → 120x51 unidades
ICE_TOP = 300           # y del borde superior de la línea de hielo
ICE_RIGHT = 1070        # x de su extremo derecho

PALETA = {
    "W": "#ffffff",     # pelo
    "L": "#d6e2ea",     # sombra suave
    "S": "#a3b3bf",     # sombra
    "D": "#7b8894",     # patas del lado lejano
    "N": "#2b3137",     # nariz
    "K": "#000000",     # ojo
}

SPRITE = [
    "......WWWWWWW...........................",
    "....WWWWWWWWWWWWWW......................",
    "...WWWWWWWWWWWWWWWWWWW..................",
    "..WWWWWWWWWWWWWWWWWWWWWWW...............",
    ".WWWWWWWWWWWWWWWWWWWWWWWWWWW...LW.......",
    ".LWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.....",
    ".LWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWKWWW...",
    ".LWWWWWWWWLWWWWWWWWWWLWWWWWWWWWWWWWWWWWN",
    ".LWWWWWWWLWWWWWWWWWWWWLWWWWWWWWLLLLSSS..",
    ".LWWWWWWLWWWWWWWWWWWWWWLWWWWSSS.........",
    "..WLLLLLLLLLLLLLLLLLLLLLLLLW............",
    "..LWWWWW.SSSSSSSSSSSSS.LWWWW............",
    ".LWWWWW...DDDD.....DDDD.LWWWW...........",
    ".LWWWW....DDDD....DDDD..LWWWW...........",
    "LWWWW.....DDDD....DDDD...LWWWW..........",
    "LWWWW.....DDDD...DDDD....LWWWW..........",
    "SSSSSS....DDDDD.DDDDD....SSSSSSS........",
]


def paths():
    out = []
    for color, hexa in PALETA.items():
        d = ""
        for y, row in enumerate(SPRITE):
            x = 0
            while x < len(row):
                if row[x] != color:
                    x += 1
                    continue
                start = x
                while x < len(row) and row[x] == color:
                    x += 1
                d += f"M{start} {y}h{x - start}v1h{start - x}z"
        if d:
            out.append(f'    <path fill="{hexa}" d="{d}"/>')
    return out


def group():
    width = {len(row) for row in SPRITE}
    assert len(width) == 1, "todas las filas de SPRITE deben medir lo mismo"
    assert set("".join(SPRITE)) <= set(PALETA) | {"."}, "carácter sin color en PALETA"
    x = ICE_RIGHT - width.pop() * PX
    y = ICE_TOP - len(SPRITE) * PX
    return "\n".join(
        [f'  <g transform="translate({x} {y}) scale({PX})" shape-rendering="crispEdges">']
        + paths()
        + ["  </g>"]
    )


if __name__ == "__main__":
    svg = SVG.read_text()
    a, b = svg.index(START) + len(START), svg.index(END)
    SVG.write_text(svg[:a] + "\n" + group() + "\n  " + svg[b:])
    print("\n".join(SPRITE))
    print(f"✔ oso en {SVG}")
