#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 07 — Afinado del stack de desarrollo.
#
#   - Rust: toolchain 'stable' con rustup.
#   - Neovim: LazyVim (si no hay config previa) + colorscheme Nanuk.
#   - Docker / MariaDB / grupos: ya se hizo en 04-services.
#   - PHP, Python, R, Node, Lua: se instalan como paquetes en 03; nada
#     que configurar aquí. Versiones extra: `nanuk lang <lenguaje>`.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

NANUK_ROOT="${NANUK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# ── Rust ──────────────────────────────────────────────────────────
if command -v rustup &>/dev/null; then
  if ! rustup show active-toolchain &>/dev/null; then
    echo "→ Rust: instalando toolchain 'stable'..."
    rustup default stable
  else
    echo "✔ Rust ya tiene un toolchain activo"
  fi
fi

# ── Neovim / LazyVim ─────────────────────────────────────────────
NVIM_DIR="$HOME/.config/nvim"
if [[ ! -e "$NVIM_DIR" ]]; then
  echo "→ Clonando LazyVim (plantilla oficial)..."
  git clone --depth 1 https://github.com/LazyVim/starter "$NVIM_DIR"
  rm -rf "$NVIM_DIR/.git"
elif [[ ! -f "$NVIM_DIR/init.lua" ]]; then
  echo "⚠ ~/.config/nvim ya existe y no parece LazyVim — no lo toco."
fi

# Tema Nanuk: colorscheme + spec de plugin. Son NUESTROS: se refrescan
# siempre. El resto de ~/.config/nvim es tuyo y no se toca.
if [[ -d "$NVIM_DIR/lua/plugins" ]]; then
  mkdir -p "$NVIM_DIR/colors"
  install -m 644 "$NANUK_ROOT/config/nvim/colors/nanuk.lua"  "$NVIM_DIR/colors/nanuk.lua"
  install -m 644 "$NANUK_ROOT/config/nvim/plugins/nanuk.lua" "$NVIM_DIR/lua/plugins/nanuk.lua"
  echo "✔ colorscheme Nanuk para Neovim desplegado"
fi

echo "✔ 07-dev completado"
