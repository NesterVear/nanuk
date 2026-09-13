#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Nanuk — orquestador de instalación
#
# No contiene lógica propia: solo ejecuta cada paso de install/ en orden.
# Cada paso es un script independiente que también puedes correr solo:
#   bash install/02-pacman.sh
# Eso hace que depurar sea trivial: si algo falla, repites SOLO ese paso.
#
# En pantalla solo se ve el progreso, una línea por paso. Todo lo que
# escriben pacman, yay y los propios pasos va al log:
#   ~/.local/state/nanuk/install.log        (otra ruta: NANUK_LOG=...)
# Si un paso falla se muestran sus últimas líneas. Para verlo todo en vivo:
#   NANUK_VERBOSE=1 bash install/install.sh
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

# Directorio donde vive este script, sin importar desde dónde lo llames.
# (Truco estándar de bash: la ruta del script está en BASH_SOURCE[0].)
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# NANUK_ROOT = raíz del repo. Los pasos lo usan para encontrar packages/,
# config/, themes/... Se exporta para que los hijos lo hereden.
export NANUK_ROOT="$(dirname "$INSTALL_DIR")"

# "script|lo que se ve en pantalla"
STEPS=(
  "01-preflight.sh|Comprobaciones"
  "02-pacman.sh|pacman y AUR (yay)"
  "03-packages.sh|Paquetes (el más largo)"
  "04-services.sh|Servicios"
  "05-desktop.sh|Escritorio y arranque"
  "06-dotfiles.sh|Configuración y tema"
  "07-dev.sh|Entorno de desarrollo"
)

LOG="${NANUK_LOG:-$HOME/.local/state/nanuk/install.log}"
mkdir -p "$(dirname "$LOG")"
touch "$LOG"
# Primera línea de ESTA ejecución (el log se acumula entre intentos).
LOG_START=$(( $(wc -l < "$LOG") + 1 ))
VERBOSE="${NANUK_VERBOSE:-0}"

echo "Nanuk · instalando"
echo "  detalle: $LOG"
echo

# Pedimos sudo una vez al principio y lo mantenemos vivo en segundo plano:
# la caché de sudo caduca a los 15 min y el paso 03 tarda más que eso.
# `sudo -n true` primero: si sudo ya funciona sin contraseña (instalación
# desde la ISO, con regla NOPASSWD temporal) no hay nada que pedir. `sudo -v`
# solo no basta ahí: con verifypw=all (por defecto) exige contraseña si
# CUALQUIER regla del usuario la pide, y la de %wheel la pide.
sudo -n true 2>/dev/null || sudo -v
( while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 60; done ) &

elapsed() { local s=$(( SECONDS - $1 )); printf '%d:%02d' $(( s / 60 )) $(( s % 60 )); }

# run_step <n> <script> <nombre>
# El paso corre en segundo plano con la salida al log; mientras, una sola
# línea que gira con el tiempo que lleva. Símbolos ASCII para el giro: la
# consola de la ISO (tty, sin fuente gráfica) no pinta braille.
run_step() {
  local n="$1" script="$2" name="$3" total="${#STEPS[@]}"
  local label="$n/$total  $name" start=$SECONDS rc=0
  printf '\n━━━ %s · %s · %s ━━━\n' "$script" "$name" "$(date '+%F %T')" >> "$LOG"

  if [[ "$VERBOSE" == 1 ]]; then
    echo "━━━ ▶ $label ━━━"
    bash "$INSTALL_DIR/$script" 2>&1 | tee -a "$LOG" || rc=$?
  else
    bash "$INSTALL_DIR/$script" >> "$LOG" 2>&1 < /dev/null &
    local pid=$! i=0 frames=('-' '\' '|' '/')
    if [[ -t 1 ]]; then
      while kill -0 "$pid" 2>/dev/null; do
        printf '\r  %s %s  %s ' "${frames[i++ % 4]}" "$label" "$(elapsed "$start")"
        sleep 0.25
      done
      printf '\r\033[K'
    else
      echo "  ▶ $label"
    fi
    wait "$pid" || rc=$?
  fi

  if (( rc == 0 )); then
    printf '  ✔ %s  %s\n' "$label" "$(elapsed "$start")"
  else
    printf '  ✖ %s  (falló tras %s)\n\n' "$label" "$(elapsed "$start")"
    echo "  Últimas líneas del log ($LOG):"
    tail -n 25 "$LOG" | sed 's/^/    /'
  fi
  return "$rc"
}

n=0
for entry in "${STEPS[@]}"; do
  n=$(( n + 1 ))
  run_step "$n" "${entry%%|*}" "${entry#*|}"
done

# Avisos no críticos de esta ejecución (AUR, flatpak…): en el log, pero que se vean.
warnings="$(tail -n +"$LOG_START" "$LOG" | grep '⚠' || true)"
if [[ -n "$warnings" ]]; then
  echo
  echo "  Avisos (no críticos, detalle en el log):"
  sed 's/^[[:space:]]*/    /' <<< "$warnings" | head -n 15
fi

# Versión de las listas de paquetes con la que se instaló: `nanuk update`
# instala después solo lo que Nanuk añada desde aquí.
if git -C "$NANUK_ROOT" rev-parse HEAD &>/dev/null; then
  mkdir -p "$HOME/.local/state/nanuk"
  git -C "$NANUK_ROOT" rev-parse HEAD > "$HOME/.local/state/nanuk/packages-commit"
fi

echo
echo "✔ Nanuk instalado. Reinicia para entrar a tu sistema."
