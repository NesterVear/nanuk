#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 01 — Preflight: verificar que es seguro instalar.
# Si algo no cuadra, abortamos ANTES de tocar el sistema.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

fail() {
  # Imprime a stderr (>&2) y sale con código de error.
  echo "✖ $1" >&2
  exit 1
}

# 1. ¿Es Arch? Leemos /etc/os-release, que toda distro moderna trae.
#    'source' lo carga como variables de bash (ID, NAME, etc.).
#    Vale Arch puro (ID=arch) y sus derivadas que siguen siendo Arch por
#    debajo, como Omarchy (ID=omarchy, ID_LIKE=arch): así funciona la
#    migración sin reinstalar (install/from-omarchy.sh).
#    /etc/arch-release (del paquete filesystem) también vale: hay quien cambia
#    os-release a otra distro para que un programa de terceros se instale.
source /etc/os-release
[[ "$ID" == "arch" || " ${ID_LIKE:-} " == *" arch "* || -f /etc/arch-release ]] \
  || fail "Esto no es Arch Linux ni una derivada (ID=$ID). Nanuk solo se instala sobre Arch."

# 2. ¿NO somos root? Se instala como usuario normal; sudo se usa puntualmente.
#    (Correr todo como root dejaría archivos de $HOME siendo de root: dolor.)
[[ $EUID -ne 0 ]] || fail "No ejecutes el instalador como root. Usa tu usuario normal (con sudo disponible)."

# 3. ¿Hay sudo?
command -v sudo &>/dev/null || fail "Falta sudo. Instálalo y agrega tu usuario a wheel."

# 4. ¿Hay internet? Un HEAD request rápido a los mirrors de Arch.
curl -sfI --max-time 10 https://archlinux.org >/dev/null \
  || fail "Sin conexión a internet (no se pudo alcanzar archlinux.org)."

echo "✔ Arch Linux detectado"
echo "✔ Usuario normal con sudo"
echo "✔ Conexión a internet"
