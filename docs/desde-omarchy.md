# Pasar de Omarchy a Nanuk sin reinstalar

Omarchy y Nanuk son las dos una capa de paquetes y configuración sobre Arch.
Se puede pasar de uno a otro **en la misma instalación**, sin tocar `/home`,
en dos fases con vuelta atrás entre medias.

```
bash install/from-omarchy.sh        # fase A: Nanuk toma el control; Omarchy sigue instalado
# reiniciar, usar Nanuk unos días
bash install/rollback-to-omarchy.sh # (solo si quieres volver; deshace la fase A)
bash install/purge-omarchy.sh       # fase B: quita Omarchy. Sin vuelta atrás.
```

Los scripts están en el repo de Nanuk. Para tenerlo:
`git clone https://github.com/nestervear/nanuk ~/.local/share/nanuk` y
ejecútalos desde ahí.

## Fase A — `from-omarchy.sh`

Qué hace, y por qué:

| Paso | Motivo |
|------|--------|
| Respaldo en `~/.local/share/nanuk-migracion/<fecha>/` | config de Hyprland, Omarchy, kitty, starship, uwsm, nvim, `.bashrc`, `.bash_profile`, sddm, limine, lista de paquetes |
| `limine` y `limine-mkinitcpio-hook` → explícitos | en Omarchy son *dependencias* del paquete `omarchy`; sin eso, quitarlo dejaría el equipo sin arranque tras el siguiente kernel |
| Quitar `mise-bin` (repo de Omarchy) | choca con el `mise` de los repos oficiales que instala Nanuk; los datos de `~/.local/share/mise` se conservan |
| Desactivar `omarchy-*.service` de usuario | arrancarían dentro de la sesión de Nanuk (crash-watch, sleep-lock, fcitx5…) |
| `pacman -Syu` con `OMARCHY_ALLOW_DIRECT_PACMAN=1` (paso 02 y `nanuk update`) | el hook `00-omarchy-update-guard` de Omarchy aborta toda actualización completa que no lance `omarchy update`; con esa variable la deja pasar. El hook desaparece con Omarchy en la fase B |
| `install/install.sh` completo | el paso 05 **desactiva sddm** y pone autologin en tty1; el 06 aparta tu `hyprland.lua`, `kitty/`, `starship.toml`… como `.bak.<fecha>` |

Después de reiniciar deberías ver: splash de Nanuk → contraseña del disco (si
está cifrado) → Hyprland directo, con tu capa `~/.config/nanuk/user/`.

**Si la pantalla de contraseña del disco no se dibuja**: pulsa `Esc` para ver el
diálogo en texto y escribe ahí. Para volver mientras tanto al splash de
Omarchy: `sudo plymouth-set-default-theme -R omarchy`. Si te pasa, abre un issue
con lo que viste.

Cosas de Nanuk que notarás en una máquina que era de trabajo:

- `sshd`, `docker` y `libvirtd` quedan **activados**. Si no usas SSH entrante:
  `sudo systemctl disable --now sshd`.
- Nanuk no toca lo que instalaste tú fuera de Omarchy: programas en `/opt` con
  su propio servicio (VPNs, por ejemplo), Tailscale, Ollama… La purga solo quita
  los paquetes `omarchy*` y sus dependencias huérfanas. Lo único que se va de
  Tailscale es el ayudante `omarchy-tailscale-receive` (recibir archivos por
  Taildrop con aviso).
- Tu `kitty.conf` y `starship.toml` de antes están al lado con `.bak.*`; lo que
  quieras conservar va a `~/.config/nanuk/user/kitty/` o `user/starship.toml`.
- `.bashrc` sigue cargando el `rc` de Omarchy además del de Nanuk (dos
  `fastfetch`, alias repetidos). Se limpia en la fase B.
- El repo que usa el sistema es `~/.local/share/nanuk` (carpeta oculta, por el
  punto de `.local`; en Nautilus, `Ctrl+H`). El respaldo de la migración está al
  lado, en `~/.local/share/nanuk-migracion/`.

## Volver — `rollback-to-omarchy.sh`

Reactiva sddm, quita el autologin y el bloque de `~/.bash_profile`, devuelve el
`hyprland.lua` de Omarchy, reactiva sus servicios de usuario y su splash. Los
paquetes de Nanuk se quedan (no molestan). Solo funciona **antes** de la fase B.

## Fase B — `purge-omarchy.sh`

### Antes de quemar el barco

1. `nanuk update`, para que la purga se ejecute con la última versión.
2. **Reinicia una vez** y comprueba que el arranque va bien: splash, contraseña
   del disco, escritorio sin ventanas raras. Mejor purgar sobre un arranque que
   ya sabes que funciona.
3. Si quieres ver antes qué se llevaría, se puede simular sin tocar nada:

   ```bash
   D=$(mktemp -d); cp -a /var/lib/pacman/local "$D/"; ln -s /var/lib/pacman/sync "$D/sync"
   fakeroot pacman --dbpath "$D" -D --asexplicit $(pacman -Qqe)   # lo tuyo, protegido
   pacman --dbpath "$D" -Rs --print --print-format '%n' omarchy omarchy-settings omarchy-nvim omarchy-keyring
   ```

   Es una aproximación: el script protege además las listas de Nanuk. Lo normal
   es que quite los cuatro `omarchy*` y lo que Omarchy traía para las
   instantáneas (`snapper`, `limine-snapper-sync` y, si tu disco no es btrfs,
   `btrfs-progs`). Si `/` o `/home` son btrfs (la instalación por defecto de
   Omarchy), `btrfs-progs` se queda; las instantáneas ya hechas siguen en el
   disco como subvolúmenes. Revisa la lista antes de aceptar.

