-- Nanuk — teclas multimedia: volumen (wpctl/pipewire), brillo (brightnessctl),
-- reproducción (playerctl).
-- locked = funciona también con la pantalla bloqueada; repeating = mantener pulsado repite.

local vol_opts = { locked = true, repeating = true }

n.bind("XF86AudioRaiseVolume", "Subir volumen", "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+", vol_opts)
n.bind("XF86AudioLowerVolume", "Bajar volumen", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", vol_opts)
n.bind("XF86AudioMute", "Silenciar", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true })
n.bind("XF86AudioMicMute", "Silenciar micrófono", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", { locked = true })

n.bind("XF86MonBrightnessUp", "Subir brillo", "brightnessctl -e4 -n2 set 5%+", vol_opts)
n.bind("XF86MonBrightnessDown", "Bajar brillo", "brightnessctl -e4 -n2 set 5%-", vol_opts)

n.bind("XF86AudioPlay", "Reproducir / pausar", "playerctl play-pause", { locked = true })
n.bind("XF86AudioPause", "Pausar", "playerctl play-pause", { locked = true })
n.bind("XF86AudioNext", "Siguiente pista", "playerctl next", { locked = true })
n.bind("XF86AudioPrev", "Pista anterior", "playerctl previous", { locked = true })
