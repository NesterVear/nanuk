#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Fase B: quitar Omarchy de una máquina que ya arranca y trabaja con Nanuk.
# Después de esto NO hay rollback-to-omarchy.sh (habría que reinstalar).
#
# Lo delicado no es borrar: es lo que se lleva por delante un `pacman -Rns`
# del paquete omarchy, porque tiene como DEPENDENCIAS cosas que Nanuk usa
# (hyprland, uwsm, limine, limine-mkinitcpio-hook, gum, jq...). Por eso,
# antes de quitar nada, todo lo que Nanuk necesita se marca como explícito.
#
# Orden:
#   1. Comprobar que estás en una sesión Nanuk.
#   2. Proteger paquetes (listas de Nanuk + bootloader + microcode + yay).
#   3. Config de limine-entry-tool para Nanuk (la de Omarchy se va con su paquete):
#      así la imagen de arranque sigue siendo UKI y el menú dice "Nanuk".
#   4. Quitar omarchy, omarchy-settings, omarchy-nvim, omarchy-keyring (+ sus
#      dependencias huérfanas: sddm, quickshell, snapper...). Muestra la lista
#      y pide confirmación.
#   5. Restaurar los .pacsave de /etc que eran configuración tuya (docker, sysctl).
#   6. Quitar el repositorio [omarchy] de pacman.conf.
#   7. Regenerar initramfs/UKI + entradas de Limine y VERIFICAR que existen.
#   8. Limpiar ~/.bashrc (bloque de Omarchy) y apartar los restos a un respaldo.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

