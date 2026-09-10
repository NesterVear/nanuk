#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 02 — Pacman a punto + ayudante del AUR.
#
# - Activa Color y ParallelDownloads en /etc/pacman.conf
# - Añade ILoveCandy: la barra de progreso de pacman pasa a ser Pac-Man
#   (el guiño arcade que quieres SOLO en la terminal)
# - Actualiza el sistema entero (Arch es rolling: instalar sobre un
#   sistema viejo rompe cosas)
# - Instala base-devel (lo que makepkg necesita para compilar)
# - Instala YAY como ayudante del AUR:
#     1. yay-bin  → binario precompilado, sin compilar nada (~10 s)
#     2. yay      → si el binario no arranca, se compila desde fuente.
#        yay está en Go: un binario, pico ~400 MB de RAM, ~1 min. (paru
#        está en Rust: ~150 crates y pico de ~2 GB — inviable en una VM
#        pequeña. Por eso Nanuk usa yay.)
#   Si aun así no se puede, se avisa y se sigue: el escritorio NO necesita
#   el AUR (todo vive en repos oficiales); se instala luego con `nanuk`.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

NANUK_ROOT="${NANUK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# ── pacman.conf ──────────────────────────────────────────────────────
# Las opciones vienen comentadas de fábrica ("#Color"). sed las descomenta.
# Correrlo dos veces no hace nada la segunda: idempotente.
echo "→ Configurando pacman..."
sudo sed -i \
  -e 's/^#Color/Color/' \
  -e 's/^#ParallelDownloads.*/ParallelDownloads = 10/' \
  /etc/pacman.conf

# ILoveCandy: la barra de progreso de pacman se convierte en Pac-Man
# comiéndose los puntos (C·····) al instalar/actualizar. Se añade bajo
# [options]. Usa el color de la barra de progreso: en el tema sale gris.
grep -q '^ILoveCandy' /etc/pacman.conf \
  || sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf

echo "→ Actualizando el sistema..."
sudo pacman -Syu --noconfirm

echo "→ Instalando base-devel..."
sudo pacman -S --noconfirm --needed base-devel git

# ── helpers ────────────────────────────────────────────────────────
# aur_works: ¿está instalado el ayudante Y su binario arranca? "error while
# loading shared libraries" ocurre cuando el paquete precompilado quedó
# enlazado a una versión de libalpm que el último `pacman -Syu` ya cambió.
# Por eso no basta con `command -v`.
aur_works() {
  command -v yay &>/dev/null && yay --version &>/dev/null
}

# build_from_aur <paquete> : clona de la AUR y compila/instala.
# `nice -n 19` deja la compilación con la prioridad más baja, así la VM
# sigue respondiendo aunque la CPU esté al 100%.
build_from_aur() {
  local pkg="$1"
  local dir; dir="$(mktemp -d)"
  git clone --depth 1 "https://aur.archlinux.org/$pkg.git" "$dir/$pkg"
  # makepkg -si: -s instala dependencias de compilación, -i instala el
  # resultado. Se ejecuta como usuario normal; pide sudo solo al instalar.
  ( cd "$dir/$pkg" && nice -n 19 makepkg -si --noconfirm )
  local rc=$?
  rm -rf "$dir"
  return $rc
}

# ── instalación de yay ─────────────────────────────────────────────
install_aur_helper() {
  aur_works && { echo "✔ yay ya está instalado y funciona"; return 0; }

  # Limpia restos de intentos anteriores (yay-bin y yay dan el mismo binario).
  # También un paru roto de una instalación previa: ya no se usa.
  for p in yay-bin yay paru-bin paru; do
    pacman -Qq "$p" &>/dev/null && sudo pacman -Rns --noconfirm "$p" || true
  done

  echo "→ Instalando yay-bin (binario precompilado, no compila nada)..."
  build_from_aur yay-bin || true
  aur_works && { echo "✔ yay instalado (binario)"; return 0; }

  echo "⚠ yay-bin no arranca (desajuste de libalpm). Compilando yay desde fuente..."
  sudo pacman -Rns --noconfirm yay-bin || true
  # go: la única dependencia de compilación de yay. makepkg -s la instalaría
  # igual, pero así queda explícito lo que entra.
  sudo pacman -S --noconfirm --needed go
  build_from_aur yay || true

  if aur_works; then
    echo "✔ yay instalado (compilado desde fuente)"
  else
    echo "⚠ No se pudo instalar yay. El escritorio se instala igual;" >&2
    echo "  reintenta luego con:  bash $NANUK_ROOT/install/02-pacman.sh" >&2
  fi
}

install_aur_helper || true
