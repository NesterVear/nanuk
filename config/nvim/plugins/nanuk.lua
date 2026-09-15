-- Nanuk — tema de Neovim para LazyVim. Este archivo se despliega en
-- ~/.config/nvim/lua/plugins/nanuk.lua y se refresca en cada `nanuk update`.
-- Tu config de LazyVim (el resto de ~/.config/nvim) es tuya, no se toca.
return {
  -- La paleta base16 (un archivo, sin dependencias pesadas).
  { "nvim-mini/mini.base16", lazy = false, priority = 1000 },

  -- Decirle a LazyVim que use el colorscheme "nanuk" (colors/nanuk.lua).
  { "LazyVim/LazyVim", opts = { colorscheme = "nanuk" } },
}
