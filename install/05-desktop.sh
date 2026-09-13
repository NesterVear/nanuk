#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 05 — Escritorio a nivel de sistema.
#
# Todo lo que necesita root o toca /etc y /boot:
#   1. Tema Plymouth "nanuk" (splash de arranque) + hook de mkinitcpio
#      + parámetros del kernel `quiet splash`.
#   2. Autologin en tty1 → Hyprland vía uwsm (sin display manager).
#   3. Apps por defecto (navegador, carpetas).
#
# La configuración de usuario (hyprland, waybar, ...) va en 06-dotfiles.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

NANUK_ROOT="${NANUK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# ── 1. Plymouth ─────────────────────────────────────────────────────
THEME_SRC="$NANUK_ROOT/themes/nanuk/plymouth"
THEME_DST="/usr/share/plymouth/themes/nanuk"

echo "→ Instalando tema Plymouth en $THEME_DST"
# rsync --delete: espejo exacto del tema del repo. Así, si un asset desaparece
# del tema (como pasó con el Pac-Man), también desaparece del sistema.
sudo rsync -a --delete --chmod=D755,F644 "$THEME_SRC/" "$THEME_DST/"

# El hook `plymouth` debe ir justo después de `udev` (o de `systemd` si el
# initramfs usa ese hook) y ANTES de `encrypt`/`sd-encrypt`, para que el
# diálogo de contraseña LUKS se dibuje sobre el splash.
MKINIT=/etc/mkinitcpio.conf
if grep -qE '^HOOKS=.*\bplymouth\b' "$MKINIT"; then
  echo "✔ hook plymouth ya presente en $MKINIT"
elif grep -qE '^HOOKS=.*\bsystemd\b' "$MKINIT"; then
  sudo sed -i -E 's/^(HOOKS=\([^)]*\bsystemd\b)/\1 plymouth/' "$MKINIT"
  echo "✔ hook plymouth añadido tras systemd"
else
  sudo sed -i -E 's/^(HOOKS=\([^)]*\budev\b)/\1 plymouth/' "$MKINIT"
  echo "✔ hook plymouth añadido tras udev"
fi

