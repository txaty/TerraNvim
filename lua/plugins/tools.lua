-- Formatting (conform.nvim) and linting (nvim-lint). Which formatters and
-- linters apply to which filetype comes from the enabled language packs
-- (lua/langs/*), collected when each plugin loads.
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>lf",
        function()
          require("conform").format { async = true }
        end,
        mode = { "n", "v" },
        desc = "LSP: Format buffer / selection",
      },
      {
        "<leader>lF",
        function()
          require("conform").format { formatters = { "injected" }, timeout_ms = 3000 }
        end,
        mode = { "n", "v" },
        desc = "LSP: Format injected languages",
      },
    },
    opts = function()
      local lang = require "core.lang"
      return {
        formatters_by_ft = lang.collect.formatters_by_ft(),
        formatters = lang.collect.formatters(),
        -- When conform has a formatter for the filetype only conform runs (the
        -- unavailable ones are skipped); LSP formatting is the fallback for
        -- filetypes without one.
        default_format_opts = { lsp_format = "fallback" },
        -- A function, so it is evaluated on every write: <leader>uf / <leader>uF
        -- (core.settings + vim.b.autoformat) take effect immediately.
        format_on_save = function(buf)
          local settings = require "core.settings"
          if not settings.get "format.on_save" or vim.b[buf].autoformat == false then
            return
          end
          return { timeout_ms = settings.get "format.timeout_ms" }
        end,
      }
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require "core.lang.lint"
      lint.apply()
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("core_lint", { clear = true }),
        callback = function()
          lint.try()
        end,
      })
      -- The event that lazy-loaded the plugin is consumed before config runs.
      lint.try()
    end,
  },
}
