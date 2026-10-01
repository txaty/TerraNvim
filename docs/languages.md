# Language packs

Everything language-specific lives in one data file per language:
`lua/langs/<name>.lua`. A pack declares its filetypes, treesitter parsers,
language servers, Mason tools, formatters, linters, debugger setup, test
adapter, plugins and buffer-local keymaps. The shared plugins (nvim-lspconfig,
conform, nvim-lint, nvim-treesitter, nvim-dap, neotest, blink.cmp, which-key)
read the **enabled** packs when they load. Nothing else in the config knows
about individual languages.

## Using packs

| Command / key | What it does |
|---|---|
| `<leader>Lp`, `:LangPanel` | Panel: `<CR>` toggle, `<C-x>` install, `<C-o>` options, `<C-r>` restart |
| `:LangEnable {pack...}` / `:LangDisable` / `:LangToggle` | Change and persist the enabled set |
| `:LangStatus [pack]`, `<leader>Ls` | What is enabled and what still needs installing |
| `:LangInstall[!] [pack...]` | Install Mason tools and parsers (`!` waits; for scripts) |
| `:LangOption {pack} {option} {value}` | Pick a variant, e.g. `:LangOption typescript server tsc` |
| `:LangInfo`, `:checkhealth core.lang` | Servers, tools and parsers per enabled pack |

- **Defaults.** A fresh install enables `lua bash json yaml toml markdown`
  (`langs.default` in `lua/core/settings.lua`). Your choices are stored per
  machine in `stdpath("data")/language_config.json`.
- **Hint.** Opening a file that belongs to a disabled pack shows a one-time
  hint to enable it.
- **Installs.** With `install.auto` (the default), the first file of an enabled
  pack you open installs that pack's missing Mason packages and parsers in the
  background. This only happens with a UI attached, never in headless or test
  runs. Language servers start as soon as their package is installed.
- **Restarts.** Enabling a pack applies servers, formatters, linters, DAP
  configs and keymaps immediately. Plugins a pack owns (rustaceanvim, vimtex,
  ...) and test adapters need a restart, which is offered (`:restart`).
- **CI / new machine.**
  ```sh
  NVIM_LANGS=all nvim --headless "+LangInstall!" +qa
  ```
  `$NVIM_LANGS` (`all`, `none`, `default` or `a,b,c`) overrides the enabled
  set without persisting it.

## Shipped packs

| Pack | Servers | Format / lint | Debug / test / extras |
|---|---|---|---|
| `lua` | lua_ls | stylua · luacheck (with `.luacheckrc`) | lazydev |
| `bash` | bashls (+shellcheck) | shfmt | |
| `json` / `yaml` / `toml` | jsonls / yamlls (SchemaStore) / taplo | LSP | |
| `markdown` | marksman | options: prettier, markdownlint | render-markdown, `<leader>m*` |
| `docker` | dockerls, compose LS | hadolint | compose filetype detection |
| `cpp` | clangd, neocmakelsp | clang-format | codelldb: launch, attach, **remote GDB server** (OpenOCD / J-Link / QEMU); option `query_driver` for cross compilers |
| `go` | gopls (gofumpt, staticcheck) | goimports + gofumpt · golangci-lint | delve · neotest-golang (gotestsum) |
| `python` | basedpyright (option: pyright) + ruff | ruff | debugpy · neotest-python · venv-selector |
| `rust` | rust-analyzer via rustaceanvim | rustfmt · clippy | codelldb · rustaceanvim neotest · crates.nvim |
| `typescript` | vtsls (option: TypeScript 7 `tsc`), eslint, biome | biome with `biome.json`, else prettier | js-debug-adapter · vitest / jest |
| `web` | html, cssls, tailwindcss, emmet | prettier | auto-close tags |
| `swift` | sourcekit-lsp (Xcode, not Mason) | swiftformat with `.swiftformat`, else `swift format` · swiftlint | lldb-dap · xcodebuild.nvim (macOS) |
| `kotlin` | kotlin-lsp (JetBrains) | ktlint (option: ktfmt) | |
| `solidity` | Nomic Foundation solidity LS | `forge fmt` in Foundry projects · solhint (with config) | |
| `latex` | texlab | tex-fmt (option: latexindent) | vimtex (Skim / zathura / Sumatra) |
| `typst` | tinymist | typstyle (via tinymist) | typst-preview |

## Pack schema

A pack is a file returning a table. Keep the file **data only**: no
`require()` or `vim.*` calls at the top level (the smoke test enforces it).
Every pack is read at startup, so lazy.nvim can keep all pack plugins in the
lockfile. Put work inside functions; they run when the consuming plugin loads.
`parsers`, `servers`, `tools`, `formatters_by_ft`, `formatters`,
`linters_by_ft`, `linters`, `cmp`, `keys` and `ft_options` may also be a
function `fun(o)` that receives the pack's resolved options.

