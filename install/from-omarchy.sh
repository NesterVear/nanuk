#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Migración Omarchy → Nanuk, en la MISMA instalación (sin reinstalar Arch).
#
# Fase A (este script). Omarchy se queda instalado como red de seguridad;
# Nanuk toma el arranque (autologin tty1, sin sddm), la sesión de Hyprland,
# el splash y los dotfiles. Tus archivos de $HOME no se tocan; lo que
# Nanuk reemplaza en ~/.config se aparta con sufijo .bak.<fecha>.
#
#   bash install/from-omarchy.sh     → reinicia → usa Nanuk unos días
#   bash install/rollback-to-omarchy.sh   si quieres volver (solo en fase A)
#   bash install/purge-omarchy.sh    cuando estés a gusto: quita Omarchy (fase B)
#
# Lo que hace antes de lanzar el instalador normal:
#   1. Respaldo de la config de Omarchy y del sistema en ~/.local/share/nanuk-migracion/.
#   2. Protege el bootloader: limine y su hook pasan a "explícitos" (hoy son
#      dependencias del paquete omarchy: si ese paquete se fuera, se irían).
#   3. Quita mise-bin (repo de Omarchy): choca con el `mise` de los repos
#      oficiales que instala Nanuk y abortaría el paso 03.
#   4. Desactiva los servicios de usuario de Omarchy (arrancarían también
#      dentro de la sesión de Nanuk).
#   5. Corre install/install.sh (pasos 01-07). El paso 05 desactiva sddm.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

NANUK_ROOT="${NANUK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
die() { echo "✖ $*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "ejecútalo con tu usuario normal, no como root"
pacman -Q omarchy &>/dev/null || die "no veo el paquete 'omarchy' instalado: esto es solo para migrar desde Omarchy"

echo "╔══════════════════════════════════════╗"
echo "║   Omarchy → Nanuk 🐻‍❄️   (fase A)       ║"
echo "╚══════════════════════════════════════╝"
echo
echo "Omarchy se queda instalado por si quieres volver. Al final: reiniciar."
echo
sudo -v
( while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 60; done ) &

# ── 1. Respaldo ─────────────────────────────────────────────────────
BK="$HOME/.local/share/nanuk-migracion/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK"
echo "→ respaldo en $BK"
tar czf "$BK/home-config.tar.gz" -C "$HOME" --ignore-failed-read \
  .config/hypr .config/omarchy .local/state/omarchy .config/uwsm \
  .config/kitty .config/starship.toml .config/nvim .bashrc .bash_profile 2>/dev/null || true
sudo tar czf "$BK/etc.tar.gz" -C / --ignore-failed-read \
  etc/sddm.conf.d etc/default/limine etc/limine-entry-tool.d etc/mkinitcpio.conf \
  etc/pacman.conf etc/systemd/system/getty@tty1.service.d 2>/dev/null || true
sudo chown "$USER" "$BK/etc.tar.gz"
pacman -Qqe > "$BK/paquetes-explicitos.txt"
pacman -Qq  > "$BK/paquetes-todos.txt"
systemctl --user list-unit-files 'omarchy-*' --state=enabled --no-legend | awk '{print $1}' \
  > "$BK/omarchy-user-units.txt" || true
echo "✔ respaldo hecho"

# ── 2. Proteger el arranque ────────────────────────────────────────
# limine-mkinitcpio-hook regenera la imagen de arranque (UKI) en cada
# kernel nuevo. Sin él, el siguiente kernel dejaría el equipo sin arrancar.
sudo pacman -D --asexplicit limine limine-mkinitcpio-hook >/dev/null
echo "✔ limine y limine-mkinitcpio-hook marcados como explícitos"

# ── 3. mise-bin → mise ─────────────────────────────────────────────
if pacman -Q mise-bin &>/dev/null; then
  # -Rdd: quita SOLO el paquete, sin tocar dependencias ni comprobar quién
  # lo necesita. `mise` (repos oficiales) lo sustituye en el paso 03 y usa
  # los mismos datos de ~/.local/share/mise.
  sudo pacman -Rdd --noconfirm mise-bin
  echo "✔ mise-bin quitado (el paso 03 instala 'mise' de los repos oficiales)"
fi

# ── 4. Servicios de usuario de Omarchy ─────────────────────────────
while read -r unit; do
  [[ -n "$unit" ]] || continue
  systemctl --user disable "$unit" &>/dev/null && echo "  desactivado: $unit"
done < "$BK/omarchy-user-units.txt"
echo "✔ servicios de usuario de Omarchy desactivados (siguen en $BK por si vuelves)"

# ── 5. Instalador de Nanuk ─────────────────────────────────────────
echo
bash "$NANUK_ROOT/install/install.sh"

# ── 6. Cierre ──────────────────────────────────────────────────────
cat > "$BK/LEEME.md" <<EOT
# Migración Omarchy → Nanuk — $(date '+%Y-%m-%d %H:%M')

Respaldo de este directorio:
- home-config.tar.gz : ~/.config/hypr, ~/.config/omarchy, uwsm, kitty, starship, nvim, .bashrc, .bash_profile
- etc.tar.gz         : sddm.conf.d, /etc/default/limine, limine-entry-tool.d, mkinitcpio.conf, pacman.conf
- paquetes-*.txt     : lista de paquetes antes de migrar
- omarchy-user-units.txt : servicios de usuario de Omarchy que se desactivaron

Volver a Omarchy (solo mientras no hayas corrido purge-omarchy.sh):
    bash $NANUK_ROOT/install/rollback-to-omarchy.sh

Quitar Omarchy del todo cuando Nanuk te convenza:
    bash $NANUK_ROOT/install/purge-omarchy.sh
EOT
echo
echo "✔ Fase A completada. Respaldo y notas en: $BK"
echo
echo "  Ahora: REINICIA. Deberías ver el splash de Nanuk, la contraseña del"
echo "  disco, y entrar directo a Hyprland (sin sddm)."
echo "  Si la pantalla de contraseña LUKS no se dibuja: pulsa Esc y escribe."
echo "  Para volver a Omarchy: bash $NANUK_ROOT/install/rollback-to-omarchy.sh"
