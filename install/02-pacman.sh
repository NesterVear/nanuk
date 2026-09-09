#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 02 — Pacman a punto + helper del AUR (paru).
#
# - Activa Color y ParallelDownloads en /etc/pacman.conf
# - Actualiza el sistema entero (Arch es rolling: instalar sobre un sistema
#   viejo rompe cosas)
# - Instala base-devel (lo que makepkg necesita para compilar)
# - Instala paru: primero el binario precompilado (paru-bin, ~10 s) y, si ese
#   binario no arranca, lo compila desde fuente (paru, unos minutos).
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── pacman.conf ──────────────────────────────────────────────────────
# Las opciones vienen comentadas de fábrica ("#Color"). sed las descomenta.
# Correrlo dos veces no hace nada la segunda: idempotente.
echo "→ Configurando pacman..."
sudo sed -i \
  -e 's/^#Color/Color/' \
  -e 's/^#ParallelDownloads.*/ParallelDownloads = 10/' \
  /etc/pacman.conf

echo "→ Actualizando el sistema..."
sudo pacman -Syu --noconfirm

echo "→ Instalando base-devel..."
sudo pacman -S --noconfirm --needed base-devel git

# ── paru ────────────────────────────────────────────────────────────
# paru_works: ¿está instalado Y su binario arranca? "error while loading
# shared libraries" ocurre cuando paru-bin quedó enlazado a una versión de
# libalpm que el último `pacman -Syu` ya cambió, y el paquete precompilado
# aún no se ha regenerado. Por eso no basta con `command -v paru`.
paru_works() {
  command -v paru &>/dev/null && paru --version &>/dev/null
}

build_from_aur() {
  # build_from_aur <nombre-paquete-aur>
  local pkg="$1" dir
  dir="$(mktemp -d)"
  git clone --depth 1 "https://aur.archlinux.org/$pkg.git" "$dir/$pkg"
  # makepkg -si: -s instala dependencias de compilación, -i instala el
  # resultado. Se ejecuta como usuario normal; pide sudo solo al instalar.
  ( cd "$dir/$pkg" && makepkg -si --noconfirm )
  rm -rf "$dir"
}

if paru_works; then
  echo "✔ paru ya está instalado y funciona"
else
  # Si hay un paru roto de un intento anterior, quítalo antes de reinstalar.
  pacman -Qq paru-bin &>/dev/null && sudo pacman -Rns --noconfirm paru-bin || true
  pacman -Qq paru     &>/dev/null && sudo pacman -Rns --noconfirm paru     || true

  echo "→ Instalando paru-bin (binario precompilado)..."
  build_from_aur paru-bin

  if paru_works; then
    echo "✔ paru instalado (binario)"
  else
    echo "⚠ paru-bin no arranca (desajuste de libalpm). Compilando paru desde fuente..."
    sudo pacman -Rns --noconfirm paru-bin || true
    # paru (fuente) necesita el compilador de Rust; 'rust' trae cargo.
    sudo pacman -S --noconfirm --needed rust
    build_from_aur paru
    paru_works || { echo "✖ No se pudo instalar paru" >&2; exit 1; }
    echo "✔ paru instalado (compilado desde fuente)"
  fi
fi