```lua
-- lua/langs/zig.lua
return {
  title = "Zig",                       -- display name
  description = "zls, zig fmt",        -- one line for :LangPanel
  filetypes = { "zig", "zon" },        -- owned filetypes (one owner each)
  grep_type = "zig",                   -- ripgrep --type for <leader>fT
  options = {                          -- variants, chosen with :LangOption
    -- fmt = { default = "zig", choices = { "zig" }, desc = "Formatter" },
  },
  parsers = { "zig" },                 -- nvim-treesitter parsers
  servers = {                          -- keys are vim.lsp config names
    zls = {
      mason = "zls",                   -- required: Mason package, or false for system servers
      -- enabled = function(o) ... end, -- variant/platform switch
      -- managed_by = "plugin",         -- configured by a plugin, never enabled here
      settings = { zls = { enable_inlay_hints = true } }, -- vim.lsp.Config fields
    },
  },
  tools = {},                          -- extra Mason packages (formatters, debuggers)
  formatters_by_ft = { zig = { "zigfmt" } }, -- conform.nvim; values may be fun(buf)
  -- formatters = { ... },             -- conform formatter overrides
  -- linters_by_ft = { zig = { ... } },-- nvim-lint
  -- linters = { name = { condition = function(ctx) ... end } },
  -- dap = function(dap, o) dap.adapters.x = ...; dap.configurations.zig = ... end,
  -- test = { adapter = function(o) return require "neotest-zig" {} end },
  -- cmp = { providers = { ... }, per_filetype = { zig = { inherit_defaults = true, "x" } } },
  -- ts_highlight = { zig = false },   -- disable treesitter highlighting for a filetype
  -- filetype_add = { extension = { zon = "zon" } }, -- vim.filetype.add() when enabled
  -- ft_options = { zig = { shiftwidth = 4 } },      -- buffer options per filetype
  plugins = {},                        -- lazy.nvim specs this pack owns (cond injected)
  keys = {                             -- buffer-local, on the pack's filetypes
    -- { "<leader>z", group = "Zig" },
    -- { "<leader>zb", "<cmd>!zig build<cr>", desc = "Zig: build" },
    -- `ft` targets other filetypes, `cond = fun(buf)` narrows further
  },
}
```

Rules the validator enforces (`make test`, `:checkhealth core.lang`):

- `name`, if set, equals the file name; `title`, `description` and `filetypes`
  are required.
- Each filetype, server and plugin has exactly one owning pack.
- Every server sets `mason` explicitly (`false` for system-provided servers).
- Keys have a `desc` (or are a `group`).
- `plugins` never lists a shared plugin (lspconfig, conform, nvim-lint,
  nvim-dap, neotest, treesitter, which-key, snacks, mason, blink, plenary,
  SchemaStore). A spec fragment with the injected `cond` would disable it
  for everyone. Dependencies only a pack uses must be listed in its
  `plugins` too, so they get the same `cond`.
- Mason package and parser names exist; formatters and linters are known to
  conform / nvim-lint.

## Adding a language

1. Create `lua/langs/<name>.lua` (or `lua/user/langs/<name>.lua` to keep it
   out of the repo; a user pack with a shipped name replaces the shipped one).
2. Find the server's config name in nvim-lspconfig's `lsp/` directory and the
   Mason package name with `:Mason`.
3. `make test`: the smoke test validates the pack and loads it in `all` mode.
4. `:LangEnable <name>`, open a file, then check `:checkhealth core.lang`.
5. Document new keymaps in `docs/keymaps.md`.

## How it works

| Module | Role |
|---|---|
| `core/lang/init.lua` | Registry, options, collectors, `plugin_specs()` |
| `core/lang/state.lua` | Enabled set and options on disk; `$NVIM_LANGS` |
| `core/lang/lsp.lua` | `vim.lsp.config/enable` for enabled packs; tracks pending installs |
| `core/lang/install.lua` | Mason + nvim-treesitter installer |
| `core/lang/runtime.lua` | FileType dispatcher: keymaps, which-key groups, options, hints, live enable/disable |
| `core/lang/lint.lua`, `core/lang/treesitter.lua` | nvim-lint and treesitter wiring |
| `core/lang/schema.lua`, `health.lua`, `smoke.lua` | Validation, health check, test suite |

A disabled pack's plugins stay in the lazy.nvim spec with `cond = false`.
lazy.nvim then neither loads, installs nor cleans them and keeps their
`lazy-lock.json` entries, so the committed lockfile does not depend on which
packs a machine has enabled. Mason's `bin` directory is put on `PATH` at
startup (`core.lang.setup()`), so tools resolve before mason.nvim loads.