# add_kernel_params PARAM...: añade parámetros al kernel donde corresponda
# según el bootloader. Solo añade los que faltan (idempotente).
add_kernel_params() {
  local p
  if [[ -f /etc/kernel/cmdline ]]; then
    # UKI (Unified Kernel Image): la línea de comandos vive en este archivo.
    for p in "$@"; do
      grep -qw "$p" /etc/kernel/cmdline || sudo sed -i "s/\$/ $p/" /etc/kernel/cmdline
    done
    echo "✔ kernel params en /etc/kernel/cmdline"
  elif [[ -f /etc/default/limine ]]; then
    # Limine con limine-mkinitcpio-hook (lo que usan Omarchy y archinstall):
    # la línea del kernel se declara en este archivo y `limine-update`
    # regenera /boot/limine.conf con ella en cada actualización del kernel.
    # Editar limine.conf a mano se perdería en el siguiente kernel.
    for p in "$@"; do
      grep -qE "^KERNEL_CMDLINE\[default\].*\b$p\b" /etc/default/limine \
        || echo "KERNEL_CMDLINE[default]+=\" $p\"" | sudo tee -a /etc/default/limine >/dev/null
    done
    command -v limine-update &>/dev/null && sudo limine-update
    echo "✔ kernel params en /etc/default/limine"
  elif compgen -G "/boot/loader/entries/*.conf" >/dev/null; then
    # systemd-boot: cada entrada tiene su línea `options`.
    local f
    for f in /boot/loader/entries/*.conf; do
      for p in "$@"; do
        grep -qE "^options.*\b$p\b" "$f" || sudo sed -i -E "s/^(options.*)\$/\1 $p/" "$f"
      done
    done
    echo "✔ kernel params en /boot/loader/entries/*.conf"
  elif [[ -f /etc/default/grub ]]; then
    for p in "$@"; do
      grep -qE "^GRUB_CMDLINE_LINUX_DEFAULT=.*\b$p\b" /etc/default/grub \
        || sudo sed -i -E "s/^(GRUB_CMDLINE_LINUX_DEFAULT=\")/\1$p /" /etc/default/grub
    done
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    echo "✔ kernel params en GRUB"
  elif compgen -G "/boot/limine.conf" >/dev/null || compgen -G "/boot/EFI/limine/limine.conf" >/dev/null; then
    # Limine sin el hook: se añade a cada línea `cmdline:` que no lo tenga.
    local f
    for f in /boot/limine.conf /boot/EFI/limine/limine.conf; do
      [[ -f "$f" ]] || continue
      for p in "$@"; do
        sudo sed -i -E "/^[[:space:]]*cmdline:/{/\b$p\b/!s/\$/ $p/}" "$f"
      done
    done
    echo "✔ kernel params en limine.conf"
  else
    echo "⚠ bootloader no reconocido: añade a mano 'quiet splash' a la línea del kernel"
  fi
}
# plymouth.ignore-serial-consoles: el stub de systemd de la UKI añade
# `console=uart,...` cuando el firmware tiene consola serie (VMs con OVMF), y
# con una consola serie Plymouth pide la contraseña LUKS en texto en vez de
# dibujar el splash. Con este parámetro la ignora. En hardware sin serie no
# cambia nada.
add_kernel_params quiet splash plymouth.ignore-serial-consoles

# -R = además de fijar el tema, regenera el initramfs (mkinitcpio -P).
echo "→ plymouth-set-default-theme -R nanuk (regenera initramfs, tarda un poco)"
sudo plymouth-set-default-theme -R nanuk

# ── 2. Autologin tty1 → uwsm → Hyprland ─────────────────────────────
# Si cifraste el disco (LUKS) ya tecleas la contraseña en el arranque; si no,
# no hay contraseña y se entra directo. En ambos casos hyprlock bloquea la
# sesión, así que un display manager solo sería una pantalla de más. agetty
# inicia sesión sola en tty1 y ~/.bash_profile lanza Hyprland en esa tty.
# Si la máquina venía con un display manager (Omarchy 4 usa sddm), lo
# desactivamos: si no, sddm y el autologin de tty1 abrirían DOS sesiones.
# Solo `disable` (no `stop`): si estás dentro de esa sesión, pararlo te
# echaría. Hace efecto al reiniciar.
for dm in sddm gdm lightdm ly greetd lemurs; do
  if systemctl is-enabled "$dm" &>/dev/null; then
    sudo systemctl disable "$dm"
    echo "✔ $dm desactivado (Nanuk entra por autologin en tty1)"
  fi
done

GETTY_DIR=/etc/systemd/system/getty@tty1.service.d
sudo install -d "$GETTY_DIR"
sudo tee "$GETTY_DIR/autologin.conf" >/dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF
# En un chroot (ISO) no hay systemd al que recargar; el drop-in se lee al arrancar.
sudo systemctl daemon-reload 2>/dev/null || true
echo "✔ autologin de $USER en tty1"

# Bloque en ~/.bash_profile delimitado por marcadores, para poder
# reconocerlo y no duplicarlo en la siguiente ejecución.
PROFILE="$HOME/.bash_profile"
if [[ ! -f "$PROFILE" ]]; then
  # Si creamos el archivo, que siga cargando ~/.bashrc como haría bash.
  printf '[[ -f ~/.bashrc ]] && . ~/.bashrc\n' > "$PROFILE"
fi
if ! grep -q '>>> nanuk' "$PROFILE"; then
  cat >> "$PROFILE" <<'EOF'

# >>> nanuk: iniciar Hyprland al entrar en tty1 >>>
# `uwsm check may-start` solo es cierto en un login shell de una tty virtual
# sin sesión gráfica ya corriendo, así que esto no molesta por ssh ni en
# terminales dentro de Hyprland.
if uwsm check may-start; then
  exec uwsm start -- hyprland.desktop
fi
# <<< nanuk <<<
EOF
  echo "✔ arranque de Hyprland añadido a $PROFILE"
fi

# ── 2b. Keyring sin preguntas repetidas ────────────────────────────
# gnome-keyring guarda contraseñas de Brave, VS Code, etc. Dos casos, según
# haya hyprlock al entrar (n.lock_on_start = "auto", ver config/hypr/helpers.lua):
#
#  · / sin cifrar: autologin + hyprlock al momento. pam_gnome_keyring en
#    /etc/pam.d/login: `auth` abre el keyring "login" con la contraseña que
#    tecleas en hyprlock (/etc/pam.d/hyprlock hace `auth include login`) y
#    `session ... auto_start` arranca el demonio. Una contraseña para todo.
#
#  · / cifrado (LUKS): la contraseña del disco ya es el inicio de sesión, y el
#    autologin (`login -f`) no pasa por `auth`: PAM nunca tiene una contraseña
#    que darle al keyring. Igual que Omarchy: keyring por defecto SIN
#    contraseña propia (lo protege el cifrado) y SIN pam_gnome_keyring. Si se
#    quedara, el primer hyprlock (al suspender, por inactividad) crearía un
#    keyring "login" con tu contraseña; en el siguiente arranque ese keyring
#    está cerrado y libsecret, que busca en TODOS los keyrings, lo pide en
#    cuanto una app consulta un secreto.
PAM_LOGIN=/etc/pam.d/login
KEYRINGS="$HOME/.local/share/keyrings"

# Nº de secretos de un .keyring cifrado, leyendo solo la cabecera (que va en
# claro): "GnomeKeyring\n\r\0\n" (16) + versión/cifrado/hash (4) + nombre
# (u32 largo + bytes) + ctime/mtime (16) + flags/lock_timeout/iteraciones (12)
# + sal (8) + reservado (16) → num_items, u32 big-endian. -1 si no es de ese tipo.
keyring_items() {
  local len
  [[ "$(head -c 12 "$1")" == GnomeKeyring ]] || { echo -1; return; }
  len=$(od -An -tu4 --endian=big -j 20 -N 4 "$1" | tr -d ' ')
  od -An -tu4 --endian=big -j $((76 + len)) -N 4 "$1" | tr -d ' '
}

if lsblk -snlo FSTYPE "$(findmnt -nvo SOURCE /)" 2>/dev/null | grep -qx crypto_LUKS; then
  if grep -q pam_gnome_keyring "$PAM_LOGIN"; then
    sudo sed -i '/pam_gnome_keyring/d' "$PAM_LOGIN"
    echo "✔ pam_gnome_keyring quitado de $PAM_LOGIN (disco cifrado)"
  fi

  # Keyring por defecto sin contraseña, solo si no hay ya uno por defecto.
  install -d -m 700 "$KEYRINGS"
  if [[ ! -f "$KEYRINGS/default" ]]; then
    if [[ ! -f "$KEYRINGS/Default_keyring.keyring" ]]; then
      printf '[keyring]\ndisplay-name=Default keyring\nctime=0\nmtime=0\nlock-on-idle=false\nlock-after=false\n' \
        > "$KEYRINGS/Default_keyring.keyring"
      chmod 600 "$KEYRINGS/Default_keyring.keyring"
    fi
    echo Default_keyring > "$KEYRINGS/default"
    echo "✔ keyring sin contraseña propia (disco cifrado)"
  fi

  # Un "login" VACÍO que dejó un hyprlock anterior solo sirve para pedir
  # contraseña: se aparta (.bak). Si guarda secretos no se toca, solo se avisa.
  if [[ -f "$KEYRINGS/login.keyring" ]]; then
    items=$(keyring_items "$KEYRINGS/login.keyring")
    if [[ "$items" == 0 ]]; then
      mv "$KEYRINGS/login.keyring" "$KEYRINGS/login.keyring.bak"
      echo "✔ keyring \"login\" vacío apartado (login.keyring.bak): cierra sesión para que deje de preguntar"
    elif [[ "$items" != -1 ]]; then
      echo "⚠ tu keyring \"login\" tiene contraseña y $items secreto(s): se pedirá al abrirlo."
      echo "  Para no verlo más: seahorse → Inicio de sesión → Cambiar contraseña → dejarla vacía."
    fi
  fi
else
  if ! grep -q pam_gnome_keyring "$PAM_LOGIN"; then
    sudo sed -i '/^auth.*system-local-login/a auth       optional     pam_gnome_keyring.so' "$PAM_LOGIN"
    echo 'session    optional     pam_gnome_keyring.so auto_start' | sudo tee -a "$PAM_LOGIN" >/dev/null
    echo "✔ pam_gnome_keyring en $PAM_LOGIN"
  fi
fi

if [[ ! -f /etc/pam.d/hyprlock ]]; then
  printf 'auth include login\naccount include login\n' | sudo tee /etc/pam.d/hyprlock >/dev/null
  echo "✔ /etc/pam.d/hyprlock creado"
fi

# ── 3. Apps por defecto ─────────────────────────────────────────────
# xdg-settings/xdg-mime escriben en ~/.config/mimeapps.list. El primero que
# exista gana; el usuario lo cambia luego con `xdg-settings set ...`.
for d in firefox.desktop brave-origin.desktop brave-browser.desktop chromium.desktop; do
  if [[ -f "/usr/share/applications/$d" \
     || -f "$HOME/.local/share/flatpak/exports/share/applications/$d" ]]; then
    xdg-settings set default-web-browser "$d" && break || true
  fi
done
xdg-mime default org.gnome.Nautilus.desktop inode/directory || true

# (La apariencia GTK vía gsettings se aplica en 06-dotfiles.sh, para que
# `nanuk update` la reaplique.)

echo "✔ Escritorio (sistema) configurado"
