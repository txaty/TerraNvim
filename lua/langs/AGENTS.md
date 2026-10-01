# Language packs (lua/langs/)

One file per language; the file name is the pack id. The full schema and
examples are in docs/languages.md; the validator is lua/core/lang/schema.lua.

## Writing or changing a pack

- Return a plain table. No top-level `require(...)` or `vim.*` (the smoke
  test loads each file in a sandbox and fails on it); put that work inside
  functions (`servers = function(o) ... end`, `dap = function(dap, o) ... end`,
  key callbacks).
- Required: `title`, `description`, `filetypes`. Each filetype, server and
  plugin belongs to exactly one pack.
- Servers are keyed by their vim.lsp config name (nvim-lspconfig's `lsp/`
  directory) and must set `mason = "<package>"` or `mason = false` (system
  binary, e.g. sourcekit-lsp). Only add `cmd`/`filetypes`/`settings` that
  differ from nvim-lspconfig. Use `enabled = o.option == "x"` for variants and
  declare variants in `options` (`{ default, choices, desc }`).
- Formatters/linters must be names conform/nvim-lint know. Prefer project
  detection over options (`vim.fs.root(buf, { "biome.json" })`) and
  `linters.<name>.condition` so tools only run where the project uses them.
- `plugins` are lazy.nvim specs owned by the pack; give them a narrow trigger
  (`ft`, `cmd`, `event = "BufRead Cargo.toml"`). Never list a shared plugin
  (see `BASE_PLUGINS` in schema.lua). List pack-only dependencies as pack
  plugins too.
- `keys` are buffer-local on the pack's filetypes (`ft` to target others,
  `cond = function(buf) ... end` to narrow). Every key needs a `desc`. Add a
  `{ "<leader>x", group = "Name" }` entry for a new prefix, and document the
  keys in docs/keymaps.md.

## Checklist

1. Verify names: Mason package (`:Mason` or the registry JSON under
   `stdpath("data")/mason/registries`), lspconfig config file, conform/nvim-lint
   formatter and linter files, nvim-treesitter parser name.
2. If the pack adds plugins, install them with every pack enabled so the
   lockfile gets their entries:
   `NVIM_LANGS=all nvim --headless "+Lazy! install" +qa`.
3. `make test` (all modes must pass) and `scripts/smoke.sh <pack>`.
4. Open a real file with the pack enabled and check `:checkhealth core.lang`
   and `:checkhealth vim.lsp`.
5. Update the pack table in docs/languages.md (and README.md if the shipped
   list changes) and add a CHANGELOG.md entry.
