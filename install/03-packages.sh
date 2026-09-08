#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 03 — Paquetes.
#
# Lee las listas de packages/*.txt e instala en tres tandas:
#   1. repos oficiales  → pacman   (base, desktop, dev, 3dprint)
#   2. AUR              → paru     (aur.txt)
#   3. flatpak          → flathub  (flatpak.txt)
# Con NANUK_EXTRAS=1 instala además extras.txt (apps personales).
#
# --needed hace que pacman/paru salten lo que ya está instalado: correr
# este script dos veces es rápido y no cambia nada. Idempotente.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

# NANUK_ROOT lo exporta install.sh. Si corres este paso solo, lo deducimos
# de la ruta del script (install/ está un nivel bajo la raíz del repo).
NANUK_ROOT="${NANUK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PKG_DIR="$NANUK_ROOT/packages"

# read_list: imprime los paquetes de uno o más archivos, ignorando
# comentarios (# hasta fin de línea), espacios finales y líneas vacías.
read_list() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$@"
}

# ── 1. Repos oficiales ──────────────────────────────────────────────
# mapfile mete cada línea de la salida en un elemento del array.
mapfile -t PACMAN_PKGS < <(read_list "$PKG_DIR"/{base,desktop,dev,3dprint}.txt)

# Microcode según el fabricante de la CPU (necesario para que el kernel
# cargue las correcciones de firmware al arrancar).
case "$(grep -m1 '^vendor_id' /proc/cpuinfo)" in
  *GenuineIntel*)  PACMAN_PKGS+=(intel-ucode) ;;
  *AuthenticAMD*)  PACMAN_PKGS+=(amd-ucode) ;;
esac

echo "→ pacman: ${#PACMAN_PKGS[@]} paquetes"
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# ── 2. AUR ──────────────────────────────────────────────────────────
mapfile -t AUR_PKGS < <(read_list "$PKG_DIR/aur.txt")
if (( ${#AUR_PKGS[@]} )); then
  echo "→ AUR (paru): ${AUR_PKGS[*]}"
  # paru se ejecuta como usuario normal y pide sudo cuando instala.
  paru -S --needed --noconfirm "${AUR_PKGS[@]}"
fi

# ── 3. Extras (opcional) ────────────────────────────────────────────
# En extras.txt un sufijo ":aur" marca los paquetes que vienen del AUR.
if [[ "${NANUK_EXTRAS:-0}" == "1" ]]; then
  EXTRA_PACMAN=()
  EXTRA_AUR=()
  while read -r pkg; do
    if [[ "$pkg" == *:aur ]]; then
      EXTRA_AUR+=("${pkg%:aur}")   # quita el sufijo
    else
      EXTRA_PACMAN+=("$pkg")
    fi
  done < <(read_list "$PKG_DIR/extras.txt")

  (( ${#EXTRA_PACMAN[@]} )) && sudo pacman -S --needed --noconfirm "${EXTRA_PACMAN[@]}"
  (( ${#EXTRA_AUR[@]} ))    && paru -S --needed --noconfirm "${EXTRA_AUR[@]}"
  echo "✔ extras instalados"
else
  echo "⏭  extras.txt saltado (usa NANUK_EXTRAS=1 para instalarlos)"
fi

# ── 4. Flatpak ──────────────────────────────────────────────────────
mapfile -t FLATPAKS < <(read_list "$PKG_DIR/flatpak.txt")
if (( ${#FLATPAKS[@]} )); then
  # Instalación por usuario (--user): no necesita root y vive en ~/.local.
  flatpak remote-add --user --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
  echo "→ flatpak: ${FLATPAKS[*]}"
  flatpak install --user -y --noninteractive flathub "${FLATPAKS[@]}"
fi

echo "✔ Paquetes instalados"
