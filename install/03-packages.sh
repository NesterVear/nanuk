#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 03 — Paquetes.
#
# Lee las listas de packages/*.txt e instala en tres tandas:
#   1. repos oficiales  → pacman   (base, desktop, dev, 3dprint, virt, security)   ← CRÍTICO
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
mapfile -t PACMAN_PKGS < <(read_list "$PKG_DIR"/{base,desktop,dev,3dprint,virt,security}.txt)

# Microcode según el fabricante de la CPU (correcciones de firmware al arranque).
# thermald (control térmico) solo existe para Intel: en AMD no hace nada.
case "$(grep -m1 '^vendor_id' /proc/cpuinfo)" in
  *GenuineIntel*)  PACMAN_PKGS+=(intel-ucode thermald) ;;
  *AuthenticAMD*)  PACMAN_PKGS+=(amd-ucode) ;;
esac

# Solo lo que FALTA. `pacman -T` (deptest) imprime los nombres que ningún
# paquete instalado satisface, contando los "provides": si ya tienes, por
# ejemplo, nodejs-lts-jod (que provee nodejs), `nodejs` no se pide. Sin esto
# pacman querría reemplazarlo y, con --noconfirm, la respuesta a "¿reemplazar?"
# es NO: el paso abortaría (pasó migrando desde Omarchy).
mapfile -t MISSING < <(pacman -T "${PACMAN_PKGS[@]}" || true)
echo "→ pacman: ${#PACMAN_PKGS[@]} paquetes en las listas, faltan ${#MISSING[@]}"
if (( ${#MISSING[@]} )); then
  sudo pacman -S --needed --noconfirm "${MISSING[@]}"
fi
# Marcarlos como instalados "explícitamente". Si alguno ya estaba como
# dependencia de otra cosa (p. ej. de un paquete de Omarchy), `--needed` lo
# salta y se queda como dependencia: un `pacman -Rns` de esa otra cosa se lo
# llevaría por delante. Así quedan protegidos. Solo los que existen con ese
# nombre (a nodejs-lts-jod no se le puede marcar como "nodejs"). Idempotente.
mapfile -t PRESENT < <(pacman -Qq "${PACMAN_PKGS[@]}" 2>/dev/null || true)
if (( ${#PRESENT[@]} )); then
  sudo pacman -D --asexplicit "${PRESENT[@]}" >/dev/null
fi

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
