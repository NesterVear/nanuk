#!/usr/bin/env python3
# ─────────────────────────────────────────────────────────────────────
# Cara de oso polar, de frente, para la terminal (fastfetch).
#
#   python3 themes/nanuk/build-console-bear.py   → config/fastfetch/nanuk.txt
#
# Solo la consola: el splash y el lock siguen con el oso de lado del wordmark.
#
# Cómo se dibuja, sin magia:
#   1. La cara son formas simples en una rejilla de W x H "píxeles": una
#      elipse para la cabeza, dos círculos para las orejas (con un hueco
#      dentro) y, restados, los ojos, la nariz y la boca. Lo negro es hueco.
#   2. Cada píxel se muestrea 5x5 veces y se pinta si más de la mitad cae
#      dentro de la figura (antialias "a mano", bordes limpios).
#   3. Una celda de terminal mide el doble de alto que de ancho, así que cada
#      carácter lleva DOS píxeles, uno encima de otro, con medios bloques:
#      █ los dos · ▀ solo el de arriba · ▄ solo el de abajo · espacio ninguno.
# ─────────────────────────────────────────────────────────────────────
from pathlib import Path

W, H = 24, 20          # píxeles → 24 columnas x 10 líneas
CX = (W - 1) / 2       # eje de simetría

HEAD = dict(cy=11.8, rx=10.8, ry=8.0)
EAR = dict(dx=7.2, cy=3.4, r=3.0, hole=1.2)
EYE = dict(dx=4.2, cy=10.6, r=1.0)
NOSE = dict(cy=14.6, rx=2.3, ry=1.4)
MOUTH = 2.3            # largo de la raya vertical bajo la nariz


def ellipse(x, y, cx, cy, rx, ry):
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1


def solid(x, y):
    head = ellipse(x, y, CX, HEAD["cy"], HEAD["rx"], HEAD["ry"])
    ear = hole = False
    for side in (-1, 1):
        ex = CX + side * EAR["dx"]
        ear |= ellipse(x, y, ex, EAR["cy"], EAR["r"], EAR["r"])
        hole |= ellipse(x, y, ex, EAR["cy"] + 0.3, EAR["hole"], EAR["hole"])
    eyes = any(ellipse(x, y, CX + s * EYE["dx"], EYE["cy"], EYE["r"], EYE["r"] * 1.15) for s in (-1, 1))
    nose = ellipse(x, y, CX, NOSE["cy"], NOSE["rx"], NOSE["ry"])
    mouth = abs(x - CX) < 0.55 and NOSE["cy"] < y < NOSE["cy"] + MOUTH
    return (head or (ear and not hole)) and not (eyes or nose or mouth)


def pixel(x, y, n=5):
    hits = sum(solid(x + (i + 0.5) / n - 0.5, y + (j + 0.5) / n - 0.5) for i in range(n) for j in range(n))
    return hits / (n * n) >= 0.5


def render():
    lines = []
    for row in range(0, H, 2):
        line = ""
        for x in range(W):
            top, bottom = pixel(x, row), pixel(x, row + 1)
            line += "█" if top and bottom else "▀" if top else "▄" if bottom else " "
        lines.append(line.rstrip())
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    out = Path(__file__).resolve().parents[2] / "config" / "fastfetch" / "nanuk.txt"
    out.write_text(render())
    print(render(), end="")
    print(f"✔ {out}")
