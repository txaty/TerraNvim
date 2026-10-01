-- Require Neovim 0.12+.
-- Why: the nvim-treesitter main branch, rustaceanvim 9 and refactoring.nvim 2
-- all require 0.12, and the config uses 0.12-only features (:restart,
-- v:startreason, native `an`/`in` incremental selection, `grt`/`grx`, LSP
-- inline completion). Without this guard, older versions fail deep inside
-- plugin code instead of with a clear, actionable message.
if vim.fn.has "nvim-0.12" == 0 then
  vim.notify(
    "This config requires Neovim 0.12 or later. Please upgrade: https://github.com/neovim/neovim/releases",
    vim.log.levels.ERROR
  )
  return
end

require "core.init"