Después:

```bash
bash ~/.local/share/nanuk/install/purge-omarchy.sh
```

Qué hace:

1. Comprueba que estás en una sesión Nanuk (tu `hyprland.lua` es el de Nanuk y
   hay autologin).
2. Marca como explícitos los paquetes que Nanuk necesita (sus listas, `limine`,
   `limine-mkinitcpio-hook`, microcode, `yay`, `mise` y `btrfs-progs` si hay algún
   sistema de archivos btrfs montado) para que no se vayan como
   dependencias de Omarchy. Si tienes una variante que sustituye a otro paquete
   (`nodejs-lts-jod` en lugar de `nodejs`, por ejemplo), protege la que tienes.
3. Escribe `/etc/limine-entry-tool.d/nanuk.conf` (UKI, nombre "Nanuk", arranque
   silencioso), porque la config equivalente de Omarchy se va con su paquete.
4. Muestra qué quitaría `pacman -Rs omarchy omarchy-settings omarchy-nvim
   omarchy-keyring` y pide un `si` explícito.
5. Devuelve a su sitio los `.pacsave` de `/etc` que eran tu configuración
   (`docker/daemon.json`, `sysctl.d/*`).
6. Quita el repositorio `[omarchy]` de `pacman.conf`.
7. Limpia lo que Omarchy escribió fuera de sus paquetes (por eso `pacman -Rns`
   no se lo lleva):
   - `/etc/os-release` decía "Omarchy": vuelve a ser un enlace a
     `/usr/lib/os-release`, como en Arch. Si cambiaste `/usr/lib/os-release` a
     propósito (hay programas que solo se instalan si dice otra distro), se
     respeta.
   - El menú de Limine seguía diciendo **Omarchy**: `limine-entry-tool` reconoce
     la entrada por el `machine-id` y conserva su nombre. Se renombra a
     **Nanuk** una vez.
   - El espejo de pacman de Omarchy (`stable-mirror.omarchy.org`, va con
     retraso) se cambia por los espejos de Arch más rápidos, con `reflector`.
     Después, `nanuk update`.
   - Lo útil se queda con nombre de Nanuk (keepalive de SSH, límite de inotify
     para VS Code). Se aparta el resto: respaldos `.bak` de actualizaciones de
     Omarchy, redes retiradas, PAM y tema SDDM de Omarchy, config de snapper. Se
     quita `~/.local/share/omarchy/bin` del `PATH` de tus servicios (por ejemplo
     `ollama.service`) y `/etc/skel/.bashrc` vuelve a ser el de Arch.
8. `mkinitcpio -P` + `limine-update`, y **verifica** que existe cada imagen a la
   que apunta `/boot/limine.conf`. Si no, para y te lo dice antes de que
   reinicies. Si todo está bien, borra la imagen vieja `omarchy_*.efi` (~50 MB en
   la partición EFI).
9. Quita el bloque de Omarchy de `~/.bashrc` y aparta (no borra) los restos:
   `~/.config/omarchy`, `~/.local/state/omarchy`, `~/.local/share/omarchy`,
   `Omacom`, `~/.cache/omarchy`, los `*.omarchy-upgrade-to-quattro.*.bak`, los
   `NativeMessagingHosts/com.omarchy.*` de los navegadores, las skills de agentes
   enlazadas a `/usr/share/omarchy`, las líneas de config que cargan archivos de
   Omarchy (`--load-extension` en `*-flags.conf`, `include` de temas en foot o
   ghostty), los `.conf`/`.lua` de Omarchy en `~/.config/hypr` y
   `/etc/sddm.conf.d`.
10. Busca todo lo que aún se llame "omarchy" (paquetes, `/etc`, `/boot`, tu home)
    y te lo enseña. No lo toca: puede ser tuyo (un tema de VS Code, una nota).

Se puede **repetir** sin riesgo: si Omarchy ya no está instalado, se salta los
pasos de paquetes y solo limpia restos y verifica.

Si al final dice **"NO REINICIES"**, no reinicies: falta la imagen de arranque.
Revisa con `sudo mkinitcpio -P && sudo limine-update ; cat /boot/limine.conf`.
Si todo fue bien, reinicia.

### Después

- Lo apartado queda en `~/.local/share/nanuk-migracion/omarchy-restos-<fecha>/`.
  Cuando lleves unos días sin echar nada de menos, puedes borrar
  `~/.local/share/nanuk-migracion/` entera.
- **`~/.local/share/nanuk` no se borra**: es la copia de Nanuk que usa el sistema
  (`nanuk`, `nanuk update`, los enlaces de `~/.local/bin`).
- Paquetes que venían del repo de Omarchy y siguen instalados (Typora, VS Code,
  LocalSend, `yay`, `limine-mkinitcpio-hook`…) dejan de recibir actualizaciones
  de ahí. Están con el mismo nombre en el AUR: `yay -S <paquete>` los reengancha.
- El bloqueo de actualizaciones de Omarchy desaparece: `sudo pacman -Syu` vuelve
  a funcionar como en cualquier Arch (aunque lo normal es `nanuk update`).

## Alternativa limpia

Si prefieres empezar de cero: instala con la ISO de Nanuk en modo
**personalizado**, formateando `/` y **conservando** la partición de `/home` sin
formatear. Ver [instalar.md](instalar.md).
