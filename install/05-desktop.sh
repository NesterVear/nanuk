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
sudo install -d "$THEME_DST"
sudo install -m 644 "$THEME_SRC"/* "$THEME_DST"/

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
  else
    echo "⚠ bootloader no reconocido: añade a mano 'quiet splash' a la línea del kernel"
  fi
}
add_kernel_params quiet splash

# -R = además de fijar el tema, regenera el initramfs (mkinitcpio -P).
echo "→ plymouth-set-default-theme -R nanuk (regenera initramfs, tarda un poco)"
sudo plymouth-set-default-theme -R nanuk

# ── 2. Autologin tty1 → uwsm → Hyprland ─────────────────────────────
# El disco ya pide contraseña (LUKS) y hyprlock bloquea la sesión, así que
# un greeter solo añadiría una pantalla más. agetty inicia sesión sola en
# tty1 y ~/.bash_profile arranca Hyprland si estamos en esa tty.
GETTY_DIR=/etc/systemd/system/getty@tty1.service.d
sudo install -d "$GETTY_DIR"
sudo tee "$GETTY_DIR/autologin.conf" >/dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF
sudo systemctl daemon-reload
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

# ── 3. Apps por defecto ─────────────────────────────────────────────
# xdg-settings/xdg-mime escriben en ~/.config/mimeapps.list.
if [[ -f /usr/share/applications/brave-browser.desktop ]]; then
  xdg-settings set default-web-browser brave-browser.desktop || true
fi
xdg-mime default org.gnome.Nautilus.desktop inode/directory || true

echo "✔ Escritorio (sistema) configurado"
