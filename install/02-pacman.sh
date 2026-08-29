#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 02 — Pacman a punto + helper del AUR (paru).
#
# - Activa Color y ParallelDownloads en /etc/pacman.conf
# - Instala base-devel (necesario para compilar paquetes del AUR)
# - Instala paru compilándolo desde el AUR (la única vez que se hace a mano;
#   después paru se encarga de todo el AUR)
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

# Sincronizar bases de datos y actualizar el sistema antes de instalar nada.
# (Arch es rolling: instalar paquetes sobre un sistema desactualizado rompe cosas.)
echo "→ Actualizando el sistema..."
sudo pacman -Syu --noconfirm

# ── base-devel + git ────────────────────────────────────────────────
# base-devel trae gcc, make, fakeroot... todo lo que makepkg necesita.
echo "→ Instalando base-devel..."
sudo pacman -S --noconfirm --needed base-devel git

# ── paru ────────────────────────────────────────────────────────────
if command -v paru &>/dev/null; then
  echo "✔ paru ya está instalado"
else
  echo "→ Compilando paru desde el AUR..."
  # Compilamos en un directorio temporal que se limpia al final.
  BUILD_DIR="$(mktemp -d)"
  git clone https://aur.archlinux.org/paru-bin.git "$BUILD_DIR/paru-bin"
  # makepkg -si: compila (-s resuelve dependencias) e instala (-i).
  # Se ejecuta como usuario normal; makepkg pide sudo solo para instalar.
  (cd "$BUILD_DIR/paru-bin" && makepkg -si --noconfirm)
  rm -rf "$BUILD_DIR"
  echo "✔ paru instalado"
fi
