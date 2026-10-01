-- HTML and CSS (with Tailwind and Emmet). JS/TS live in the typescript pack.
return {
  title = "Web",
  description = "html, cssls, tailwindcss, emmet, prettier, auto-close tags",
  filetypes = { "html", "css", "scss", "less" },
  grep_type = "html",
  parsers = { "html", "css", "scss" },
  -- Node-based servers have a pinned cmd: nvim-lspconfig's default prefers the
  -- project's node_modules/.bin copy, i.e. a binary shipped by the repository.
  servers = {
    html = { mason = "html-lsp", cmd = { "vscode-html-language-server", "--stdio" } },
    cssls = { mason = "css-lsp", cmd = { "vscode-css-language-server", "--stdio" } },
    -- Loads the project's tailwind.config.js, so only in trusted projects
    -- (core.trust); it also only attaches where Tailwind is configured.
    tailwindcss = {
      mason = "tailwindcss-language-server",
      cmd = { "tailwindcss-language-server", "--stdio" },
      trust = true,
    },
    emmet_language_server = { mason = "emmet-language-server" },
  },
  tools = { "prettierd" },
  formatters = function()
    -- prettier loads JS configs/plugins from the project: trusted projects only
    -- (elsewhere the LSP formats).
    local trust = require "core.trust"
    return {
      prettier = { command = trust.node_bin "prettier", condition = trust.formatter_condition "prettier" },
      prettierd = { condition = trust.formatter_condition "prettier" },
    }
  end,
  formatters_by_ft = {
    html = { "prettierd", "prettier", stop_after_first = true },
    css = { "prettierd", "prettier", stop_after_first = true },
    scss = { "prettierd", "prettier", stop_after_first = true },
    less = { "prettierd", "prettier", stop_after_first = true },
  },
  plugins = {
    {
      "windwp/nvim-ts-autotag",
      ft = { "html", "xml", "javascriptreact", "typescriptreact", "vue", "svelte", "astro", "markdown" },
      opts = {},
    },
  },
}
