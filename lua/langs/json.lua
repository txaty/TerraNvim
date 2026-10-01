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
      settings = { json = { validate = { enable = true } } },
      before_init = function(_, config)
        config.settings.json.schemas = require("schemastore").json.schemas()
      end,
    },
  },
}
