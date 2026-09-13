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
#      así la imagen de arranque sigue siendo UKI.
#   4. Quitar omarchy, omarchy-settings, omarchy-nvim, omarchy-keyring (+ sus
#      dependencias huérfanas: sddm, quickshell, snapper...). Muestra la lista
#      y pide confirmación.
#   5. Restaurar los .pacsave de /etc que eran configuración tuya (docker, sysctl).
#   6. Quitar el repositorio [omarchy] de pacman.conf.
#   7. Restos del sistema que no son de ningún paquete: /etc/os-release, el
#      nombre en el menú de Limine, el espejo de Omarchy, respaldos .bak, etc.
#   8. Regenerar initramfs/UKI + entradas de Limine y VERIFICAR que existen.
#   9. Limpiar ~/.bashrc (bloque de Omarchy) y apartar los restos a un respaldo.
#  10. Buscar lo que aún se llame "omarchy" y enseñarlo.
#
# Se puede repetir: si Omarchy ya no está instalado, se salta 2 y 4-6 y solo
# limpia restos y verifica.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

NANUK_ROOT="${NANUK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
die() { echo "✖ $*" >&2; exit 1; }
read_list() { sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$@"; }

[[ $EUID -ne 0 ]] || die "con tu usuario normal, no root"
YA_PURGADO=0
pacman -Q omarchy &>/dev/null || YA_PURGADO=1
head -1 "$HOME/.config/hypr/hyprland.lua" 2>/dev/null | grep -q Nanuk \
  || die "tu ~/.config/hypr/hyprland.lua no es el de Nanuk: corre antes from-omarchy.sh y reinicia"
[[ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]] \
  || die "no veo el autologin de Nanuk en tty1: corre antes from-omarchy.sh"

echo "╔══════════════════════════════════════╗"
echo "║   Purgar Omarchy   (fase B, sin vuelta) ║"
echo "╚══════════════════════════════════════╝"
(( YA_PURGADO )) && echo "Omarchy ya no está instalado: solo se limpian restos y se verifica."
sudo -v
( while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 60; done ) &

BK="$HOME/.local/share/nanuk-migracion/omarchy-restos-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK"
MARK="$BK/.marca"; touch "$MARK"   # para encontrar los .pacsave que cree ESTE proceso

# ── 2. Proteger paquetes ───────────────────────────────────────────
if (( ! YA_PURGADO )); then
  mapfile -t WANT < <(read_list "$NANUK_ROOT"/packages/{base,desktop,dev,3dprint,virt,security}.txt)
  WANT+=(limine limine-mkinitcpio-hook intel-ucode amd-ucode yay mise)
  # La instalación por defecto de Omarchy es btrfs, y btrfs-progs solo cuelga de
  # snapper: sin esto se iría con él (y con él fsck.btrfs para el initramfs).
  findmnt -rn -t btrfs >/dev/null && WANT+=(btrfs-progs)
  # Se protege el paquete QUE ESTÁ INSTALADO, no el nombre de la lista: `pacman -Q
  # nodejs` acierta si tienes nodejs-lts-jod (lo "provee"), pero `pacman -D nodejs`
  # no lo encuentra y, con set -e, cortaba la purga aquí.
  KEEP=()
  for p in "${WANT[@]}"; do
    q="$(pacman -Qq -- "$p" 2>/dev/null | head -n 1)" && [[ -n "$q" ]] && KEEP+=("$q")
  done
  mapfile -t KEEP < <(printf '%s\n' "${KEEP[@]}" | sort -u)
  sudo pacman -D --asexplicit "${KEEP[@]}" >/dev/null
  echo "✔ ${#KEEP[@]} paquetes de Nanuk protegidos (explícitos)"
fi

# ── 3. limine-entry-tool: config de Nanuk ──────────────────────────
# Copia de lo que Omarchy definía (UKI, nombre del SO, parámetros de un
# arranque silencioso) sin la parte de snapshots (la raíz es ext4).
if [[ -d /etc/limine-entry-tool.d ]]; then
  sudo tee /etc/limine-entry-tool.d/nanuk.conf >/dev/null <<'EOT'
# Nanuk — entradas de Limine (limine-entry-tool).
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

if (( ! YA_PURGADO )); then
  # ── 4. Quitar Omarchy ────────────────────────────────────────────
  CORE=(omarchy omarchy-settings omarchy-nvim omarchy-keyring)
  echo
  echo "Se quitarían estos paquetes (omarchy + dependencias que ya nadie usa):"
  sudo pacman -Rs --print --print-format '  %n' "${CORE[@]}" | sort
  echo
  read -r -p "¿Seguir? Escribe 'si' para continuar: " ok
  [[ "$ok" == "si" ]] || die "cancelado; no se ha quitado nada"
  sudo pacman -Rns --noconfirm "${CORE[@]}"
  echo "✔ paquetes de Omarchy quitados"

  # ── 5. .pacsave que eran tuyos ───────────────────────────────────
  # pacman deja como .pacsave los archivos de /etc que el paquete declaraba
  # como "backup" (docker/daemon.json, sysctl.d/*). Eran tu configuración:
  # los devolvemos a su sitio.
  while IFS= read -r f; do
    sudo mv "$f" "${f%.pacsave}"
    echo "  restaurado: ${f%.pacsave}"
  done < <(sudo find /etc -name '*.pacsave' -newer "$MARK" 2>/dev/null)

  # ── 6. Repositorio [omarchy] fuera ───────────────────────────────
  if grep -q '^\[omarchy\]' /etc/pacman.conf; then
    sudo cp /etc/pacman.conf "$BK/pacman.conf.antes"
    sudo sed -i '/^\[omarchy\]/,/^Server/d' /etc/pacman.conf
    sudo pacman -Sy
    echo "✔ repo [omarchy] quitado de pacman.conf"
  fi
fi

# ── 7. Restos del sistema ──────────────────────────────────────────
# Lo que Omarchy escribió a mano (sin paquete) no se va con pacman -Rns.
# Se aparta a $BK/sistema/<ruta> o se reescribe guardando copia.
shopt -s nullglob
apartar() {
  sudo test -e "$1" || sudo test -L "$1" || return 0
  sudo mkdir -p "$BK/sistema${1%/*}"
  sudo mv "$1" "$BK/sistema${1%/*}/"
  echo "  apartado: $1"
}
sin_dueno() { ! pacman -Qo "$1" &>/dev/null; }

# /etc/os-release decía "Omarchy" (y de ahí lo copian fastfetch, limine-entry-tool...).
# Vuelve a lo estándar de Arch: un enlace a /usr/lib/os-release. No se escribe
# uno propio: hay programas de terceros (VPNs...) que solo funcionan si
# /usr/lib/os-release dice otra distro, y ese cambio es del usuario: se respeta.
if [[ ! -L /etc/os-release ]] && grep -qi '^ID=omarchy' /etc/os-release 2>/dev/null; then
  apartar /etc/os-release
  sudo ln -s ../usr/lib/os-release /etc/os-release
  echo "✔ /etc/os-release → /usr/lib/os-release ($(. /usr/lib/os-release; echo "$PRETTY_NAME"))"
fi

# Menú de Limine: limine-entry-tool reconoce la entrada por el machine-id y
# conserva su nombre aunque TARGET_OS_NAME diga "Nanuk". Se renombra una vez.
if sudo grep -q '^/+Omarchy$' /boot/limine.conf 2>/dev/null; then
  sudo cp /boot/limine.conf "$BK/limine.conf.antes"
  sudo sed -i -e 's|^/+Omarchy$|/+Nanuk|' -e 's|^comment: Omarchy$|comment: Nanuk|' /boot/limine.conf
  echo "✔ menú de Limine: Omarchy → Nanuk"
fi

# /etc/default/limine: los parámetros (raíz, cifrado) son de ESTA máquina y se
# quedan; solo cambia el comentario de cabecera.
if grep -qi omarchy /etc/default/limine 2>/dev/null; then
  sudo cp /etc/default/limine "$BK/default-limine.antes"
  { echo "# Parámetros de arranque de esta máquina (raíz, cifrado, arranque silencioso)."
    echo "# Los += de /etc/limine-entry-tool.d/ hacen que limine-entry-tool no lea"
    echo "# /etc/kernel/cmdline ni /proc/cmdline: la raíz tiene que ir escrita aquí."
    grep -v '^#' /etc/default/limine
  } | sudo tee /etc/default/limine.nuevo >/dev/null
  sudo mv /etc/default/limine.nuevo /etc/default/limine
  echo "✔ /etc/default/limine: cabecera de Omarchy fuera (parámetros intactos)"
fi

# Espejo: Omarchy fija pacman a su espejo con retraso (stable-mirror.omarchy.org).
# Se cambia por los espejos de Arch más rápidos; tras esto toca `nanuk update`.
CAMBIO_ESPEJO=0
if grep -q 'omarchy\.org' /etc/pacman.d/mirrorlist 2>/dev/null; then
  sudo cp /etc/pacman.d/mirrorlist "$BK/mirrorlist.antes"
  echo "→ espejos: fuera el de Omarchy; reflector elige los de Arch más rápidos (≤3 min)..."
  if ! { sudo timeout 180 reflector --protocol https --latest 20 --sort rate \
           --save /etc/pacman.d/mirrorlist 2>/dev/null \
         && grep -q '^Server' /etc/pacman.d/mirrorlist; }; then
    echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
    echo "  (reflector no respondió: queda el espejo geográfico oficial de Arch)"
  fi
  CAMBIO_ESPEJO=1
  echo "✔ espejos de Arch en /etc/pacman.d/mirrorlist"
fi

# Configuración útil con nombre de Omarchy → mismo contenido, nombre de Nanuk.
if [[ -f /etc/ssh/ssh_config.d/20-omarchy-keepalive.conf ]]; then
  sed 's/^# Omarchy:/# Nanuk:/' /etc/ssh/ssh_config.d/20-omarchy-keepalive.conf \
    | sudo tee /etc/ssh/ssh_config.d/20-nanuk-keepalive.conf >/dev/null
  apartar /etc/ssh/ssh_config.d/20-omarchy-keepalive.conf
fi
for f in /etc/sysctl.d/*omarchy-file-watchers.conf*; do
  [[ -e /etc/sysctl.d/90-nanuk-file-watchers.conf ]] || sudo cp "$f" /etc/sysctl.d/90-nanuk-file-watchers.conf
  apartar "$f"
done
sudo sed -i 's/^# Omarchy override of /# Override of /' /etc/security/faillock.conf 2>/dev/null || true
sudo sed -i 's/^# Omarchy: /# /' /etc/security/pam_env.conf 2>/dev/null || true

# Unidades de systemd con ~/.local/share/omarchy/bin en el PATH (ya no existe).
while IFS= read -r u; do
  sudo cp "$u" "$BK/$(basename "$u").antes"
  sudo sed -i -E 's#[^:"=]*/\.local/share/omarchy/bin/?:##g' "$u"
  echo "  PATH limpiado: $u"
done < <(grep -rlI '\.local/share/omarchy' /etc/systemd/system 2>/dev/null || true)

# /etc/skel/.bashrc (de bash) apuntaba a /usr/share/omarchy: el de Arch.
if grep -q OMARCHY /etc/skel/.bashrc 2>/dev/null; then
  sudo cp /etc/skel/.bashrc "$BK/skel-bashrc.antes"
  sudo tee /etc/skel/.bashrc >/dev/null <<'EOB'
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
EOB
  echo "✔ /etc/skel/.bashrc: el de Arch"
fi

# Sueltos sin paquete: respaldos de la actualización 3→4, redes retiradas,
# PAM del bloqueo de Omarchy, tema de SDDM, snapper sin snapper.
for f in /etc/pacman.conf*.omarchy-*.bak /etc/pacman.d/mirrorlist*.omarchy-*.bak \
         /etc/systemd/network/omarchy-* /etc/pam.d/omarchy-* /usr/share/sddm/themes/omarchy; do
  sin_dueno "$f" && apartar "$f"
done
for f in /etc/pacman.conf.bak /etc/pacman.d/mirrorlist.bak; do
  grep -qi omarchy "$f" 2>/dev/null && apartar "$f"
done
pacman -Q snapper &>/dev/null || { apartar /etc/snapper; apartar /etc/conf.d/snapper; }

# ── 8. Arranque: regenerar y VERIFICAR ─────────────────────────────
echo "→ regenerando initramfs/UKI y entradas de Limine..."
sudo mkinitcpio -P
command -v limine-update &>/dev/null && sudo limine-update || true
# Cada imagen a la que apunta limine.conf tiene que existir (no basta con que
# haya "alguna" .efi: la vieja de Omarchy daría el OK por error).
FALTAN=0; ENTRADAS=0
while IFS= read -r p; do
  ENTRADAS=$((ENTRADAS + 1))
  sudo test -f "/boot$p" || { echo "✖ limine.conf apunta a /boot$p y no existe" >&2; FALTAN=1; }
done < <(sudo sed -n 's|^[[:space:]]*path: boot():\(/EFI/Linux/[^#]*\).*|\1|p' /boot/limine.conf)
if (( ENTRADAS > 0 && ! FALTAN )); then
  echo "✔ arranque OK:"
  sudo grep -E '^/\+|^\s*path:' /boot/limine.conf | sed 's/#.*//; s/^/    /'
  # Imágenes viejas que ya no usa ninguna entrada (la de Omarchy pesa ~50 MB en la ESP).
  for f in /boot/EFI/Linux/omarchy_*.efi; do
    sudo grep -qF "${f#/boot}" /boot/limine.conf || { sudo rm -f "$f"; echo "  borrada imagen sin uso: $f"; }
  done
else
  echo "✖ ATENCIÓN: no encuentro las imágenes UKI de /boot/limine.conf." >&2
  echo "  NO REINICIES todavía. Revisa: sudo mkinitcpio -P && sudo limine-update ; cat /boot/limine.conf" >&2
  exit 1
fi

# ── 9. Restos en $HOME ─────────────────────────────────────────────
# ~/.bashrc: el bloque de Omarchy (source de un archivo que ya no existe) y los
# comentarios que dejaba una versión anterior de este script.
if grep -qE 'OMARCHY_PATH|/usr/share/omarchy/|^# \[quitado al purgar Omarchy\]' "$HOME/.bashrc"; then
  cp "$HOME/.bashrc" "$BK/bashrc.antes"
  awk '
    /^# All the default Omarchy aliases/ { off=1 }
    off { if ($0 ~ /source "\$OMARCHY_PATH\/default\/bash\/rc"/) off=0; next }
    /^# \[quitado al purgar Omarchy\]/ || /^# Omarchy environment/ || /\/usr\/share\/omarchy\// { next }
    { print }
  ' "$HOME/.bashrc" > "$HOME/.bashrc.tmp" && mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"
  echo "✔ bloque de Omarchy fuera de ~/.bashrc (copia en $BK/bashrc.antes)"
fi

# Carpetas y archivos de Omarchy → al respaldo, no a la papelera.
# (-L también: ~/.local/share/omarchy era un enlace a /usr/share/omarchy, roto tras el paso 4.)
mover() {
  [[ -e "$1" || -L "$1" ]] || return 0
  mkdir -p "$BK/$(dirname "${1#"$HOME"/}")"
  mv "$1" "$BK/${1#"$HOME"/}"
  echo "  apartado: $1"
}
mover "$HOME/.config/omarchy"
mover "$HOME/.local/state/omarchy"
mover "$HOME/.local/share/omarchy"
mover "$HOME/.local/share/omarchy.bak"
mover "$HOME/.config/Omacom"
mover "$HOME/.local/share/Omacom"
mover "$HOME/.cache/omarchy"
mover "$HOME/.cache/Omacom"
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
# Respaldos que dejó la actualización Omarchy 3 → 4 (*.omarchy-upgrade-to-quattro.*.bak).
mapfile -t VIEJOS < <(find "$HOME/.config" "$HOME/.local/share" -maxdepth 3 \
  -name '*.omarchy-upgrade-to-*.bak' -not -path "$HOME/.local/share/nanuk-migracion/*" 2>/dev/null)
for f in "${VIEJOS[@]}"; do mover "$f"; done
# Integraciones de navegador de Omarchy (llaman a scripts que ya no existen).
for f in "$HOME"/.config/*/NativeMessagingHosts/com.omarchy.*.json; do mover "$f"; done
# Skills de agentes (Claude, Codex...) enlazadas a /usr/share/omarchy: enlaces rotos.
mapfile -t ROTOS < <(find "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.hermes/skills" \
  "$HOME/.pi/agent/skills" -maxdepth 1 -xtype l -lname '/usr/share/omarchy/*' 2>/dev/null)
for f in "${ROTOS[@]}"; do mover "$f"; done
# Config tuya que carga archivos de Omarchy: extensiones de Chromium/Brave en
# /usr/share/omarchy y temas en ~/.local/state/omarchy (ya no existen). Se quitan
# solo esas entradas; si --load-extension tenía otras tuyas, se conservan.
for f in "$HOME"/.config/*-flags.conf "$HOME"/.config/foot/foot.ini "$HOME"/.config/ghostty/config \
         "$HOME"/.config/hyprland-preview-share-picker/config.yaml; do
  grep -qE '/usr/share/omarchy/|\.local/state/omarchy/' "$f" 2>/dev/null || continue
  mkdir -p "$BK/config-antes"; cp "$f" "$BK/config-antes/$(basename "$(dirname "$f")")-$(basename "$f")"
  awk '
    /^--load-extension=/ {
      n = split(substr($0, 18), ext, ","); keep = ""
      for (i = 1; i <= n; i++) if (ext[i] !~ /^\/usr\/share\/omarchy\//) keep = keep (keep == "" ? "" : ",") ext[i]
      if (keep != "") print "--load-extension=" keep
      next
    }
    /\.local\/state\/omarchy\// { next }
    { print }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  echo "  sin rutas de Omarchy: $f"
done
[[ -d /etc/sddm.conf.d ]] && { sudo mv /etc/sddm.conf.d "$BK/etc-sddm.conf.d"; echo "  apartado: /etc/sddm.conf.d"; }
sudo chown -R "$USER" "$BK"
systemctl --user daemon-reload || true
sudo systemctl daemon-reload

# ── 10. Verificación: ¿queda algo que se llame Omarchy? ────────────
echo
echo "→ buscando restos de Omarchy..."
RESTOS="$(
  {
    pacman -Qq | grep -i omarchy || true
    sudo grep -rIli omarchy /etc /boot/limine.conf 2>/dev/null || true
    find /etc /usr/share /boot -iname '*omarchy*' 2>/dev/null || true
    find "$HOME/.config" "$HOME/.local" "$HOME/.cache" -maxdepth 3 -iname '*omarchy*' \
      -not -path "$HOME/.local/share/nanuk/*" -not -path "$HOME/.local/share/nanuk-migracion*" 2>/dev/null || true
    find "$HOME" -maxdepth 4 -xtype l -lname '*omarchy*' 2>/dev/null || true
  } | sort -u
)"
if [[ -z "$RESTOS" ]]; then
  echo "✔ no queda nada de Omarchy"
else
  echo "Aún aparece 'omarchy' aquí (no se tocan: pueden ser tuyos, p. ej. un tema o una nota):"
  sed 's/^/    /' <<<"$RESTOS"
fi

echo
echo "✔ Omarchy purgado. Restos guardados en $BK (bórralo cuando quieras)."
echo "  Paquetes que venían del repo de Omarchy y siguen instalados (typora, code, localsend,"
echo "  yay, limine-mkinitcpio-hook...): ya no reciben updates de ahí; están con el mismo"
echo "  nombre en el AUR → yay -S <paquete> los vuelve a enganchar."
(( CAMBIO_ESPEJO )) && echo "  Espejos cambiados: corre ahora 'nanuk update' (el de Omarchy iba con retraso)."
echo "  Reinicia para comprobar el arranque."
