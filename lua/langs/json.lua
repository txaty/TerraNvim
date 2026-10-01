-- JSON with schemas from SchemaStore (package.json, tsconfig, GitHub configs, ...).
return {
  title = "JSON",
  description = "jsonls with SchemaStore schemas",
  filetypes = { "json", "jsonc", "json5" },
  grep_type = "json",
  parsers = { "json", "json5" },
  servers = {
    jsonls = {
      mason = "json-lsp",
      -- Pinned: nvim-lspconfig's default prefers <root>/node_modules/.bin, which
      -- would run a binary shipped by whatever repository is open.
      cmd = { "vscode-json-language-server", "--stdio" },
      settings = { json = { validate = { enable = true } } },
      before_init = function(_, config)
        config.settings.json.schemas = require("schemastore").json.schemas()
      end,
    },
  },
}
