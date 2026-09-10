#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 02 — Pacman a punto + helper del AUR (paru).
#
# - Activa Color y ParallelDownloads en /etc/pacman.conf
# - Actualiza el sistema entero (Arch es rolling: instalar sobre un sistema
#   viejo rompe cosas)
# - Instala base-devel (lo que makepkg necesita para compilar)
# - Instala paru:
#     1. binario precompilado (paru-bin, ~10 s)
#     2. si ese binario no arranca → lo compila desde fuente, con cuidado
#        de no reventar por falta de RAM en una VM
#   Si aun así no se puede, se avisa y se sigue: el escritorio NO necesita
#   paru (todo vive en repos oficiales); se puede instalar luego con `nanuk`.
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

# ILoveCandy: la barra de progreso de pacman pasa a ser Pac-Man comiéndose
# los puntos (C·····). Guiño clásico de Arch. Se añade bajo [options].
grep -q '^ILoveCandy' /etc/pacman.conf \
  || sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf

echo "→ Actualizando el sistema..."
sudo pacman -Syu --noconfirm

echo "→ Instalando base-devel..."
sudo pacman -S --noconfirm --needed base-devel git

# ── helpers ────────────────────────────────────────────────────────
# paru_works: ¿está instalado Y su binario arranca? "error while loading
# shared libraries" ocurre cuando paru-bin quedó enlazado a una versión de
# libalpm que el último `pacman -Syu` ya cambió, y el paquete precompilado
# aún no se ha regenerado. Por eso no basta con `command -v paru`.
paru_works() {
  command -v paru &>/dev/null && paru --version &>/dev/null
}

# build_from_aur <paquete> [VAR=val ...] : clona de la AUR y compila/instala.
# Las asignaciones extra se pasan al entorno de makepkg (para CARGO_*, RUSTFLAGS).
build_from_aur() {
  local pkg="$1"; shift
  local dir; dir="$(mktemp -d)"
  git clone --depth 1 "https://aur.archlinux.org/$pkg.git" "$dir/$pkg"
  # makepkg -si: -s instala dependencias de compilación, -i instala el
  # resultado. Se ejecuta como usuario normal; pide sudo solo al instalar.
  ( cd "$dir/$pkg" && env "$@" makepkg -si --noconfirm )
  local rc=$?
  rm -rf "$dir"
  return $rc
}

# ram_mb: RAM disponible ahora mismo, en MiB.
ram_mb() { awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo; }

# ── instalación de paru ────────────────────────────────────────────
install_paru() {
  paru_works && { echo "✔ paru ya está instalado y funciona"; return 0; }

  # Limpia restos de intentos anteriores (paru-bin y paru dan el mismo binario).
  pacman -Qq paru-bin &>/dev/null && sudo pacman -Rns --noconfirm paru-bin || true
  pacman -Qq paru     &>/dev/null && sudo pacman -Rns --noconfirm paru     || true

  echo "→ Instalando paru-bin (binario precompilado)..."
  build_from_aur paru-bin || true
  paru_works && { echo "✔ paru instalado (binario)"; return 0; }

  echo "⚠ paru-bin no arranca (desajuste de libalpm). Compilando paru desde fuente..."
  sudo pacman -Rns --noconfirm paru-bin || true
  # rustup (no 'rust': chocan, y dev.txt ya trae rustup). Toolchain mínimo.
  sudo pacman -S --noconfirm --needed rustup
  rustup default stable 2>/dev/null || rustup toolchain install stable

  # Compilar Rust en una VM con poca RAM la mata: rustc muere con SIGKILL
  # (el OOM killer). Dos defensas:
  #   · CARGO_BUILD_JOBS=1  → un rustc a la vez (el pico viene de enlazar
  #     varias crates en paralelo).
  #   · swap temporal en zram si hay menos de ~3 GB libres. zram es RAM
  #     comprimida: no toca disco y se quita al terminar.
  local swap_dev=""
  if (( $(ram_mb) < 5000 )); then
    echo "→ RAM baja ($(ram_mb) MB libres): añadiendo 4 GB de swap temporal (zram)..."
    if sudo modprobe zram 2>/dev/null; then
      swap_dev=$(cat /sys/class/zram-control/hot_add 2>/dev/null || echo 0)
      swap_dev="/dev/zram${swap_dev}"
      echo 4G   | sudo tee "/sys/block/$(basename "$swap_dev")/disksize" >/dev/null
      sudo mkswap "$swap_dev" >/dev/null && sudo swapon -p 20 "$swap_dev" || swap_dev=""
    fi
  fi

  build_from_aur paru CARGO_BUILD_JOBS=1 RUSTFLAGS="-C debuginfo=0" || true

  if [[ -n "$swap_dev" ]]; then
    sudo swapoff "$swap_dev" || true
    sudo bash -c "echo $(basename "$swap_dev" | tr -dc 0-9) > /sys/class/zram-control/hot_remove" 2>/dev/null || true
  fi

  if paru_works; then
    echo "✔ paru instalado (compilado desde fuente)"
  else
    echo "⚠ No se pudo instalar paru. El escritorio se instala igual;" >&2
    echo "  cuando tengas más RAM, ejecuta:  bash $NANUK_ROOT/install/02-pacman.sh" >&2
  fi
}


install_paru || true
