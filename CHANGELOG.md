# Changelog

All notable user-facing changes to this Neovim configuration are documented
here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Entries are written for humans — read them for *what changed and why it
matters*, not for a reproduction of the git history. For the full commit-level
record, use `git log`.

## [Unreleased]

The config becomes a general-purpose distribution, **TerraNvim** (the
repository moved from `txaty/nvim-config` to `txaty/TerraNvim`; GitHub
redirects the old URL). Language support is data-driven, defaults are
"batteries on", and stale plugins are replaced. Requires **Neovim 0.12**.

### Added

- **Language packs** (`lua/langs/*.lua`): one data file per language
  declaring filetypes, parsers, servers, Mason tools, formatters, linters,
  DAP, tests, plugins and buffer-local keymaps. Shipped: lua, bash, json,
  yaml, toml, markdown (on by default), docker, cpp (embedded-ready, with a
  remote GDB server debug config), go, python, rust, typescript, web, swift,
  kotlin, solidity, latex, typst. Manage with `<leader>Lp` / `:LangPanel`,
  `:LangEnable`, `:LangOption`, `:LangInstall[!]`, `:checkhealth core.lang`.
  See docs/languages.md.
- Missing Mason tools and treesitter parsers of enabled packs install on
  first use (`install.auto`); servers attach when their install finishes.
- `lua/core/settings.lua` with an optional, gitignored `lua/user/` layer
  (`settings.lua`, `plugins/`, `langs/`).
- Runtime toggles: `<leader>uf` / `<leader>uF` format on save (global /
  buffer), `<leader>ul` lint, `<leader>uh` inlay hints, `<leader>uu` the
  built-in undo tree. `<leader>qr` runs `:restart`, which is also offered
  after changes that need it.
- AI: claudecode.nvim (Claude Code IDE integration) and sidekick.nvim (any AI
  CLI), behind the existing AI toggle.
- `:colorscheme txaty` / `txaty-light`; the theme picker filters by
  `dark`/`light` and previews live.
- `make check` (stylua, luacheck, headless smoke tests in three language
  modes, startup budget); AGENTS.md for contributors and coding agents.

### Changed

- LSP servers now start automatically, and format-on-save and linting are on
  (all switchable). The old `vim.g.enable_*` flags were never set, so all of
  this was silently off.
- Servers start because an enabled pack declares them, not because Mason
  has them installed. Non-Mason servers (sourcekit-lsp) work, and disabled
  packs stay quiet.
- Explorer: nvim-tree → snacks.explorer; it no longer opens automatically
  next to files (`nvim <dir>` still opens it, and changes into `<dir>`).
- Terminal: toggleterm → Snacks.terminal, which uses your `$SHELL`
  (`<C-\>` or `<C-/>` toggles, `<C-/>` hides from inside, `<Esc><Esc>` for
  Normal mode).
- lazygit.nvim → Snacks.lazygit, diffview.nvim → diffview-plus.nvim
  (maintained fork), telescope removed (snacks picker everywhere).
- Python: basedpyright + ruff (format, imports, lint). TypeScript: vtsls or
  TypeScript 7 `tsc`, Biome or prettier per project, js-debug-adapter
  directly. Go: gofumpt, golangci-lint v2, neotest-golang. Rust:
  rustaceanvim 9 and its neotest adapter.
- Themes curated to 12 maintained plugins (37 themes incl. txaty).
- LSP keymaps follow Neovim's defaults (`grr`, `gri`, `grt`, `grn`, `gra`);
  Glance moves to `<leader>lp*`; parameter motions to `],`/`[,`;
  language keymaps are buffer-local. See docs/keymaps.md, "Changed in the
  2026-10 modernization".
- EditorConfig is honoured (Neovim built-in); `winborder` is rounded.

### Removed

- Flutter/Dart support, distant.nvim, git-conflict.nvim, copilot.lua,
  CopilotChat.nvim, avante.nvim, telescope.nvim, toggleterm.nvim,
  lazygit.nvim, nvim-tree.lua, mason-lspconfig, mason-conform,
  mason-nvim-lint, mason-nvim-dap, nvim-dap-vscode-js, neotest-go,
  neotest-rust and 17 theme plugins.
- The keymap audit (use `:checkhealth which-key`), the fallback word
  highlighter (snacks.words) and the NvChad cleanup sweep.
- CLAUDE.md and GEMINI.md: AGENTS.md is the single instructions file
  (Claude Code reads it natively; Gemini CLI via `.gemini/settings.json`).

### Fixed

- Treesitter parsers and Mason tools were never installed automatically:
  nvim-treesitter's main branch ignores `ensure_installed`, and Mason has no
  such option.
- mason-nvim-lint installed nvim-lint's default linters (vale, jsonlint,
  hadolint, tflint) and nvim-lint ran them; only pack linters run now.
- DAP configurations were missing for buffers opened before nvim-dap loaded.
- Disabling a language dropped its plugins from `lazy-lock.json`; they are
  now kept with `cond = false`.
- overseer commands broken by its v2 API; refactoring.nvim maps that never
  ran a refactor (missing `expr`); theme switching discarded colorscheme
  options and saved the wrong variant; flash changed `f`/`t` after the first
  jump; UI toggles leaked into floating windows and unwrapped prose; `]c`
  broke diff navigation; mini.ai shadowed native `an`/`in`.

---

## 2026-08

