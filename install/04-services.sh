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

# enable (que arranque en cada boot) es obligatorio; start (ahora mismo) no:
# en una VM thermald o bluetooth pueden negarse a arrancar por falta de
# hardware, y eso no debe abortar el instalador. Al reiniciar, systemd lo
# reintenta solo.
for svc in "${SERVICES[@]}"; do
  echo "→ enable $svc"
  sudo systemctl enable "$svc"
  sudo systemctl start "$svc" || echo "  ⚠ $svc no arrancó ahora (¿hardware ausente?); queda activado para el próximo boot"
done

# ── Docker: usuario al grupo ────────────────────────────────────────
# Sin esto, cada `docker` pediría sudo. Hace efecto en el siguiente login.
if id -nG "$USER" | grep -qw docker; then
  echo "✔ $USER ya está en el grupo docker"
else
  sudo usermod -aG docker "$USER"
  echo "✔ $USER añadido al grupo docker (cierra sesión para que aplique)"
fi

# ── Virtualización (libvirt + KVM) ────────────────────────────────
# libvirtd.socket = activación por socket: el demonio arranca solo cuando
# virt-manager o virsh se conectan por primera vez.
if pacman -Qq libvirt &>/dev/null; then
  echo "→ Configurando libvirt..."
  sudo systemctl enable --now libvirtd.socket

  # Grupos: 'libvirt' para gestionar VMs sin sudo; 'kvm' para /dev/kvm.
  for grp in libvirt kvm; do
    id -nG "$USER" | grep -qw "$grp" || sudo usermod -aG "$grp" "$USER"
  done

  # IP forwarding: el NAT de las VMs lo necesita y así sobrevive a reinicios.
  echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-nanuk-libvirt.conf >/dev/null
  sudo sysctl -q -p /etc/sysctl.d/99-nanuk-libvirt.conf || true

  # Red NAT por defecto (virbr0 + dnsmasq). libvirt crea sus propias reglas
  # de firewall (nftables) al arrancar la red: no hay que tocar nada más
  # mientras Nanuk no tenga un cortafuegos propio (ver packages/extras.txt).
  sudo virsh --connect qemu:///system net-autostart default &>/dev/null || true
  sudo virsh --connect qemu:///system net-start     default &>/dev/null \
    || echo "  (la red 'default' ya estaba activa)"

  echo "✔ libvirt listo (cierra sesión para entrar al grupo libvirt)"
fi

# ── MariaDB (solo si se instaló desde extras.txt) ───────────────────
# Por defecto Nanuk NO trae base de datos nativa: van en Docker, y así el
# puerto 3306 queda libre para los contenedores de tus proyectos.
if command -v mariadb-install-db &>/dev/null; then
if [[ ! -d /var/lib/mysql/mysql ]]; then
  echo "→ Inicializando MariaDB..."
  sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
fi
sudo systemctl enable --now mariadb
fi

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
