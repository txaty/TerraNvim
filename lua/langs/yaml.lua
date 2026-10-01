-- YAML with schemas from SchemaStore (GitHub Actions, Kubernetes, compose, ...).
return {
  title = "YAML",
  description = "yamlls with SchemaStore schemas",
  filetypes = { "yaml" },
  grep_type = "yaml",
  parsers = { "yaml" },
  servers = {
    yamlls = {
      mason = "yaml-language-server",
      settings = {
        yaml = {
          -- yamlls' own SchemaStore download is replaced by SchemaStore.nvim's
          -- bundled catalogue (no network request, same schemas).
          schemaStore = { enable = false, url = "" },
          keyOrdering = false,
          validate = true,
        },
      },
      before_init = function(_, config)
        config.settings.yaml.schemas = require("schemastore").yaml.schemas()
      end,
    },
  },
}
