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
| **Precedencia de ruta** | waybar, kitty, mako, fuzzel, fastfetch, GTK, starship, hyprlock, hypridle, lazygit, lazydocker | Si existe `user/<app>`, se enlaza esa; si no, `default/<app>`. Todo o nada por app. |

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

### Barra, terminal, notificaciones, launcher (waybar, kitty, mako, fuzzel)

Estas apps no saben de capas: se copia **la carpeta entera** a `user/` y se
edita ahí. A partir de ese momento esa app deja de recibir cambios nuestros
(es el precio de tener el control total).

```bash
cp -r ~/.config/nanuk/default/waybar ~/.config/nanuk/user/waybar
nvim ~/.config/nanuk/user/waybar/config.jsonc
bash ~/.local/share/nanuk/install/06-dotfiles.sh    # ~/.config/waybar → user/waybar
```

Lo mismo con `kitty`, `mako`, `fuzzel`, `fastfetch`, `gtk-3.0`,
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

Para no tener que recordar comandos. También con el copo de nieve de la
izquierda de la barra. Un menú en una terminal flotante (`gum` + `fzf`) con:

- **Buscar e instalar paquetes**: todos los de los repos oficiales y del AUR
  en una lista que se filtra al escribir, con la ficha del paquete al lado.
  `Tab` marca varios. Un id de flatpak (`com.spotify.Client`) se escribe tal
  cual y `Enter`.
- **Quitar paquetes**: lo instalado a propósito y tus flatpaks. Lo que viene
  con Nanuk sale marcado y pide confirmación.
- **Actualizar el sistema**, **cambiar el tema**, **cambiar el fondo**, apps
  web, lenguajes y el diagnóstico.

Por debajo llama a los mismos `nanuk install`, `nanuk remove`, `nanuk theme`…
así que todo queda anotado en tu capa igual.

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

### Ventanas: qué flota, con qué tamaño

Las reglas de `default/hypr/windows.lua` hacen que casi nada haya que
recolocarlo a mano:

| Tipo | Ejemplos | Cómo abre |
|------|----------|-----------|
| Diálogo | "¿Seguro?", Propiedades, polkit, calculadora | flotando, centrado, con su tamaño natural |
| Mediana (60% x 65%) | btop, `nanuk menu`, nmtui, pavucontrol, KeePassXC, file-roller | flotando, centrada |
| Grande (72% x 80%) | elegir o guardar archivos en cualquier app | flotando, centrada |
| Navegador | Brave, Chromium y sus apps web | siempre en mosaico |
| Resto | editores, terminal, Nautilus, VLC | en mosaico |

Los modales se reconocen por el protocolo, no por el título, así que funciona
en cualquier idioma. Para meter una app tuya en una talla, en
`user/hypr/windows.lua`:

```lua
n.window("^(org.keepassxc.KeePassXC)$", { tag = "+float-md" })   -- mediana
n.window("^(mi-app)$", { tag = "+float-lg" })                    -- grande
n.window("^(gimp)$", { tag = "-dialog" })                        -- que no flote
```

La clase de una ventana: `hyprctl clients`. `SUPER + T` pasa la ventana
activa a flotante mediana y centrada, o la devuelve al mosaico.

### Inicio de sesión y keyring

Nanuk entra por autologin y **bloquea al momento con hyprlock**: ves el
wordmark y el campo de contraseña como si fuera una pantalla de inicio de
sesión, sin display manager. Esa misma contraseña abre el keyring de GNOME
(Brave, VS Code…), así no vuelve a preguntar.

**Con el disco cifrado (LUKS)** la contraseña ya la tecleas en el arranque,
en la pantalla de Nanuk, así que hyprlock no vuelve a salir: entras directo al
escritorio. Como nadie le da una contraseña al keyring, el instalador lo deja
sin contraseña propia (lo protege el cifrado del disco, como en Omarchy) y no
activa `pam_gnome_keyring`; si encuentra un keyring "login" vacío de antes, lo
aparta como `login.keyring.bak`. Si tu keyring "login" sí guarda secretos y
tiene contraseña, se pedirá al abrirlo: en `seahorse` → *Inicio de sesión* →
*Cambiar contraseña*, déjala vacía y no vuelve a salir.

Para cambiarlo, en `~/.config/nanuk/user/hypr/autostart.lua`:
`n.lock_on_start = false` (nunca bloquear al entrar) o `true` (siempre, aunque
el disco esté cifrado).

