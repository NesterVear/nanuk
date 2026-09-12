# Personalizar Nanuk — dónde va lo tuyo

Nanuk se instala en **dos capas**. Entender esto es lo único que necesitas
para no perder nunca una configuración:

```
~/.config/nanuk/
├── default/   ← lo nuestro. SE REEMPLAZA en cada `nanuk update`. No edites aquí.
├── user/      ← lo tuyo. Se crea una vez al instalar y NUNCA se vuelve a tocar.
├── themes/    ← temas del repo (se reemplazan igual que default/).
└── theme      → enlace al tema activo
```

La regla: **todo lo que quieras cambiar va en `~/.config/nanuk/user/`**.
Abre esa carpeta con `nanuk edit`. Dentro hay un `README.md` que apunta a esta
guía.

Hay dos maneras en que una app lee tu capa, según si soporta "includes" o no:

| Mecanismo               | Apps                                                      | Cómo funciona                                                         |
|-------------------------|-----------------------------------------------------------|-----------------------------------------------------------------------|
| **Capas reales**        | Hyprland, bash                                            | Se carga `default/` y **después** `user/`. Lo tuyo gana línea a línea. |
| **Precedencia de ruta** | waybar, kitty, mako, wofi, fastfetch, GTK, starship, hyprlock, hypridle, lazygit, lazydocker | Si existe `user/<app>`, se enlaza esa; si no, `default/<app>`. Todo o nada por app. |

---

## Mapa rápido: quiero cambiar…

### Atajos de teclado, monitores, reglas de ventana, autostart (Hyprland)

Archivos en `~/.config/nanuk/user/hypr/`. Vienen con ejemplos comentados:

| Archivo          | Para qué                                                  |
|------------------|-----------------------------------------------------------|
| `apps.lua`       | terminal, navegador, editor, gestor de archivos por defecto |
| `bindings.lua`   | atajos nuevos, cambiar o quitar uno de los nuestros       |
| `monitors.lua`   | resolución, escala, posición, workspaces por monitor      |
| `input.lua`      | teclado, distribución, touchpad, sensibilidad             |
| `windows.lua`    | reglas: qué flota, qué va a qué workspace, opacidad       |
| `looknfeel.lua`  | gaps, bordes, animaciones (si quieres salirte de la densidad estricta) |
| `autostart.lua`  | programas que arrancan con la sesión                      |
| `init.lua`       | qué archivos de los anteriores se cargan. Añade aquí los tuyos. |

Como tu capa se carga **al final**, cualquier `hl.*` que pongas sobreescribe
el default. Para los atajos tienes tres verbos:

```lua
n.bind("SUPER + C", "VS Code", n.launch("code"))              -- añadir
n.rebind("SUPER + RETURN", "Terminal", n.launch("kitty"))     -- reemplazar uno nuestro
hl.unbind("SUPER + O")                                        -- quitar sin reemplazo
```

Aplicar: `hyprctl reload`. Ver la lista de defaults: `~/.config/nanuk/default/hypr/bindings/*.lua`
(solo para leer). Chuleta en pantalla: `SUPER + K` o `nanuk keys`.

### Alias, funciones, `PATH`, variables de entorno (bash)

`~/.config/nanuk/user/bash/rc`. Se carga después del nuestro, así que puedes
redefinir cualquier alias. No edites `~/.bashrc` a mano: el bloque
`>>> nanuk >>>` que hay ahí solo carga las dos capas.

### El prompt (starship)

```bash
cp ~/.config/nanuk/default/starship.toml ~/.config/nanuk/user/starship.toml
nvim ~/.config/nanuk/user/starship.toml
bash ~/.local/share/nanuk/install/06-dotfiles.sh    # rehace los enlaces
```

### Barra, terminal, notificaciones, launcher (waybar, kitty, mako, wofi)

Estas apps no saben de capas: se copia **la carpeta entera** a `user/` y se
edita ahí. A partir de ese momento esa app deja de recibir cambios nuestros
(es el precio de tener el control total).

```bash
cp -r ~/.config/nanuk/default/waybar ~/.config/nanuk/user/waybar
nvim ~/.config/nanuk/user/waybar/config.jsonc
bash ~/.local/share/nanuk/install/06-dotfiles.sh    # ~/.config/waybar → user/waybar
```

Lo mismo con `kitty`, `mako`, `wofi`, `fastfetch`, `gtk-3.0`,
`gtk-4.0`, `lazygit`, `lazydocker`, y con los archivos sueltos
`hypr/hyprlock.conf` y `hypr/hypridle.conf`.

Para volver a los defaults: borra `user/<app>` y re-ejecuta el paso 06.

### Apps web (Tidal, WhatsApp, ChatGPT… en ventana propia)

`nanuk-webapp <url> [--focus]` abre la URL en Brave Origin en modo app (sin
barra de direcciones). Con `--focus`, si ya está abierta la enfoca en vez de
duplicarla. Nanuk trae Tidal (`SUPER + SHIFT + U`) y WhatsApp (`SUPER + SHIFT + G`).

Para añadir la tuya solo hace falta el nombre y la URL:

```bash
nanuk webapp add "YouTube" https://youtube.com     # aparece en el launcher al momento
nanuk webapp list
nanuk webapp remove youtube
```

Eso escribe `~/.config/nanuk/user/webapps/youtube.desktop` (tu capa: sobrevive a
los updates) y lo enlaza en `~/.local/share/applications`. Si en `user/webapps/`
hay un archivo con el mismo nombre que uno nuestro (`tidal.desktop`), gana el tuyo.

