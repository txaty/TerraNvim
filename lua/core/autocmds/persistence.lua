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

  -- Persist the theme whenever it changes, including a hand-typed
  -- :colorscheme. core.theme.apply() saves explicitly (or deliberately not,
  -- for previews and the startup restore), so skip events it triggers.
  autocmd("ColorScheme", {
    group = augroup "ThemeAutoSave",
    callback = function(ev)
      local ok, theme = pcall(require, "core.theme")
      if not ok or theme.is_applying() then
        return
      end
      -- ev.match is the name given to :colorscheme (e.g. kanagawa-lotus),
      -- which is more precise than the g:colors_name some themes set.
      local name = theme.resolve(ev.match, vim.o.background)
      if name then
        theme.set_current(name)
        theme.save(name)
      end
    end,
  })
end

return M
