return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    -- Loads on InsertEnter, or earlier as a dependency of nvim-lspconfig (first
    -- file opened) so its plugin/ file registers LSP completion capabilities
    -- before any server starts.
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = function()
      local packs = require("core.lang").collect.cmp()
      return {
        keymap = {
          preset = "none",
          ["<C-k>"] = { "select_prev", "fallback" },
          ["<C-j>"] = { "select_next", "fallback" },
          ["<C-b>"] = { "scroll_documentation_up", "fallback" },
          ["<C-f>"] = { "scroll_documentation_down", "fallback" },
          ["<C-Space>"] = { "show" },
          ["<C-e>"] = { "cancel", "fallback" },
          ["<CR>"] = { "accept", "fallback" },
          ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
          ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        },
        completion = {
          documentation = { auto_show = true, auto_show_delay_ms = 200 },
          list = { selection = { preselect = false, auto_insert = false } },
        },
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
          -- Language packs add providers per filetype (e.g. lazydev for lua).
          providers = packs.providers,
          per_filetype = packs.per_filetype,
        },
        signature = { enabled = false }, -- let noice.nvim handle signature help
      }
    end,
  },
}
