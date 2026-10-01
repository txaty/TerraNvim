<p align="center">
  <img src="docs/assets/logo.png" alt="TerraNvim logo" width="320">
</p>

<h1 align="center">TerraNvim</h1>

<p align="center">
  A down-to-earth Neovim distribution: fast, modular, and ready for everyday work.
</p>

<p align="center">
  <a href="https://neovim.io"><img src="https://img.shields.io/badge/Neovim-0.12%2B-57A143?logo=neovim&logoColor=white" alt="Neovim 0.12+"></a>
  <img src="https://img.shields.io/badge/Made%20with-Lua-2C2D72?logo=lua&logoColor=white" alt="Made with Lua">
  <img src="https://img.shields.io/badge/startup-~25%20ms-3ddc97" alt="Startup about 25 ms">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/txaty/TerraNvim" alt="MIT license"></a>
</p>

TerraNvim is a Neovim configuration you can use as a complete IDE-like setup
or as a base for your own. Languages come as **language packs**: one data file
per language that you switch on with `:LangEnable`. Nothing language-specific
is hard-wired, and startup stays around 25 ms.

- **Language packs** for Lua, Bash, JSON, YAML, TOML, Markdown, Docker,
  C/C++ (embedded-ready), Go, Python, Rust, TypeScript/JavaScript, HTML/CSS,
  Swift, Kotlin, Solidity, LaTeX and Typst. Each pack bundles LSP, formatting,
  linting, debugging, tests and keymaps. Adding a language is one file
  ([docs/languages.md](docs/languages.md)).
- **Batteries on, switchable**: language servers start automatically,
  formatting and linting run on save, and missing tools for enabled languages
  install on first use. Every behaviour is a setting, and most are toggles.
- **Modern stack**: lazy.nvim, snacks.nvim (picker, explorer, terminal,
  lazygit, dashboard), blink.cmp, `vim.lsp.config` with nvim-lspconfig as
  data, conform, nvim-lint, nvim-treesitter (main), nvim-dap, neotest,
  diffview-plus, gitsigns, noice, which-key, flash, trouble.
- **AI, opt-in**: Claude Code integration (claudecode.nvim) and a terminal for
  any AI CLI (sidekick.nvim). Both stay off until you enable them.
- **Neovim 0.12 native** where it is good enough: default LSP keymaps,
  incremental selection, `:restart`, `:Undotree`, `winborder`, EditorConfig.
- **Hardened defaults**: no modelines, no project-local config execution,
  pinned plugins, writes only under Neovim's own data directories.

## Requirements

