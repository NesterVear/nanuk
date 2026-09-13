# Nanuk 🐻‍❄️

> Un oso polar en la oscuridad absoluta.

Sistema basado en **Arch Linux** + **Hyprland**: minimalista, negro profundo,
un solo acento de color (hielo), pensado para **programar** e **imprimir en
3D**. Con una regla de oro: **las actualizaciones jamás tocan tu
configuración.**

Web: [nestervear.github.io/nanuk](https://nestervear.github.io/nanuk/)

## Requisitos

| | Mínimo | Recomendado |
|---|---|---|
| CPU | x86_64 | con VT-x / AMD-V si quieres usar las VMs (libvirt) |
| Firmware | **UEFI** (Limine arranca una imagen UKI) | |
| GPU | cualquiera con driver libre en Mesa (Intel, AMD) | NVIDIA: no probado, sin soporte específico |
| RAM | 4 GB (escritorio + navegador) | 8 GB; 16 GB con Docker, VMs y OrcaSlicer a la vez |
| Disco para `/` | 20 GB | 40 GB o más (imágenes de Docker y VMs crecen) |
| Red | internet durante la instalación | |

El sistema instalado ocupa unos 6–8 GB (paquetes con sus dependencias, más
OrcaSlicer por flatpak). `/home` puede ir en otro disco.

## Instalar

- **Desde la ISO**, sin instalar Arch antes: descarga la última de
  [Releases](https://github.com/nestervear/nanuk/releases/latest), grábala en una
  USB y arranca en UEFI. El instalador pregunta lo necesario (teclado, zona
  horaria, kernel, disco, usuario) y deja Nanuk listo.
- **Sobre un Arch ya instalado**, limpio, con un usuario con sudo e internet:

  ```bash
  curl -fsSL https://raw.githubusercontent.com/nestervear/nanuk/main/boot.sh | bash
  ```

Los dos caminos instalan la versión **estable** (la última probada). Paso a paso,
con ayuda si nunca has instalado Arch: [docs/instalar.md](docs/instalar.md).

¿Vienes de **Omarchy**? Puedes pasar a Nanuk sin reinstalar, con vuelta atrás:
[docs/desde-omarchy.md](docs/desde-omarchy.md).

## Actualizar

```bash
nanuk check    # ¿hay algo nuevo? (solo mira: repos, AUR, flatpak y Nanuk)
nanuk update   # versión estable de Nanuk + sistema + paquetes nuevos + defaults
```

No hace falta acordarse: **una hora después de encender**, Nanuk consulta una
sola vez si hay actualizaciones (y otra si no apagas en más de 24 h). Si las
hay, aparece el icono de actualizar (󰓦) junto al clima en la barra; clic → te las enseña y
pregunta si actualizar ahora.

`nanuk update` nunca toca `~/.config/nanuk/user/`. Pone Nanuk en la versión
**estable** (si editaste `~/.local/share/nanuk`, guarda tus cambios con
`git stash`), actualiza el sistema, instala los paquetes que Nanuk haya
**añadido** a sus listas (no reinstala lo que quitaste) y avisa de los que ya no
usa, re-despliega la config por defecto, re-aplica el arranque (splash,
autologin, keyring) solo si cambió, recarga Hyprland y la barra, y te dice si
hace falta reiniciar o cerrar sesión.

## Dónde está cada cosa

| Quiero...                          | Voy a...                                         |
|------------------------------------|--------------------------------------------------|
| Cambiar un atajo, monitor, regla   | `~/.config/nanuk/user/hypr/*.lua` (nunca se pisa) |
| Cambiar la terminal por defecto    | `~/.config/nanuk/user/hypr/apps.lua`             |
| Personalizar waybar/kitty/mako/fuzzel | `cp -r ~/.config/nanuk/default/waybar ~/.config/nanuk/user/` y editar |
| Instalar algo (repo/AUR/flatpak)   | `nanuk install <paquete>` (lo detecta y lo anota) |
| Instalar sin acordarme de comandos | `nanuk menu`, `SUPER+SHIFT+I` o el copo de la barra: buscar/quitar paquetes, tema, fondo, actualizar |
| Quitar varios paquetes a la vez    | `nanuk menu` → *Quitar paquetes*: todos los instalados, `Espacio` marca |
| Saber si hay actualizaciones       | el icono 󰓦 de la barra (sale solo) o `nanuk check` |
| Seguir lo último (`main`) en vez de `estable` | `echo main > ~/.config/nanuk/user/channel` (bórralo para volver) |
| Ver todos los atajos de teclado    | `nanuk keys` o `SUPER+K`                          |
| Cambiar el fondo de pantalla       | `nanuk bg` (lista), `nanuk bg 3`, `SUPER+SHIFT+B` rota; los tuyos en `user/backgrounds/` |
| Añadir una app web (Brave, ventana propia) | `nanuk webapp add "Nombre" https://url` (y un atajo en `user/hypr/bindings.lua` si quieres) |
| Ver los defaults (no editar)       | `~/.config/nanuk/default/`                        |

## Documentación

| Guía | Qué explica |
|---|---|
| [Instalar](docs/instalar.md) | desde la ISO o sobre Arch, paso a paso |
| [Personalizar](docs/personalizar.md) | dónde va lo tuyo, app por app, y qué toca un update |
| [Desde Omarchy](docs/desde-omarchy.md) | migrar sin reinstalar, en dos fases, con vuelta atrás |

La carpeta `~/.config/nanuk/user/` trae además un `README.md` que apunta a la
guía de personalización.
