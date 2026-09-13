# Esta carpeta es tuya

`~/.config/nanuk/user/` se creó una vez al instalar Nanuk y **ningún update la
vuelve a tocar**. Todo lo que quieras cambiar del sistema va aquí, nunca en
`../default/` (esa se reemplaza entera en cada `nanuk update`).

- Atajos, monitores, reglas de ventana, apps por defecto → `hypr/*.lua`
- Alias y variables de entorno → `bash/rc`
- Una app entera (waybar, kitty, mako, fuzzel…) → copia `../default/<app>` aquí
  y re-ejecuta `bash ~/.local/share/nanuk/install/06-dotfiles.sh`
- Apps web para el launcher (Brave, ventana propia) → `webapps/*.desktop`
  (las crea `nanuk webapp add "Nombre" https://url`, o `nanuk menu`)
- Paquetes tuyos → `packages.txt` (lo llena `nanuk install`)
- Fondos de pantalla tuyos → `backgrounds/*.jpg|png`; el elegido es el enlace
  `background` (lo cambia `nanuk bg <nombre>`, `nanuk bg none` = negro puro)
- Canal de actualizaciones → `channel` (no existe = versión `estable`; con
  `main` dentro, `nanuk update` trae lo último sin esperar a que se publique)

Guía completa: `docs/personalizar.md` en el repo
(`~/.local/share/nanuk/docs/personalizar.md`).
