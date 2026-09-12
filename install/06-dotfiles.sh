#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 06 — Dotfiles en capas. El corazón del proyecto.
#
#   ~/.config/nanuk/default/  ← config/ del repo. SE REEMPLAZA en cada update.
#   ~/.config/nanuk/user/     ← skel/ del repo, SOLO los archivos que falten.
#                               Jamás se sobreescribe nada que ya exista.
#   ~/.config/nanuk/themes/   ← themes/ del repo.
#   ~/.config/nanuk/theme     → symlink al tema activo (se crea si no existe).
#
# Después, cada app se conecta a esas capas:
#   - Hyprland: ~/.config/hypr/hyprland.lua carga default → theme → user.
#   - Apps sin include (waybar, kitty, mako, wofi, gtk): symlink a
#     user/<app> si existe, si no a default/<app>. Para personalizar una app
#     entera: cp -r default/waybar user/waybar, edita, y re-ejecuta este paso.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

NANUK_ROOT="${NANUK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
NANUK_CFG="$HOME/.config/nanuk"

# ── 1. Capa default: espejo exacto de config/ ───────────────────────
# rsync --delete borra en destino lo que ya no existe en el repo: así los
# defaults nunca acumulan basura de versiones viejas.
mkdir -p "$NANUK_CFG"
rsync -a --delete "$NANUK_ROOT/config/" "$NANUK_CFG/default/"
rsync -a --delete "$NANUK_ROOT/themes/" "$NANUK_CFG/themes/"
# Los scripts que las apps ejecutan (waybar/weather.sh...) deben ser ejecutables
# aunque el repo se haya clonado/copiado perdiendo el bit +x.
find "$NANUK_CFG/default" "$NANUK_CFG/themes" -name '*.sh' -exec chmod +x {} +
echo "✔ default/ y themes/ actualizados"

# ── 2. Capa user: solo lo que falte ────────────────────────────────
# Recorremos skel/ archivo por archivo. cp -n (no-clobber) es la clave:
# si el archivo ya existe, no lo toca. Así un update puede traer plantillas
# nuevas sin pisar las que ya personalizaste.
while IFS= read -r -d '' src; do
  rel="${src#"$NANUK_ROOT/skel/"}"
  dst="$NANUK_CFG/user/$rel"
  mkdir -p "$(dirname "$dst")"
  cp -n "$src" "$dst"
done < <(find "$NANUK_ROOT/skel" -type f -print0)
echo "✔ user/ completado (sin tocar lo existente)"

# ── 3. Tema activo ─────────────────────────────────────────────────
# Solo se crea el enlace si no existe: si ya elegiste otro tema, se respeta.
if [[ ! -e "$NANUK_CFG/theme" ]]; then
  ln -s "themes/nanuk" "$NANUK_CFG/theme"
  echo "✔ tema activo: nanuk"
fi

# ── 4. Enlaces por app (precedencia user > default) ────────────────
# link_layered <destino> <ruta-relativa>
#   Enlaza <destino> a user/<ruta> si existe, si no a default/<ruta>.
#   Si en el destino hay un archivo/carpeta real (no enlace), lo respalda.
link_layered() {
  local target="$1" rel="$2"
  local src="$NANUK_CFG/default/$rel"
  [[ -e "$NANUK_CFG/user/$rel" ]] && src="$NANUK_CFG/user/$rel"

  if [[ -e "$target" && ! -L "$target" ]]; then
    mv "$target" "$target.bak.$(date +%s)"
    echo "  respaldado: $target → $target.bak.*"
  fi
  mkdir -p "$(dirname "$target")"
  # -s symlink, -f reemplaza, -n no entra en el directorio si el destino
  # ya es un enlace a directorio (sin -n, crearía el enlace DENTRO).
  ln -sfn "$src" "$target"
}

