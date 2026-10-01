# AGENTS.md

A general-purpose Neovim 0.12 distribution (lazy.nvim, snacks.nvim,
`vim.lsp.config`). Optimised for startup time (about 25 ms headless) and for
adding languages without touching shared code. User docs: README.md,
docs/languages.md, docs/keymaps.md.

## Commands

```sh
make check     # definition of done: lint + test + startup
make lint      # stylua --check and luacheck on lua/ scripts/ colors/
make fmt       # stylua
make test      # scripts/smoke.sh default all none (headless, isolated state)
make startup   # median headless startup; warns > 30 ms, fails > 35 ms
scripts/smoke.sh python,go   # smoke with an explicit set of language packs
```

The smoke test runs this checkout (via a temporary XDG_CONFIG_HOME symlink)
with a temporary XDG_STATE_HOME. Under `vim.g.nvim_smoke` it never installs
plugins/tools or writes persisted JSON; it fails if lazy-lock.json or any
`stdpath("data")/*.json` changes. Inspect behaviour headlessly the same way.
Note that lazy.nvim only fires `VeryLazy` on UIEnter, which headless never
gets; `scripts/smoke.lua` shows how to emulate it.

## Layout and where things go

- `init.lua` → `lua/core/init.lua`: options, keymaps, `core.lang.setup()`,
  autocmds, lifecycle (VimEnter steps table), then `core/lazy.lua`.
- `lua/core/settings.lua`: every user-facing switch and its default.
  Users override it in the gitignored `lua/user/settings.lua`; read values
  with `require("core.settings").get("a.b")`. Do not add `vim.g` feature
  flags.
- `lua/plugins/*.lua`: shared plugin specs, imported by lazy.nvim. The import
  is not recursive; subdirectories need their own `{ import = ... }`.
- `lua/langs/*.lua`: language packs, the only place for language-specific
  configuration (servers, formatters, linters, DAP, tests, keymaps). See
  `lua/langs/AGENTS.md`. Shared plugins read enabled packs through
  `core.lang` collectors when they load.
- `lua/core/lang/`: pack registry, installer, LSP wiring, runtime, health,
  schema and smoke suite.
- `lua/core/theme*.lua`, `colors/`: theme registry (keys are colorscheme
  names) and the built-in txaty theme.
- There is no `lua/configs/` directory: inline plugin config in `opts` or
  `config`.

## Invariants

- **Lazy-load everything.** `defaults.lazy = true`; each spec needs `event`,
  `cmd`, `ft` or `keys`. lazy.nvim ORs triggers, so an `event` next to
  `ft`/`keys` makes them decorative; combine them only when the plugin needs
  both, and say why in a comment.
- Exceptions that load at startup: snacks.nvim (`priority = 1000`),
  nvim-treesitter (its main branch cannot be lazy-loaded), rustaceanvim and
  vimtex (both ask not to be lazy-loaded; they are pack plugins, off unless
  their pack is enabled). Colorschemes have no trigger: `core.theme` loads them.
- **Language packs:**
  - Pack files are data only, with no top-level `require`/`vim.*`; every pack
    is read at startup.
  - Packs never list shared plugins: a fragment with the injected `cond`
    would disable the plugin for everyone.
  - Disabled packs' plugins stay in the spec with `cond = false` so
    lazy-lock.json does not depend on which packs a machine enabled. Install
    new pack plugins with every pack enabled (`NVIM_LANGS=all`) before
    committing the lockfile.
- **LSP:** use `vim.lsp.config()`/`vim.lsp.enable()` (core/lang/lsp.lua), never
  `require("lspconfig")`. Don't override `cmd`/`root_dir` unless the pack
  needs to; nvim-lspconfig's `lsp/*.lua` provides them. rust-analyzer belongs
  to rustaceanvim (`managed_by`). Capabilities come from blink.cmp's
  `vim.lsp.config("*")`.
- **Keymaps:** keep Neovim's defaults (`grr gri grt grn gra grx gO K [d ]d an
  in`). Plugin keymaps go in the plugin's `keys` spec, plugin-free ones in
  `core/keymaps.lua`, language ones in the pack's `keys`. Update
  docs/keymaps.md in the same change.
- **Startup budget:** keep `make startup` under 30 ms. Do work in functions
  that run on events, not at require time.

## Security rules

- Never build commands from strings: use `vim.cmd { cmd = ..., args = {...} }`
  and `vim.system({ "cmd", arg })`. No `loadstring`, `load`, `dofile`,
  `os.execute` or `io.popen`.
- Reject shell metacharacters (`|;&$!#` backtick, newline) in user input
  passed to commands, and confirm external launches (`core.security`).
- Write files only under `stdpath("data"|"state"|"cache")`, through
  `core.persist` (refuses symlinks). Delete only with
  `safe_delete()` in `core/cleanup.lua`.
- Keep `modeline=false`, `modelines=0`, `exrc=false`, `secure=true`, and the
  pinned `'shell'`.
- Every plugin is pinned in lazy-lock.json; `checker` stays disabled. After
  `:Lazy update`, review the lockfile diff and new `build` hooks, and grep
  the updated plugins for `os.execute`, `io.popen` and `loadstring`.

## Conventions

- Lua 5.1/LuaJIT, 2-space indent, 120 columns, double quotes, no call
  parentheses for single string/table arguments (stylua enforces these).
  Use local helpers, not globals. Files are snake_case.
- Comment non-obvious code at the site: what it solves, why this approach, and
  the constraint or version that forces it (e.g. a plugin API migration or a
  Neovim version guard). Skip comments that restate the code.
- Verify plugin APIs against the installed source in
  `~/.local/share/nvim/lazy/<plugin>` rather than from memory; many plugins
  here changed APIs in 2025–2026 (overseer v2, refactoring 2.0, rustaceanvim
  9, mason v2, nvim-treesitter main).
- Commits: Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`,
  `docs:`, `test:`). Commit lazy-lock.json together with the plugin change.
  The human operator is the only author: no AI co-author trailers, and no
  mention of AI tools in commit messages or PRs.
- User-visible changes get a CHANGELOG.md entry under [Unreleased].

## Done means

1. `make check` passes, with no new smoke warnings you did not expect.
2. Keymap changes are reflected in docs/keymaps.md, and language changes in
   docs/languages.md.
3. Plugin changes come with the lockfile and a note on why the plugin is
   needed (or why it replaces another).
