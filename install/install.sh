#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Nanuk — orquestador de instalación
#
# No contiene lógica propia: solo ejecuta cada paso de install/ en orden.
# Cada paso es un script independiente que también puedes correr solo:
#   bash install/02-pacman.sh
# Eso hace que depurar sea trivial: si algo falla, repites SOLO ese paso.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

# Directorio donde vive este script, sin importar desde dónde lo llames.
# (Truco estándar de bash: la ruta del script está en BASH_SOURCE[0].)
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# NANUK_ROOT = raíz del repo. Los pasos lo usan para encontrar packages/,
# config/, themes/... Se exporta para que los hijos lo hereden.
export NANUK_ROOT="$(dirname "$INSTALL_DIR")"

STEPS=(
  01-preflight.sh
  02-pacman.sh
  03-packages.sh
  04-services.sh
  05-desktop.sh
  06-dotfiles.sh
  07-dev.sh
)

echo "╔══════════════════════════════════╗"
echo "║   Nanuk 🐻‍❄️  — instalador         ║"
echo "╚══════════════════════════════════╝"
echo "raíz del repo: $NANUK_ROOT"
echo

# Pedimos sudo una vez al principio y lo mantenemos vivo en segundo plano:
# la caché de sudo caduca a los 15 min y el paso 03 tarda más que eso.
# `sudo -n true` refresca sin preguntar; el bucle muere cuando muere este script.
sudo -v
( while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 60; done ) &

for step in "${STEPS[@]}"; do
  echo
  echo "━━━ ▶ $step ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bash "$INSTALL_DIR/$step"
done

echo
echo "✔ Nanuk instalado. Reinicia para entrar a tu sistema."