link_layered "$HOME/.config/waybar"              waybar
link_layered "$HOME/.config/kitty"               kitty
link_layered "$HOME/.config/mako"                mako
link_layered "$HOME/.config/wofi"                wofi
link_layered "$HOME/.config/hypr/hyprlock.conf"  hypr/hyprlock.conf
link_layered "$HOME/.config/hypr/hypridle.conf"  hypr/hypridle.conf
link_layered "$HOME/.config/gtk-3.0/settings.ini" gtk-3.0/settings.ini
link_layered "$HOME/.config/gtk-3.0/gtk.css"      gtk-3.0/gtk.css
link_layered "$HOME/.config/gtk-4.0/settings.ini" gtk-4.0/settings.ini
link_layered "$HOME/.config/gtk-4.0/gtk.css"      gtk-4.0/gtk.css
link_layered "$HOME/.config/starship.toml"        starship.toml
link_layered "$HOME/.config/lazygit/config.yml"    lazygit/config.yml
link_layered "$HOME/.config/lazydocker/config.yml" lazydocker/config.yml
link_layered "$HOME/.config/fastfetch"             fastfetch
# btop reescribe btop.conf al salir: por eso el .conf se COPIA (solo si falta)
# y únicamente el tema se enlaza.
mkdir -p "$HOME/.config/btop/themes"
link_layered "$HOME/.config/btop/themes/nanuk.theme" btop/nanuk.theme
cp -n "$NANUK_CFG/default/btop/btop.conf" "$HOME/.config/btop/btop.conf"
echo "✔ enlaces de apps creados"

# ── 5. Hyprland: archivo de entrada ────────────────────────────────
# Este archivo es nuestro (lo dice su primera línea). Si encontramos otro
# que no lo es —una config previa del usuario— lo respaldamos antes.
HYPR_ENTRY="$HOME/.config/hypr/hyprland.lua"
mkdir -p "$HOME/.config/hypr"
if [[ -f "$HYPR_ENTRY" ]] && ! head -1 "$HYPR_ENTRY" | grep -q 'Nanuk'; then
  mv "$HYPR_ENTRY" "$HYPR_ENTRY.bak.$(date +%s)"
  echo "  respaldado: $HYPR_ENTRY"
fi
install -m 644 "$NANUK_ROOT/config/hypr/hyprland.lua" "$HYPR_ENTRY"
# .luarc.json: para que el editor (nvim/VSCode con lua-ls) autocomplete hl.* y n.*
install -m 644 "$NANUK_ROOT/config/hypr/.luarc.json" "$HOME/.config/hypr/.luarc.json"
install -m 644 "$NANUK_ROOT/config/hypr/.luarc.json" "$NANUK_CFG/.luarc.json"
echo "✔ ~/.config/hypr/hyprland.lua desplegado"

# ── 6. Scripts en ~/.local/bin ─────────────────────────────────────
mkdir -p "$HOME/.local/bin"
for script in "$NANUK_ROOT"/bin/nanuk "$NANUK_ROOT"/bin/nanuk-*; do
  [[ -f "$script" ]] || continue
  chmod +x "$script"
  ln -sfn "$script" "$HOME/.local/bin/$(basename "$script")"
done
echo "✔ scripts enlazados en ~/.local/bin (nanuk, nanuk-*)"

# ── 6b. Apps web → ~/.local/share/applications (para el launcher) ───
# default/webapps/*.desktop y user/webapps/*.desktop se enlazan como
# nanuk-webapp-<nombre>.desktop. Si user/ tiene el mismo nombre, gana.
# Primero se limpian los enlaces nuestros rotos (una app web que ya no existe).
APPS_DIR="$HOME/.local/share/applications"
mkdir -p "$APPS_DIR"
find "$APPS_DIR" -maxdepth 1 -name 'nanuk-webapp-*.desktop' -xtype l -delete
for layer in default user; do
  for entry in "$NANUK_CFG/$layer"/webapps/*.desktop; do
    [[ -f "$entry" ]] || continue
    ln -sfn "$entry" "$APPS_DIR/nanuk-webapp-$(basename "$entry")"
  done
done
command -v update-desktop-database &>/dev/null && update-desktop-database "$APPS_DIR" 2>/dev/null || true
echo "✔ apps web enlazadas en $APPS_DIR"

# ── 7. Bash: bloque con marcadores en ~/.bashrc ────────────────────
BASHRC="$HOME/.bashrc"
touch "$BASHRC"
if ! grep -q '>>> nanuk' "$BASHRC"; then
  cat >> "$BASHRC" <<'EOF'

# >>> nanuk >>>
# Defaults de Nanuk (no editar; se actualizan solos) y después tu capa.
source ~/.config/nanuk/default/bash/rc
[[ -f ~/.config/nanuk/user/bash/rc ]] && source ~/.config/nanuk/user/bash/rc
# <<< nanuk <<<
EOF
  echo "✔ bloque nanuk añadido a ~/.bashrc"
fi

echo "✔ Dotfiles desplegados. Tu capa: $NANUK_CFG/user/"
