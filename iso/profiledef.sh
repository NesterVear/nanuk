#!/usr/bin/env bash
# shellcheck disable=SC2034
# ─────────────────────────────────────────────────────────────────────
# Perfil de archiso para la ISO de Nanuk. Derivado de `releng` (la ISO
# oficial de Arch) quitando lo que no usamos: arranque BIOS, PXE, cloud-init,
# agentes de VMware/VirtualBox/Hyper-V. Solo UEFI: es requisito de Nanuk.
#
# Construir:  bash iso/build.sh          (necesita `archiso` y root)
# ─────────────────────────────────────────────────────────────────────

iso_name="nanuk"
iso_label="NANUK_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Nanuk <https://github.com/nestervear/nanuk>"
iso_application="Nanuk — instalador"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="nanuk"
buildmodes=('iso')
bootmodes=('uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
# mkarchiso copia airootfs/ SIN conservar permisos: todo ejecutable va aquí.
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/usr/local/bin/nanuk-install"]="0:0:755"
)