Refactors that landed between the April snapshot and the modernization.
The theme accessors and lifecycle notes below are superseded by [Unreleased].

### Added

- The custom **txaty** theme is now split into three focused files so that
  editing colors no longer means scrolling past a thousand highlight rules.
  Edit `lua/core/theme_txaty_colors.lua` to tune palette hex values, and
  `lua/core/theme_txaty_highlights.lua` to adjust highlight group
  assignments. The public API (`apply(variant)`, `get_palette(variant)`) is
  unchanged.
- The theme registry exposes two explicit accessors — `get_themes()` and
  `get_theme_info()` — with clear lazy initialization. The existing
  `M.themes` and `M.theme_info` field access still works for backward
  compatibility, so no call sites need updating.

### Changed

- The VimEnter lifecycle is now driven by a declarative `steps` table in
  `lua/core/lifecycle/init.lua`. Each step declares its timing mode
  (immediate, scheduled, very-lazy, or deferred) and any gating conditions
  in one place, instead of being woven through imperative control flow.
  Adding or removing a startup step is now a one-line change to the table.
  Observable behavior is identical to before.

### Fixed

- Corrupted JSON configuration files (for example, a partially written
  `ui_config.json` after a crash) now produce a visible warning instead of
  silently reverting to defaults — the user sees why settings aren't being
  remembered.
- File-cleanup failures during `:CleanupNvim` and startup cleanup are now
  accumulated and reported. Previously a permission error on a single log
  file would be swallowed with no indication; now the failure count and
  details surface through `vim.notify`.
- The `LangPanel` UI is noticeably snappier on repeat opens because the
  language-enabled state is cached in memory instead of being re-read from
  disk on every per-language query.

---

## 2026-04-12

Documented here as the prior stable snapshot before the unreleased work
above. Dates reflect when the work landed on `main`.

### Added

- Automatic `lazy.nvim` bootstrap on first run, with explicit user opt-in
  so nothing is fetched silently.
- `snacks.bufdelete` integration and `scope.nvim` for tab-scoped buffers.
- Multicursor support and a more informative diagnostics UI.
- Breadcrumb navigation via `dropbar.nvim` (replacing `nvim-navic`), plus
  several LSP and UI quality-of-life plugins.

### Changed

- UI and DAP plugin surface area consolidated; a handful of redundant
  plugins were removed.
- Autocmd bootstrap split into focused modules under `core/autocmds/`,
  one per concern (filetype, cursor, word highlighting, persistence, UI
  state) — easier to read and reason about.
- Shell configuration simplified to read the `SHELL` environment variable
  directly rather than maintaining its own mapping.
- Cursor animation responsiveness increased; inline git blame is now off
  by default to avoid steady cursor-hold work, and can be re-enabled with
  `<leader>gB`.
- Fallback word-highlighting now caches LSP `documentHighlight` support
  per buffer, avoiding repeated client scans on every `CursorHold`.
- The `diffview` file panel now uses a list-style layout.

### Fixed

- Treesitter now tracks its `main` branch. The old `master` branch ships a
  `query_predicates.lua` that's incompatible with Neovim 0.12's match
  table format (arrays of nodes instead of single nodes) and produced
  cryptic `conceal_line` errors. The `main` branch removes that file and
  resolves the crash. **Requires Neovim 0.11+; 0.12 recommended.**

### Security

- Hardened Neovim startup defaults: `modeline=false`, `exrc=false`,
  `secure=true`, shell pinned to an explicit binary path, and legacy
  surfaces (`netrw`, `rplugin`, `spellfile`, `editorconfig`) disabled.
  Automatic behaviors that previously ran silently at startup — session
  restore, cleanup, LSP startup, format-on-save, lint-on-write, AI
  integrations — are now off by default and require an explicit opt-in
  via `vim.g.enable_*` flags. See README.md for the full list.

---

## Migration notes

### Editing the custom txaty theme

Colors and highlight group definitions now live in separate files. The
entry point (`theme_txaty.lua`) and its public API are unchanged, so
existing callers don't need any updates.

| You want to change | Edit this file |
| --- | --- |
| A palette color (hex value) | `lua/core/theme_txaty_colors.lua` |
| A highlight group assignment | `lua/core/theme_txaty_highlights.lua` |
| How the theme is wired up | `lua/core/theme_txaty.lua` |

### Adding a startup step

Open `lua/core/lifecycle/init.lua` and add an entry to the `steps` table.
The table is processed in order; each entry looks like:

```lua
{
  name = "my_step",
  mode = "deferred",       -- "sync" | "scheduled" | "very_lazy" | "deferred"
  delay_ms = 500,          -- only meaningful when mode = "deferred"
  condition = function() return vim.g.my_feature end,  -- optional gate
  needs_session = false,   -- optional: skip when no session was restored
  fn = function(ctx) ... end,
}
```

There is no imperative `run_sequence()` wiring to update.

### Language support after the modernization

Your `language_config.json` is migrated on first start. A language you never
toggled stays enabled, `web` becomes `typescript` + `web`, and `flutter` is
dropped. Enable new packs with `:LangEnable swift solidity` (or
`<leader>Lp`), then let the first file install the tools, or run
`:LangInstall`.

### Opting out of the new defaults

Create `lua/user/settings.lua`:

```lua
return {
  lsp = { auto_start = false },
  format = { on_save = false },
  lint = { enabled = false },
  install = { auto = false },
}
```

The `vim.g.enable_*` flags no longer exist.
