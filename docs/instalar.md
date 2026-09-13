# Instalar Nanuk

Dos caminos. Los dos terminan igual: Nanuk en su versión **estable** (la última
probada), aunque la ISO que descargaste sea de hace meses.

- [Desde la ISO](#desde-la-iso): no hace falta instalar Arch antes.
- [Sobre un Arch ya instalado](#sobre-un-arch-ya-instalado): si ya tienes Arch
  limpio, sin escritorio.

Antes de empezar, revisa los [requisitos](../README.md#requisitos): sobre todo
**UEFI** y unos 20 GB libres para `/`.

## Desde la ISO

### 1. Descargar y grabar

Descarga `nanuk-AAAA.MM.DD-x86_64.iso` y su `.sha256` de
[Releases](https://github.com/nestervear/nanuk/releases/latest) y comprueba que
bajó bien:

```bash
sha256sum -c nanuk-*.iso.sha256
```

Grábala en una USB (se borra entera). En Linux, con `lsblk` para ver qué
dispositivo es la USB:

```bash
sudo dd if=nanuk-AAAA.MM.DD-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

`/dev/sdX` es la USB **entera** (no `sdX1`). Desde Windows o macOS sirve
balenaEtcher, o Rufus en modo DD.

### 2. Arrancar en UEFI

La ISO solo arranca en UEFI. En la configuración del firmware: modo de arranque
UEFI, CSM/Legacy desactivado y **Secure Boot desactivado** (la ISO no está
firmada). En el menú de arranque elige la entrada `UEFI: <tu USB>`. Si sale
"No bootable device", el equipo está arrancando en modo BIOS/Legacy.

En una máquina virtual (virt-manager, QEMU): firmware **UEFI (OVMF)** al crearla;
no se puede cambiar después.

### 3. Responder las preguntas

El instalador arranca solo y pregunta, en este orden:

1. **Red**: por cable funciona sin hacer nada; para Wi-Fi te guía con `iwctl`.
2. **Teclado, idioma y zona horaria** (sugerida según tu conexión).
3. **Kernel**: `linux` (recomendado, el más reciente), `linux-lts` (más
   conservador) o `linux-hardened`.
4. **Nombre del equipo, usuario y contraseña** (la misma queda para root).
5. **Disco**, dos modos:
   - *Por defecto*: usa un disco entero y **lo borra**. Para confirmar tienes
     que escribir su nombre.
   - *Personalizado*: particionas a mano con `cfdisk` y eliges qué partición va
     a cada sitio (EFI, `/`, `/home`, swap). Un `/home` que ya tengas se puede
     **conservar sin formatear**, también si está cifrado.
   - En los dos: cifrado opcional de `/` y sistema de archivos ext4 o btrfs.

### 4. Esperar

En pantalla solo verás el progreso; el detalle queda en
`/var/log/nanuk-install.log`. Al terminar reinicia solo a los 10 segundos (una
tecla lo cancela) y arranca desde el disco aunque la USB siga puesta.

Si falla algo de la última parte (sin red, un paquete del AUR caído…), no tienes
que hacer nada: en el primer arranque la instalación continúa sola (si no hay
red, te abre `nmtui` para conectarte) y reinicia al acabar.

## Sobre un Arch ya instalado

Necesitas Arch **limpio** (sin escritorio), con un usuario normal (no root) que
tenga sudo, e internet.

Si nunca has instalado Arch: arranca la ISO oficial de
[archlinux.org](https://archlinux.org/download/), conéctate a internet (Wi-Fi con
`iwctl`: [wiki de Arch](https://wiki.archlinux.org/title/Iwd)) y ejecuta
`archinstall` eligiendo:

- Disco: "best-effort default layout" (ext4 o btrfs); cifrado opcional.
- Bootloader: **Limine**.
- Un usuario con sudo (superuser: sí).
- Perfil **Minimal**, sin servidor de audio.
- Red con **NetworkManager**.
- Tu zona horaria, con NTP.

Reinicia, entra con tu usuario en la consola de texto y ejecuta:

```bash
curl -fsSL https://raw.githubusercontent.com/nestervear/nanuk/main/boot.sh | bash
```

Instala la versión estable. Si prefieres lo último aunque no esté tan probado:
`curl -fsSL …/boot.sh | NANUK_CHANNEL=main bash`.

## Después de instalar

- `SUPER + K` enseña todos los atajos de teclado.
- `SUPER + SHIFT + I` (o `nanuk menu`) abre el menú: instalar y quitar programas,
  tema, fondo, actualizar.
- Todo lo que quieras cambiar va en `~/.config/nanuk/user/`:
  [personalizar.md](personalizar.md).
