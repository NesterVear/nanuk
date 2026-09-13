#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Construye la ISO de Nanuk.
#
#   sudo bash iso/build.sh              → iso/out/nanuk-YYYY.MM.DD-x86_64.iso
#
# Necesita el paquete `archiso` (mkarchiso) y root. Antes de llamar a
# mkarchiso copia el repo entero (con .git, para que `nanuk update` pueda
# hacer pull después) dentro de airootfs/usr/local/share/nanuk: así el
# instalador y los dotfiles viajan en la ISO y no dependen de GitHub hasta
# el primer `nanuk update`.
#
# Variables: NANUK_ISO_WORK (por defecto /var/tmp/nanuk-iso-work; necesita
# ~6 GB libres) y NANUK_ISO_OUT (por defecto iso/out).
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

PROFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$PROFILE")"
WORK="${NANUK_ISO_WORK:-/var/tmp/nanuk-iso-work}"
OUT="${NANUK_ISO_OUT:-$PROFILE/out}"
PAYLOAD="$PROFILE/airootfs/usr/local/share/nanuk"

[[ $EUID -eq 0 ]] || { echo "✖ mkarchiso necesita root: sudo bash iso/build.sh" >&2; exit 1; }
command -v mkarchiso &>/dev/null || { echo "✖ falta archiso: pacman -S archiso" >&2; exit 1; }

echo "→ copiando el repo a la ISO ($PAYLOAD)"
mkdir -p "$PAYLOAD"
# Fuera: la propia iso/ (recursivo), salidas de builds, la maqueta de diseño, la
# web y la documentación interna (la ISO es pública).
rsync -a --delete "$REPO/" "$PAYLOAD/" \
  --exclude /iso --exclude /design --exclude /site --exclude '*.pkg.tar.zst' \
  --exclude /interno --exclude /CLAUDE.md --exclude /PLAN.md
# Si el repo se construye desde una copia sin remoto, que el sistema instalado
# apunte a GitHub igualmente.
git -C "$PAYLOAD" remote set-url origin https://github.com/nestervear/nanuk.git 2>/dev/null || true

echo "→ mkarchiso (tarda: descarga paquetes y comprime; la salida va a $OUT)"
rm -rf "$WORK"
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"
rm -rf "$WORK"

echo
echo "✔ ISO lista:"
ls -lh "$OUT"/*.iso
echo
echo "Probar en QEMU (UEFI):"
echo "  run_archiso -u -i $OUT/nanuk-*.iso      # viene con archiso"
echo "Grabar a USB:"
echo "  sudo dd if=$OUT/nanuk-*.iso of=/dev/sdX bs=4M status=progress oflag=sync"
