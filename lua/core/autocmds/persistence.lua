-- Session and theme auto-persistence on exit / colorscheme change
local autocmd = vim.api.nvim_create_autocmd
local augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

local M = {}

function M.setup()
  -- Session auto-save on exit
  autocmd("VimLeavePre", {
    group = augroup "SessionAutoSave",
    callback = function()
      if not require("core.session_toggle").is_enabled() then
        return
      end
      local ok, session = pcall(require, "core.lifecycle.session")
      if ok then
        session.save()
      end
    end,
  })

  -- Auto-save theme whenever it changes (skip during live preview)
  autocmd("ColorScheme", {
    group = augroup "ThemeAutoSave",
    callback = function()
      local ok, theme = pcall(require, "core.theme")
      if not ok then
        return
      end
      -- Don't persist during theme picker preview
      if theme.is_previewing() then
        return
      end
      local current = vim.g.colors_name
      -- Only save if it's a theme we recognize
      if current and theme.theme_info[current] then
        theme.save_theme(current)
      end
    end,
  })
end

return M
