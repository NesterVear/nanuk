#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 04 — Servicios del sistema.
#
# Activa (enable) y arranca (--now) los servicios que Nanuk espera tener
# siempre. `systemctl enable` es idempotente: si ya está activo, no hace nada.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Servicios base ──────────────────────────────────────────────────
SERVICES=(
  NetworkManager          # red (wifi/ethernet) — nmtui / nmcli
  bluetooth               # bluez
  sshd                    # acceso remoto
  docker                  # contenedores
  power-profiles-daemon   # perfiles de energía (balanced/performance/power-saver)
  fstrim.timer            # TRIM semanal para SSD
  systemd-timesyncd       # hora por NTP
)

# thermald solo tiene sentido en Intel.
if grep -q GenuineIntel /proc/cpuinfo; then
  SERVICES+=(thermald)
fi

for svc in "${SERVICES[@]}"; do
  echo "→ enable --now $svc"
  sudo systemctl enable --now "$svc"
done

# ── Docker: usuario al grupo ────────────────────────────────────────
# Sin esto, cada `docker` pediría sudo. Hace efecto en el siguiente login.
if id -nG "$USER" | grep -qw docker; then
  echo "✔ $USER ya está en el grupo docker"
else
  sudo usermod -aG docker "$USER"
  echo "✔ $USER añadido al grupo docker (cierra sesión para que aplique)"
fi

# ── MariaDB: inicializar datadir solo la primera vez ────────────────
if [[ ! -d /var/lib/mysql/mysql ]]; then
  echo "→ Inicializando MariaDB..."
  sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
fi
sudo systemctl enable --now mariadb

# ── zram: swap comprimida en RAM ───────────────────────────────────
# zram-generator crea /dev/zram0 al arrancar leyendo este archivo.
ZRAM_CONF=/etc/systemd/zram-generator.conf
if [[ ! -f "$ZRAM_CONF" ]]; then
  sudo tee "$ZRAM_CONF" >/dev/null <<'EOF'
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
EOF
  echo "✔ zram configurado ($ZRAM_CONF)"
fi

# ── Agente polkit (diálogos de contraseña en el escritorio) ────────
# Es una unidad de usuario que arranca con graphical-session.target,
# que uwsm levanta al iniciar Hyprland.
systemctl --user enable hyprpolkitagent.service 2>/dev/null \
  || echo "⚠ no se pudo activar hyprpolkitagent.service (se reintenta al iniciar sesión gráfica)"

echo "✔ Servicios configurados"
