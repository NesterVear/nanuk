# Sesión de root en la ISO. En tty1 arranca el instalador; en cualquier
# otra consola (tty2...) queda una shell normal para mirar cosas.
[[ -f ~/.bashrc ]] && . ~/.bashrc
if [[ "$(tty)" == /dev/tty1 && -z "${NANUK_NO_AUTOSTART:-}" ]]; then
  nanuk-install
fi
