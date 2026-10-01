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
      -- Pinned (see json.lua): never the project's node_modules/.bin copy.
      cmd = { "yaml-language-server", "--stdio" },
      settings = {
        yaml = {
          -- yamlls' own SchemaStore catalogue download is replaced by
          -- SchemaStore.nvim's bundled list (individual schemas are still
          -- fetched by yamlls when a matching file is opened).
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
