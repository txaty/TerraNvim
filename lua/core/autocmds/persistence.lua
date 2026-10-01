-- Theme persistence on colorscheme change. (Sessions are saved by
-- persistence.nvim itself; core/lifecycle/init.lua loads it when session
-- persistence is on.)
local autocmd = vim.api.nvim_create_autocmd
local augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

local M = {}

function M.setup()
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
      -- Most precise first: the name given to :colorscheme (ev.match) when it
      -- is a registry theme of the current 'background' (kanagawa-dragon);
      -- then g:colors_name, which some themes set to the full variant
      -- (tokyonight-moon); then base names resolved by 'background'.
      local bg = vim.o.background
      local exact = theme.registry[ev.match]
      local name = (exact and exact.variant == bg and ev.match)
        or theme.resolve(vim.g.colors_name, bg)
        or theme.resolve(ev.match, bg)
      theme.set_current(name) -- nil for themes outside the registry
      if name then
        theme.save(name)
      end
    end,
  })
end

return M