### Entradas que no quieres ver en el launcher

`~/.config/nanuk/user/hidden-apps.txt`: un id de `.desktop` por línea (el nombre
del archivo en `/usr/share/applications/` sin la extensión). Nanuk ya oculta
las de avahi ("Examinador de servidores SSH/VNC") y algunas herramientas de
dependencias (`default/hidden-apps.txt`). Aplica con el paso 06.

### Apps GTK y Qt (Nautilus, diálogos, VLC, KeePassXC…)

Negro absoluto y blanco, iconos **Tela-circle-grey-dark** (estilo Material,
carpetas grises), cursor Adwaita, radio 0. Tres piezas, todas en `default/`:
`gtk-3.0/` y `gtk-4.0/` (settings.ini + gtk.css) y el bloque `gsettings` del
paso 05, que es lo que las apps de libadwaita leen de verdad en Wayland.
Qt usa `QT_QPA_PLATFORMTHEME=gtk3` y sigue a GTK. Para cambiar de iconos:
`gsettings set org.gnome.desktop.interface icon-theme "<nombre>"` y la línea
`gtk-icon-theme-name` en tu copia de `user/gtk-3.0/settings.ini`.

### Fondo de pantalla

Nanuk trae siete fondos en el tema (`~/.config/nanuk/theme/backgrounds/1.jpg` … `7.jpg`)
y arranca con el `1`. Para elegir otro, o ninguno:

```bash
nanuk bg              # lista (● = activo)
nanuk bg 3            # activa 3.jpg del tema
nanuk bg none         # negro puro, sin imagen (swaybg ni se arranca)
nanuk bg next         # el siguiente de la lista; también SUPER + SHIFT + B
```

Tus propias imágenes van en `~/.config/nanuk/user/backgrounds/` (jpg, png o
webp) y aparecen en la lista con su nombre: `nanuk bg mi-foto`. Lo fácil es
que las copie Nanuk:

```bash
nanuk bg add ~/Descargas/aurora.jpg   # la copia a user/backgrounds/ y la activa
```

O desde `nanuk menu` (`SUPER + SHIFT + I`) → **"Añadir una imagen de fondo"**:
un buscador con tus imágenes de Imágenes, Descargas y Escritorio (las más
nuevas primero) y la vista previa al lado; también puedes pegar la ruta de
cualquier imagen. "Cambiar el fondo de pantalla" elige entre las que ya hay.

Lo elegido se guarda como enlace en `~/.config/nanuk/user/background`, así que
sobrevive a los updates. Lo pinta `swaybg` (no hay archivo de config: recibe la
imagen como argumento). Si algo falla, avisa con una notificación y lo que dijo
queda en `~/.local/state/nanuk/swaybg.log`.

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
| `~/.config/nanuk/user/background`     | No, respeta el fondo que elegiste (se crea si falta) |
| `~/.config/hypr/hyprland.lua`         | Sí (es nuestro; si había otro, se respalda `.bak.*`) |
| `~/.config/{waybar,kitty,…}` (enlaces) | Se rehacen apuntando a `user/` o `default/`   |
| `~/.config/nvim/`                     | Solo `colors/nanuk.lua` y `lua/plugins/nanuk.lua` |
| `~/.config/btop/btop.conf`            | No (se copió una vez)                         |
| `~/.bashrc`                           | No (el bloque nanuk se añade solo si falta)   |
| `~/.local/share/icons/Nanuk/`         | Sí, se regenera (tema de iconos monocromo)    |
| gsettings (modo oscuro, iconos, fuente) | Sí, se reaplican                            |
| Paquetes                              | Solo se instalan los que Nanuk **añadió** a sus listas desde la última vez; los que ya no usa se avisan, no se borran |
| `~/.local/share/nanuk` (el repo)      | `git pull`; si lo editaste, tus cambios quedan en `git stash` |

Si alguna vez encuentras algo tuyo con sufijo `.bak.<timestamp>`, es que
Nanuk lo encontró donde esperaba poner un enlace y lo apartó en vez de borrarlo.

## Comprobar que todo está en su sitio

```bash
nanuk doctor      # enlaces rotos, servicios caídos, grupos, Hyprland
hyprctl reload    # tras editar user/hypr/*
```
