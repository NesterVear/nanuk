-- Colorscheme "nanuk" — se invoca con :colorscheme nanuk (LazyVim lo hace solo).
-- Negro absoluto, blanco, grises; el hielo (#9fd8ff) solo donde hay foco:
-- cursor y búsqueda activa. Aplica la paleta a TODOS los grupos vía
-- mini.base16 (incluye treesitter, LSP y plugins). Requiere echasnovski/mini.base16.

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("colorscheme nanuk: falta mini.base16", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#000000", -- fondo
    base01 = "#0a0a0a", -- fondo de líneas de estado / cursorline
    base02 = "#1e1e1e", -- selección
    base03 = "#707070", -- comentarios, invisibles
    base04 = "#909090", -- texto atenuado
    base05 = "#d8d8d8", -- texto normal
    base06 = "#e8e8e8",
    base07 = "#ffffff", -- lo más brillante
    base08 = "#b0a0a0", -- variables, borrado
    base09 = "#b0a89c", -- números, constantes
    base0A = "#b0b0a0", -- clases, tipos
    base0B = "#a0b0a0", -- cadenas, añadido
    base0C = "#a0b0b0", -- soporte, escapes
    base0D = "#a0a8b0", -- funciones
    base0E = "#b0a0b0", -- palabras clave
    base0F = "#5a5a5a",
  },
})

vim.g.colors_name = "nanuk"

-- Único acento de color: hielo en el cursor y la búsqueda activa.
local ice = "#9fd8ff"
for _, group in ipairs({ "Cursor", "lCursor", "TermCursor", "IncSearch", "CurSearch" }) do
  vim.api.nvim_set_hl(0, group, { fg = "#000000", bg = ice })
end
vim.api.nvim_set_hl(0, "Search", { fg = "#000000", bg = "#3a3a3a" })
