-- Developer tools: formatting (conform.nvim) and linting (nvim-lint)
return {
  -- Formatting with conform.nvim
  {
    "stevearc/conform.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>lF",
        function()
          require("conform").format { formatters = { "injected" }, timeout_ms = 3000 }
        end,
        mode = { "n", "v" },
        desc = "LSP: Format injected languages",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
      -- FORMAT PRIORITY: lsp_fallback means LSP formatting ONLY runs if conform
      -- has NO formatter configured for the current filetype.
      --
      -- Behavior:
      --   - If conform has a formatter: ONLY conform runs (LSP skipped)
      --   - If conform has NO formatter: LSP runs (fallback)
      --
      -- This prevents double-formatting. If you want BOTH conform AND LSP to run,
      -- remove lsp_fallback and chain them manually:
      --   format_on_save = function(bufnr)
      --     vim.lsp.buf.format({ bufnr = bufnr })
      --     require("conform").format({ bufnr = bufnr })
      --   end
      format_on_save = vim.g.enable_format_on_save == true and {
        timeout_ms = 500,
        lsp_fallback = true,
      } or nil,
    },
  },
  {
    "zapling/mason-conform.nvim",
    cmd = { "Mason", "ConformInfo" },
    dependencies = { "mason-org/mason.nvim", "stevearc/conform.nvim" },
    opts = {},
  },

  -- Linting with nvim-lint
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "InsertLeave" },
    dependencies = {
      {
        "rshkarin/mason-nvim-lint",
        dependencies = { "mason-org/mason.nvim" },
        opts = {},
      },
    },
    config = function()
      if vim.g.enable_lint_on_write ~= true then
        return
      end

      local lint = require "lint"

      lint.linters_by_ft = {
        lua = { "luacheck" },
      }

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })

      -- Run lint immediately for the buffer that triggered lazy-load.
      -- The event that caused lazy.nvim to load this plugin is consumed
      -- before config runs, so without this the first save would be missed.
      lint.try_lint()
    end,
  },
}
