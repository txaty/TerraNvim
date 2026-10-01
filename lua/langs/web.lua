-- HTML and CSS (with Tailwind and Emmet). JS/TS live in the typescript pack.
return {
  title = "Web",
  description = "html, cssls, tailwindcss, emmet, prettier, auto-close tags",
  filetypes = { "html", "css", "scss", "less" },
  grep_type = "html",
  parsers = { "html", "css", "scss" },
  servers = {
    html = { mason = "html-lsp" },
    cssls = { mason = "css-lsp" },
    -- Attaches only in projects with a Tailwind config / dependency.
    tailwindcss = { mason = "tailwindcss-language-server" },
    emmet_language_server = { mason = "emmet-language-server" },
  },
  tools = { "prettierd" },
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