- Neovim **0.12+**, git, a C compiler, [`tree-sitter` CLI](https://github.com/tree-sitter/tree-sitter)
  ≥ 0.26.1 (builds parsers), `rg` and `fd`.
- Optional: `lazygit`, a [Nerd Font](https://www.nerdfonts.com/), and per
  language the toolchain itself (`go`, `cargo`, `node`, Xcode, JDK 17+, ...).
  Language servers and tools come from Mason automatically.

## Install

```sh
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null   # keep an existing config
git clone https://github.com/txaty/TerraNvim ~/.config/nvim
nvim    # lazy.nvim bootstraps itself and installs the pinned plugins
```

To try it next to your current config, use a separate app name (it keeps its
own config, plugins and state):

```sh
git clone https://github.com/txaty/TerraNvim ~/.config/terranvim
NVIM_APPNAME=terranvim nvim
```

Then in Neovim:

1. `<leader>Lp` (Space, L, p): enable the languages you use.
2. Open a file of each. Tools install in the background, and the server
   attaches when its install finishes.
3. `:checkhealth core.lang`: see what each enabled language has.

Setting up a machine non-interactively:

```sh
nvim --headless "+Lazy! restore" +qa
nvim --headless "+LangEnable go python rust typescript" "+LangInstall!" +qa
```

## Languages

| Command | |
|---|---|
| `<leader>Lp` / `:LangPanel` | Enable/disable, install, options |
| `:LangEnable` / `:LangDisable` / `:LangToggle {pack...}` | Persisted per machine |
| `:LangOption {pack} {option} {value}` | e.g. `typescript server tsc`, `python server pyright`, `cpp query_driver /opt/homebrew/bin/arm-none-eabi-*` |
| `:LangInstall[!] [pack...]` | Install Mason tools and parsers now |
| `:checkhealth core.lang` / `<leader>Lh` | Per-pack status |

Enabled on a fresh install: lua, bash, json, yaml, toml, markdown. The full
table, the schema and a walkthrough for adding a language are in
**[docs/languages.md](docs/languages.md)**.

## Configuration

Settings live in [`lua/core/settings.lua`](lua/core/settings.lua). Override
them in `lua/user/settings.lua` (gitignored; copy
[`lua/user/settings.example.lua`](lua/user/settings.example.lua)):

```lua
return {
  format = { on_save = false },
  langs = { default = { "lua", "go", "python" }, options = { typescript = { server = "tsc" } } },
  theme = { dark = "kanagawa-wave", light = "kanagawa-lotus" },
}
```

| Setting | Default | |
|---|---|---|
| `lsp.auto_start` | `true` | Start servers of enabled packs |
| `format.on_save` / `format.timeout_ms` | `true` / `1000` | Toggle at runtime: `<leader>uf`, per buffer `<leader>uF` |
| `lint.enabled` | `true` | Toggle: `<leader>ul` |
| `install.auto` | `true` | Install missing tools/parsers of enabled packs on first use |
| `langs.default` / `langs.options` / `langs.hint_disabled` | see above | Fresh-install packs, per-pack option defaults, hint for disabled packs |
| `session.persistence` | `true` | Default for `:SessionToggle` (per-directory sessions) |
| `ai.enabled` | `false` | Default for `:AIToggle` |
| `cleanup.auto` | `false` | Daily sweep of stale logs/swap/undo/views (`:CleanupNvim` anytime) |
| `editorconfig` | `true` | Honour `.editorconfig` |
| `theme.dark` / `theme.light` | `catppuccin-mocha` / `catppuccin-latte` | Fallbacks for `<leader>cd` / `<leader>cl` |

Your own plugins go in `lua/user/plugins/*.lua` (lazy.nvim specs). Your own
language packs go in `lua/user/langs/*.lua`.

## Using it

Press `<leader>` (Space) and wait: which-key shows everything, including
language-specific keys in buffers of that language. Highlights:

| Key | | Key | |
|---|---|---|---|
| `<leader>ff` / `fg` | Find files / grep | `<C-n>` | Explorer |
| `s` | Flash jump | `<C-\>` | Terminal (your `$SHELL`) |
| `gd`, `grr`, `gri`, `grn`, `gra`, `K` | LSP (Neovim defaults) | `<leader>lf` | Format |
| `<leader>gg` | lazygit | `<leader>gvo` | Diffview |
| `<leader>db` / `dc` | Breakpoint / debug | `<leader>tn` | Nearest test |
| `<leader>cc` | Theme picker | `<leader>qr` | `:restart` |

The full reference is **[docs/keymaps.md](docs/keymaps.md)**, which also lists what
changed in the 2026-10 modernization.

### AI

`<leader>ai` (or `:AIEnable`) and accept the restart prompt. Then:

- **Claude Code** (`<leader>ac`): runs the `claude` CLI in a split, connected
  over Claude Code's IDE protocol. Claude sees your selection and open files,
  and its edits open as diffs: `<leader>aa` accepts, `<leader>ad` rejects.
- **sidekick** (`<C-.>`, `<leader>ak`): a persistent terminal for any AI CLI
  (claude, codex, gemini, ...) with helpers to send the current
  file/selection/diagnostics.

### Themes

37 themes: 12 maintained plugins, each with dark and light variants, and the
built-in low-saturation **txaty** pair. `<leader>cc` opens a picker with
live preview; `<leader>cd` / `<leader>cl` switch to your last dark / light
theme. The choice persists, including themes set with a plain `:colorscheme`.

### Remote editing

distant.nvim was removed (unmaintained). Neovim 0.12 can attach your local UI
to a Neovim running on another machine. Use Unix sockets in private
directories: a TCP `--listen` port is unauthenticated and lets any local user
on either machine run code as you.

```sh
# on the host
mkdir -p -m 700 ~/.cache/nvim-remote
nvim --headless --listen ~/.cache/nvim-remote/nvim.sock
# locally: forward the socket, then attach with :connect
mkdir -p -m 700 ~/.cache/nvim-remote
ssh -N -L ~/.cache/nvim-remote/host.sock:/home/you/.cache/nvim-remote/nvim.sock host
nvim "+connect $HOME/.cache/nvim-remote/host.sock"
```

Mounting with sshfs also works.

## Security model

- No modelines, no `.nvim.lua`/`.exrc` execution (`exrc=false`, `secure`).
- `'shell'` is pinned to `/bin/sh` for `:!` and plugins; interactive
  terminals use your `$SHELL` only after validating it.
- Plugins are pinned in `lazy-lock.json` and never auto-update
  (`checker.enabled = false`).
- Network access happens only on: the first start (missing plugins); first use
  of an enabled language (missing Mason tools/parsers; `install.auto = false`
  turns this off); `:Lazy`/`:Mason`/`:LangInstall`; and AI plugins once you
  enable them.
- Persisted state is written only under `stdpath("data"|"state"|"cache")`,
  never through symlinks.
- External openers (`<leader>mo`, `<leader>io`) ask before launching.

After updating plugins: review `git diff lazy-lock.json`, check new `build`
hooks, and grep the updated plugins for `os.execute`, `io.popen` and
`loadstring`.

## Maintenance

| | |
|---|---|
| `:Lazy update` | Update plugins (review and commit `lazy-lock.json`) |
| `:TSUpdate` | Update treesitter parsers |
| `:Mason` | Update tools |
| `:checkhealth` | Everything; `:checkhealth core.lang`, `vim.lsp`, `which-key`, `vim.deprecated` in particular |
| `:Lazy profile` | Startup profile |

## Development

```sh
make check   # lint (stylua + luacheck), headless smoke tests, startup budget
make fmt     # format Lua
make test    # smoke tests with default, all and no language packs
```

`scripts/smoke.sh` starts this checkout headlessly with isolated state and
checks:

- startup is free of errors;
- every language pack is valid;
- enabled packs register their servers, formatters, linters, DAP configs and
  keymaps;
- nothing writes to the lockfile or persisted state.

Contributor and coding-agent notes are in [AGENTS.md](AGENTS.md);
[CHANGELOG.md](CHANGELOG.md) records notable changes.

## Credits

Ideas borrowed from [LazyVim](https://www.lazyvim.org/),
[AstroNvim](https://astronvim.com/), [NvChad](https://nvchad.com/) and
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). MIT licensed.
