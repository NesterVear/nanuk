#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Nanuk 🐻‍❄️ — punto de entrada
#
# Uso previsto en una máquina limpia:
#   curl -fsSL https://raw.githubusercontent.com/nestervear/nanuk/main/boot.sh | bash
#
# Este script solo hace dos cosas: clonar (o actualizar) el repo en un
# lugar fijo, y lanzar el instalador real. Toda la lógica vive en install/.
# ─────────────────────────────────────────────────────────────────────

# set -e  → aborta si cualquier comando falla
# set -u  → aborta si usas una variable no definida (caza typos)
# set -o pipefail → un fallo dentro de una tubería (a | b) también aborta
set -euo pipefail

# NANUK_REPO se puede sobreescribir para probar con un fork o una copia local:
#   NANUK_REPO=/ruta/a/mi/repo bash boot.sh
REPO="${NANUK_REPO:-https://github.com/nestervear/nanuk.git}"
NANUK_DIR="$HOME/.local/share/nanuk"

echo "🐻‍❄️  Nanuk — instalación"
echo "    repo:    $REPO"
echo "    destino: $NANUK_DIR"
echo

# git es lo único que necesitamos aquí; en un Arch recién instalado puede
# no venir. --needed hace que no reinstale si ya está (idempotencia).
# -Syu y no -Sy: en Arch instalar un paquete tras refrescar las listas sin
# actualizar el resto ("partial upgrade") puede romper librerías. El paso 02
# actualiza todo igualmente, así que aquí no cuesta nada más.
if ! command -v git &>/dev/null; then
  echo "→ Instalando git..."
  # OMARCHY_ALLOW_DIRECT_PACMAN=1: en una máquina que viene de Omarchy, su hook
  # 00-omarchy-update-guard aborta todo `pacman -Syu` que no lance `omarchy update`.
  # `env` hace que la variable llegue a pacman a través de sudo. En Arch sin
  # Omarchy nadie la lee.
  sudo env OMARCHY_ALLOW_DIRECT_PACMAN=1 pacman -Syu --noconfirm --needed git
fi

if [[ -d "$NANUK_DIR/.git" ]]; then
  # Ya estaba clonado: solo traemos lo último. Así boot.sh sirve
  # tanto para instalar como para re-instalar/actualizar.
  echo "→ Repo ya existente, actualizando..."
  git -C "$NANUK_DIR" pull --ff-only
else
  echo "→ Clonando repo..."
  git clone "$REPO" "$NANUK_DIR"
fi

# Cedemos el control al orquestador. exec reemplaza este proceso por el
# instalador: a partir de aquí ya corre el código del repo clonado.
exec bash "$NANUK_DIR/install/install.sh"