NANUK_ROOT="${NANUK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
die() { echo "✖ $*" >&2; exit 1; }
read_list() { sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$@"; }

[[ $EUID -ne 0 ]] || die "con tu usuario normal, no root"
pacman -Q omarchy &>/dev/null || die "Omarchy ya no está instalado; nada que purgar"
head -1 "$HOME/.config/hypr/hyprland.lua" 2>/dev/null | grep -q Nanuk \
  || die "tu ~/.config/hypr/hyprland.lua no es el de Nanuk: corre antes from-omarchy.sh y reinicia"
[[ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]] \
  || die "no veo el autologin de Nanuk en tty1: corre antes from-omarchy.sh"

echo "╔══════════════════════════════════════╗"
echo "║   Purgar Omarchy   (fase B, sin vuelta) ║"
echo "╚══════════════════════════════════════╝"
sudo -v
( while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 60; done ) &

BK="$HOME/.local/share/nanuk-migracion/omarchy-restos-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK"
MARK="$BK/.marca"; touch "$MARK"   # para encontrar los .pacsave que cree ESTE proceso

# ── 2. Proteger paquetes ───────────────────────────────────────────
mapfile -t WANT < <(read_list "$NANUK_ROOT"/packages/{base,desktop,dev,3dprint,virt,security}.txt)
WANT+=(limine limine-mkinitcpio-hook intel-ucode amd-ucode yay mise)
KEEP=()
for p in "${WANT[@]}"; do pacman -Q -- "$p" &>/dev/null && KEEP+=("$p"); done
sudo pacman -D --asexplicit "${KEEP[@]}" >/dev/null
echo "✔ ${#KEEP[@]} paquetes de Nanuk protegidos (explícitos)"

# ── 3. limine-entry-tool: config de Nanuk ──────────────────────────
# Copia de lo que Omarchy definía (UKI, nombre del SO, parámetros de un
# arranque silencioso) sin la parte de snapshots (la raíz es ext4).
if [[ -d /etc/limine-entry-tool.d ]]; then
  sudo tee /etc/limine-entry-tool.d/nanuk.conf >/dev/null <<'EOT'
# Nanuk — entradas de Limine (limine-entry-tool). Sustituye a omarchy-*.conf.
TARGET_OS_NAME="Nanuk"
CUSTOM_UKI_NAME="nanuk"
ENABLE_UKI=yes
ENABLE_LIMINE_FALLBACK=yes
FIND_BOOTLOADERS=yes
BOOT_ORDER="*, *fallback"
KERNEL_CMDLINE[default]+=" quiet splash loglevel=0 systemd.show_status=false rd.udev.log_level=0 vt.global_cursor_default=0"
KERNEL_CMDLINE[default]+=" initramfs_async=0"
EOT
  echo "✔ /etc/limine-entry-tool.d/nanuk.conf escrito"
fi

# ── 4. Quitar Omarchy ──────────────────────────────────────────────
CORE=(omarchy omarchy-settings omarchy-nvim omarchy-keyring)
echo
echo "Se quitarían estos paquetes (omarchy + dependencias que ya nadie usa):"
sudo pacman -Rs --print --print-format '  %n' "${CORE[@]}" | sort
echo
read -r -p "¿Seguir? Escribe 'si' para continuar: " ok
[[ "$ok" == "si" ]] || die "cancelado; no se ha quitado nada"
sudo pacman -Rns --noconfirm "${CORE[@]}"
echo "✔ paquetes de Omarchy quitados"

# ── 5. .pacsave que eran tuyos ─────────────────────────────────────
# pacman deja como .pacsave los archivos de /etc que el paquete declaraba
# como "backup" (docker/daemon.json, sysctl.d/*). Eran tu configuración:
# los devolvemos a su sitio.
while IFS= read -r f; do
  sudo mv "$f" "${f%.pacsave}"
  echo "  restaurado: ${f%.pacsave}"
done < <(sudo find /etc -name '*.pacsave' -newer "$MARK" 2>/dev/null)

# ── 6. Repositorio [omarchy] fuera ─────────────────────────────────
if grep -q '^\[omarchy\]' /etc/pacman.conf; then
  sudo cp /etc/pacman.conf "$BK/pacman.conf.antes"
  sudo sed -i '/^\[omarchy\]/,/^Server/d' /etc/pacman.conf
  sudo pacman -Sy
  echo "✔ repo [omarchy] quitado de pacman.conf"
fi

# ── 7. Arranque: regenerar y VERIFICAR ─────────────────────────────
echo "→ regenerando initramfs/UKI y entradas de Limine..."
sudo mkinitcpio -P
command -v limine-update &>/dev/null && sudo limine-update || true
if compgen -G "/boot/EFI/Linux/*.efi" >/dev/null && grep -q '^\s*path:' /boot/limine.conf; then
  echo "✔ arranque OK:"
  ls -1 /boot/EFI/Linux/*.efi | sed 's/^/    /'
  grep -E '^/\+|^\s*path:' /boot/limine.conf | sed 's/^/    /'
else
  echo "✖ ATENCIÓN: no encuentro una imagen UKI en /boot/EFI/Linux o entradas en /boot/limine.conf." >&2
  echo "  NO REINICIES todavía. Revisa: sudo mkinitcpio -P && sudo limine-update ; cat /boot/limine.conf" >&2
  exit 1
fi

# ── 8. Restos en $HOME ─────────────────────────────────────────────
# ~/.bashrc: el bloque de Omarchy (source de un archivo que ya no existe).
if grep -q 'OMARCHY_PATH' "$HOME/.bashrc"; then
  cp "$HOME/.bashrc" "$BK/bashrc.antes"
  awk '
    /^# All the default Omarchy aliases/ { off=1 }
    off { print "# [quitado al purgar Omarchy] " $0; if ($0 ~ /source "\$OMARCHY_PATH\/default\/bash\/rc"/) off=0; next }
    { print }
  ' "$HOME/.bashrc" > "$HOME/.bashrc.tmp" && mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"
  echo "✔ bloque de Omarchy comentado en ~/.bashrc (copia en $BK/bashrc.antes)"
fi

# Carpetas y archivos de Omarchy → al respaldo, no a la papelera.
mover() { [[ -e "$1" ]] && { mkdir -p "$BK/$(dirname "${1#"$HOME"/}")"; mv "$1" "$BK/${1#"$HOME"/}"; echo "  apartado: $1"; } || true; }
mover "$HOME/.config/omarchy"
mover "$HOME/.local/state/omarchy"
mover "$HOME/.local/share/omarchy"
mover "$HOME/.config/uwsm/env.d/99-omarchy-upgrade-env"
for f in "$HOME"/.config/systemd/user/*omarchy*; do mover "$f"; done
# En ~/.config/hypr solo son de Nanuk: hyprland.lua, .luarc.json y los enlaces
# hyprlock.conf / hypridle.conf. Todo lo demás era de Omarchy.
for f in "$HOME"/.config/hypr/* "$HOME"/.config/hypr/.[!.]*; do
  case "$(basename "$f")" in
    hyprland.lua|.luarc.json|hyprlock.conf|hypridle.conf) ;;
    *) mover "$f" ;;
  esac
done
[[ -d /etc/sddm.conf.d ]] && { sudo mv /etc/sddm.conf.d "$BK/etc-sddm.conf.d"; sudo chown -R "$USER" "$BK/etc-sddm.conf.d"; echo "  apartado: /etc/sddm.conf.d"; }
systemctl --user daemon-reload || true
sudo systemctl daemon-reload

echo
echo "✔ Omarchy purgado. Restos guardados en $BK (bórralo cuando quieras)."
echo "  Paquetes que venían del repo de Omarchy y siguen instalados (typora, code, localsend,"
echo "  yay, limine-mkinitcpio-hook...): ya no reciben updates de ahí; están con el mismo"
echo "  nombre en el AUR → yay -S <paquete> los vuelve a enganchar."
echo "  Reinicia para comprobar el arranque."
