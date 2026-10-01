-- File type specific settings
local autocmd = vim.api.nvim_create_autocmd
local augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

local M = {}

function M.setup()
  -- Prose-friendly settings for text files. vim.b.prose_wrap tells
  -- core.ui_toggle.apply() (BufWinEnter, which runs after FileType) to keep
  -- wrap on here regardless of the global wrap toggle.
  autocmd("FileType", {
    group = augroup "prose_settings",
    pattern = { "markdown", "text", "tex", "typst" },
    callback = function(args)
      vim.b[args.buf].prose_wrap = true
      vim.opt_local.wrap = true
      vim.opt_local.linebreak = true
      vim.opt_local.breakindent = true
    end,
  })

  -- Python specific folding config
  autocmd("FileType", {
    group = augroup "python_settings",
    pattern = "python",
    callback = function()
      vim.opt_local.foldenable = false
      vim.opt_local.foldmethod = "manual"
    end,
  })
end

return M
