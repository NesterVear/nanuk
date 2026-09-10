#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 03 — Paquetes.
#
# Lee las listas de packages/*.txt e instala en tres tandas:
#   1. repos oficiales  → pacman   (base, desktop, dev, 3dprint)   ← CRÍTICO
#   2. AUR              → yay      (aur.txt)                        ← opcional
#   3. flatpak          → flathub  (flatpak.txt)                    ← opcional
# Con NANUK_EXTRAS=1 instala además extras.txt (apps personales).
#
# Solo la tanda 1 aborta el instalador si falla: todo el escritorio (Hyprland,
# barra, terminal...) vive en repos oficiales. Un fallo del AUR o de flathub
# se avisa y se sigue — esas apps se pueden instalar luego con `nanuk install`.
#
# --needed hace que pacman/yay salten lo que ya está instalado: correr
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

# ── 1. Repos oficiales (crítico) ───────────────────────────────────
# mapfile mete cada línea de la salida en un elemento del array.
mapfile -t PACMAN_PKGS < <(read_list "$PKG_DIR"/{base,desktop,dev,3dprint,virt}.txt)

# Microcode según el fabricante de la CPU (correcciones de firmware al arranque).
case "$(grep -m1 '^vendor_id' /proc/cpuinfo)" in
  *GenuineIntel*)  PACMAN_PKGS+=(intel-ucode) ;;
  *AuthenticAMD*)  PACMAN_PKGS+=(amd-ucode) ;;
esac

echo "→ pacman: ${#PACMAN_PKGS[@]} paquetes"
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# ── 2. AUR (opcional) ──────────────────────────────────────────────
# aur_install: instala del AUR y, si algo falla (paru roto, paquete que ya no
# existe, compilación que peta), lo avisa pero NO aborta el instalador.
aur_install() {
  (( $# )) || return 0
  # yay es el ayudante de Nanuk; si una máquina ya trae paru, también vale.
  local helper; helper="$(command -v yay || command -v paru || true)"
  if [[ -z "$helper" ]]; then
    echo "⚠ sin ayudante del AUR (yay/paru); se omite: $*"
    return 0
  fi
  echo "→ AUR ($(basename "$helper")): $*"
  "$helper" -S --needed --noconfirm "$@" || echo "⚠ Falló parte del AUR (no es crítico): $*"
}

mapfile -t AUR_PKGS < <(read_list "$PKG_DIR/aur.txt")
aur_install "${AUR_PKGS[@]}"

# ── 3. Extras (opcional) ───────────────────────────────────────────
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
  aur_install "${EXTRA_AUR[@]}"
  echo "✔ extras procesados"
else
  echo "⏭  extras.txt saltado (usa NANUK_EXTRAS=1 para instalarlos)"
fi

# ── 4. Flatpak (opcional) ──────────────────────────────────────────
mapfile -t FLATPAKS < <(read_list "$PKG_DIR/flatpak.txt")
if (( ${#FLATPAKS[@]} )); then
  if command -v flatpak &>/dev/null; then
    # Instalación por usuario (--user): no necesita root y vive en ~/.local.
    flatpak remote-add --user --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo || true
    echo "→ flatpak: ${FLATPAKS[*]}"
    flatpak install --user -y --noninteractive flathub "${FLATPAKS[@]}" \
      || echo "⚠ Falló parte de flatpak (no es crítico): ${FLATPAKS[*]}"
  else
    echo "⚠ flatpak no está instalado; se omite: ${FLATPAKS[*]}"
  fi
fi

echo "✔ Paquetes instalados"