Un atajo, si lo quieres, en `~/.config/nanuk/user/hypr/bindings.lua`:

```lua
n.bind("SUPER + SHIFT + Y", "YouTube", "nanuk-webapp https://youtube.com --focus")
```

### El menú: `nanuk menu` (o `SUPER + SHIFT + I`)

Para no tener que recordar comandos. Un menú en la terminal (hecho con `gum`)
con: instalar o quitar un paquete escribiendo solo el nombre, añadir o quitar
una app web con nombre y URL, instalar un lenguaje, actualizar el sistema y
el diagnóstico. Por debajo llama a los mismos `nanuk install`, `nanuk webapp`,
`nanuk lang`… así que todo queda anotado en tu capa igual.

### Paquetes

- **Algo suelto** (repo, AUR o flatpak, lo detecta solo):
  `nanuk install <paquete>`. Queda anotado en `user/packages.txt`, y
  `nanuk sync` lo reinstala todo en una máquina nueva.
- **Algo que debería venir con Nanuk para todos**: una línea en
  `packages/*.txt` del repo y re-ejecutar el paso 03. Las listas, por tema:

  | Archivo               | Qué hay                                            | ¿Se instala?          |
  |-----------------------|----------------------------------------------------|-----------------------|
  | `packages/base.txt`   | sistema, red, energía, CLI de diario (btop, fzf, eza, gum…) | siempre (pacman) |
  | `packages/desktop.txt`| Hyprland, barra, kitty, audio, Firefox, fuentes, GTK | siempre (pacman) |
  | `packages/dev.txt`    | neovim, docker, python/php/node/lua, mise, rustup (BD: en Docker) | siempre (pacman) |
  | `packages/3dprint.txt`| FreeCAD                                            | siempre (pacman)      |
  | `packages/virt.txt`   | libvirt, qemu, virt-manager, OVMF, swtpm           | siempre (pacman)      |
  | `packages/security.txt` | KeePassXC, tor, Tor Browser (launcher)           | siempre (pacman)      |
  | `packages/aur.txt`    | Brave Origin, VS Code, fuente del wordmark         | siempre (yay, no crítico) |
  | `packages/flatpak.txt`| OrcaSlicer                                         | siempre (flathub, no crítico) |
  | `packages/extras.txt` | apps personales (R, MariaDB nativa, Obsidian, LibreOffice…) | solo con `NANUK_EXTRAS=1` |

  Quitar un paquete de Nanuk = borrar su línea. Ojo: eso solo evita que se
  instale en máquinas nuevas; en la tuya sigue hasta que hagas `pacman -Rns`.
- Quitar: `nanuk remove <paquete>`. Ver la lista: `nanuk list`.

### Lenguajes y versiones

`nanuk lang <lenguaje>` (rust, node, python, go, ruby, java, php, r). Las
versiones por proyecto las gestiona `mise` con un `.mise.toml` o
`.tool-versions` en la carpeta del proyecto.

### Neovim

`~/.config/nvim/` es **tuyo** (LazyVim). Nanuk solo refresca dos archivos
suyos: `colors/nanuk.lua` y `lua/plugins/nanuk.lua`. Todo lo demás no se toca.

### btop

`~/.config/btop/btop.conf` se copia una sola vez y después es tuyo (btop lo
reescribe al salir). Solo el tema `nanuk.theme` se enlaza desde los defaults.

### Tema

`nanuk theme` lista los temas; `nanuk theme <nombre>` cambia. Cada tema vive en
`~/.config/nanuk/themes/<nombre>/` (`colors.toml`, `hyprland.lua`, `wordmark.*`).

> Hoy `themes/` se reemplaza entero en cada update: un tema propio debe
> añadirse **en el repo**, no en `~/.config/nanuk/themes/`. Un `user/themes/`
> que sobreviva a los updates está en el plan (Fase 3/7).

---

## Qué toca y qué no toca un `nanuk update`

| Ruta                                  | ¿Se toca?                                     |
|---------------------------------------|-----------------------------------------------|
| `~/.config/nanuk/default/`            | Sí, se reemplaza entera (espejo del repo)     |
| `~/.config/nanuk/themes/`             | Sí, se reemplaza entera                       |
| `~/.config/nanuk/user/`               | **No.** Solo se añaden plantillas nuevas si no existen |
| `~/.config/nanuk/theme` (enlace)      | No, respeta el tema que elegiste              |
| `~/.config/hypr/hyprland.lua`         | Sí (es nuestro; si había otro, se respalda `.bak.*`) |
| `~/.config/{waybar,kitty,…}` (enlaces) | Se rehacen apuntando a `user/` o `default/`   |
| `~/.config/nvim/`                     | Solo `colors/nanuk.lua` y `lua/plugins/nanuk.lua` |
| `~/.config/btop/btop.conf`            | No (se copió una vez)                         |
| `~/.bashrc`                           | No (el bloque nanuk se añade solo si falta)   |

Si alguna vez encuentras algo tuyo con sufijo `.bak.<timestamp>`, es que
Nanuk lo encontró donde esperaba poner un enlace y lo apartó en vez de borrarlo.

## Comprobar que todo está en su sitio

```bash
nanuk doctor      # enlaces rotos, servicios caídos, grupos, Hyprland
hyprctl reload    # tras editar user/hypr/*
```
