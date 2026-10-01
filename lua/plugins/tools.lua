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
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
      -- Formatter priority: when conform has a formatter for the filetype only
      -- conform runs; LSP formatting is the fallback for filetypes without one.
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
      local lint = require "lint"

      lint.linters_by_ft = {
        lua = { "luacheck" },
      }

      local function try_lint()
        if not require("core.settings").get "lint.enabled" or vim.b.lint == false then
          return
        end
        -- ignore_errors: linting is on by default, so a linter that is not
        -- installed must not raise an error on every save.
        lint.try_lint(nil, { ignore_errors = true })
      end

      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("lint", { clear = true }),
        callback = try_lint,
      })

      -- The event that lazy-loaded this plugin is consumed before config runs,
      -- so lint the triggering buffer now or the first save is missed.
      try_lint()
    end,
  },
}
