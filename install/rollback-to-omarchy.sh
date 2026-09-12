#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Vuelta a Omarchy tras from-omarchy.sh (fase A). Deshace lo que Nanuk
# cambió en el ARRANQUE y la SESIÓN; deja los paquetes de Nanuk instalados
# (no molestan). Solo funciona mientras Omarchy siga instalado, es decir,
# antes de purge-omarchy.sh.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail
die() { echo "✖ $*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "con tu usuario normal, no root"
pacman -Q omarchy &>/dev/null || die "Omarchy ya no está instalado: no hay vuelta automática (reinstalar Omarchy desde su ISO)"

BK_BASE="$HOME/.local/share/nanuk-migracion"
BK="$(ls -d "$BK_BASE"/*/ 2>/dev/null | sort | tail -1 || true)"
[[ -n "$BK" ]] || die "no encuentro un respaldo en $BK_BASE (¿corriste from-omarchy.sh?)"
echo "→ usando el respaldo $BK"
sudo -v

# 1. Sesión: sddm otra vez, sin autologin de tty1.
sudo systemctl enable sddm
sudo rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf
sudo systemctl daemon-reload
echo "✔ sddm activado, autologin tty1 quitado"

# 2. ~/.bash_profile: fuera el bloque de Nanuk que lanza Hyprland.
sed -i '/^# >>> nanuk: iniciar Hyprland/,/^# <<< nanuk <<</d' "$HOME/.bash_profile"
echo "✔ bloque de Nanuk quitado de ~/.bash_profile"

# 3. Hyprland: restaurar el hyprland.lua de Omarchy (el .bak más reciente).
HYPR="$HOME/.config/hypr"
latest="$(ls -t "$HYPR"/hyprland.lua.bak.* 2>/dev/null | head -1 || true)"
if [[ -n "$latest" ]]; then
  mv "$HYPR/hyprland.lua" "$HYPR/hyprland.lua.nanuk"
  mv "$latest" "$HYPR/hyprland.lua"
  echo "✔ ~/.config/hypr/hyprland.lua de Omarchy restaurado (el de Nanuk queda como hyprland.lua.nanuk)"
else
  echo "⚠ no hay hyprland.lua.bak.*; sácalo de $BK/home-config.tar.gz"
fi

# 4. Servicios de usuario de Omarchy.
if [[ -f "$BK/omarchy-user-units.txt" ]]; then
  while read -r unit; do
    [[ -n "$unit" ]] && systemctl --user enable "$unit" &>/dev/null && echo "  activado: $unit"
  done < "$BK/omarchy-user-units.txt"
fi

# 5. Splash de Omarchy.
if [[ -d /usr/share/plymouth/themes/omarchy ]]; then
  sudo plymouth-set-default-theme -R omarchy
  echo "✔ splash de Omarchy"
fi

echo
echo "✔ Listo: reinicia y entrarás por sddm a Omarchy. Los enlaces de Nanuk en"
echo "  ~/.config (kitty, starship, waybar...) siguen ahí; tus originales están"
echo "  al lado con sufijo .bak.* y en $BK/home-config.tar.gz."
