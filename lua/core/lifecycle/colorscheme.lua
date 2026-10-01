-- Colorscheme restore at VimEnter, before UI plugins render.
local M = {}

---Apply the saved theme (or settings theme.dark). Nothing is written back:
---core.theme.apply() marks itself as applying, so the ColorScheme autosave in
---core/autocmds/persistence.lua ignores it.
---@return boolean restored_saved_theme
function M.restore()
  local ok, theme = pcall(require, "core.theme")
  if not ok then
    pcall(vim.cmd.colorscheme, "habamax")
    return false
  end
  return theme.restore()
end

return M
