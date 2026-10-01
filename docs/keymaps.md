# Keymaps

`<leader>` is **Space**. Press it and wait for which-key to see everything
available in the current buffer, including the language-specific groups that
only exist in buffers of their language. Overlapping mappings are reported by
`:checkhealth which-key`.

Neovim's own defaults are kept wherever possible, notably the LSP ones:
`K` hover, `grn` rename, `gra` code action, `grr` references,
`gri` implementation, `grt` type definition, `grx` run codelens, `gO` document
symbols, `[d`/`]d` diagnostics, `<C-w>d` diagnostic float, `<C-s>` (insert)
signature help, and `an`/`in` (visual) incremental selection.

## Groups

| Prefix | Purpose | Prefix | Purpose |
|---|---|---|---|
| `<leader>a` | AI (Claude Code, sidekick) | `<leader>n` | Messages (noice) |
| `<leader>b` | Buffers | `<leader>o` | Tasks (overseer) |
| `<leader>c` | Colorschemes | `<leader>q` | Session / quit |
| `<leader>d` | Debug (DAP) | `<leader>s` | Search / symbols |
| `<leader>f` | Find / files | `<leader>t` | Tests |
| `<leader>g` | Git (`<leader>gv` Diffview) | `<leader>T` | Terminal |
| `<leader>i` | Images / PDF (in those buffers) | `<leader>u` | UI toggles |
| `<leader>l` | LSP, format, refactor | `<leader>v` | Multi-cursor |
| `<leader>L` | Language packs | `<leader>w` | Windows |
| `<leader>m` | Markup: Markdown / LaTeX / Typst (buffer-local) | `<leader>x` | Diagnostics lists (Trouble) |

Language packs add buffer-local groups: `<leader>R` Rust, `<leader>C` Crates
(Cargo.toml), `<leader>p` Python, `<leader>X` Xcode (Swift, macOS).

## Editing and navigation

| Key | Action |
|---|---|
| `s` / `S` | Flash jump / Flash treesitter select (`r`, `R` in operator mode) |
| `f` `F` `t` `T` | Flash-enhanced char motions; press again to repeat |
| `;` | Command line (`:`) |
| `<Esc>` | Clear search highlight |
| `<Tab>` / `<S-Tab>` | Next / previous buffer |
| `<C-h/j/k/l>` | Move between windows |
| `<C-s>` | Save · `<C-c>` copy whole file |
| `jk` (insert) | Leave insert mode; `<C-h/j/k/l/b/e>` move in insert mode |
| `<C-a>` / `<C-x>` (`g<C-a>`) | Smarter increment / decrement (dial.nvim) |
| `p` `P` `[y` `]y` | Put and cycle the yank ring (yanky) |
| `ys` `ds` `cs` | Add / delete / change surroundings |
| `gc` / `gcc` | Comment (built-in, with ts-comments) |
| `<leader>j` | Split / join a code block (treesj) |
| `]f` `[f` `]F` `[F` | Next / previous function start / end |
| `]c` `[c` `]C` `[C` | Next / previous class (diff change in diff windows) |
| `],` `[,` | Next / previous parameter |
| `<leader>sa` / `<leader>sA` | Swap parameter with next / previous |
| `af` `if` `ac` `ic` `ao` `io` `aa` `ia` `at` `it` | Text objects: function, class, block, argument, tag (mini.ai) |
| `ai` `ii` / `[i` `]i` | Scope text object / jump to scope edges (snacks) |
| `]]` / `[[` | Next / previous reference of the word under the cursor |
| `<C-Up>` `<C-Down>` `gb` `gB` `<leader>va` | Multi-cursor: add above/below/next/prev match/all; `<Esc>` clears, `<left>`/`<right>` cycle |

## Find and files (`<leader>f`)

| Key | Action | Key | Action |
|---|---|---|---|
| `ff` | Files | `fg` | Live grep |
| `fG` | Grep with include/exclude globs | `fT` | Grep by file type (enabled packs) |
| `fR` | Reset grep filters | `fw` | Grep word under cursor |
| `fb` | Buffers | `fr` | Recent files |
| `f/` | Search in buffer | `fh` | Help |
| `fk` | Keymaps | `fc` | Commands |
| `fm` | Marks | `fd` | Diagnostics |
| `fs` | LSP symbols | `ft` | TODO comments |
| `fe` / `<C-n>` | Toggle explorer | `fE` | Reveal current file in explorer |
| `fy` `fY` `fN` | Yank absolute / relative path / filename | `fW` | Save |
| `fS` | Select scratch buffer | `<leader>.` | Scratch buffer |

Picker: `<C-j>`/`<C-k>` move, `<C-q>` send to quickfix, `<Esc>` close.
`<leader>S` opens search-and-replace (grug-far); `<leader>sw` searches the word
under the cursor. `<leader>H` opens the dashboard.

## LSP, formatting and refactoring (`<leader>l`)

Buffer-local once a server attaches:

| Key | Action |
|---|---|
| `gd` / `gD` | Definition / declaration |
| `<leader>la` | Code action (also visual) |
| `<leader>ls` | Signature help |
| `<leader>ld` | Line diagnostics |
| `<leader>D` | Type definition |
| `<leader>lw{a,r,l}` | Add / remove / list workspace folders |

Always available:

| Key | Action |
|---|---|
| `<leader>lr` | Rename with live preview (inc-rename) |
| `<leader>lf` | Format buffer or selection (conform; LSP fallback) |
| `<leader>lF` | Format injected languages (e.g. SQL in strings) |
| `<leader>lp{d,r,i,t}` | Peek definitions / references / implementations / type definitions (glance) |
| `<leader>lo` | Symbol outline sidebar · `<leader>ss`/`<leader>sS` jump to (workspace) symbol |
| `<leader>lb` | Pick a breadcrumb (dropbar) |
| `<leader>lg` | Generate a doc comment (neogen) |
| `<leader>le` / `<leader>lE` | Extract function / variable (operator: e.g. `<leader>leif`, or visual) |
| `<leader>li` / `<leader>lI` | Inline variable / function |
| `<leader>lR` | Refactoring menu |
| `<leader>lm` | Mason |
| `<leader>lh` | Switch source/header (C/C++ buffers) |

## Language packs (`<leader>L`)

| Key | Action |
|---|---|
| `<leader>Lp` | Panel: `<CR>` toggle, `<C-i>` install tools, `<C-o>` options, `<C-r>` restart |
| `<leader>Ls` | Status of every pack |
| `<leader>Li` | Install missing tools and parsers of enabled packs |
| `<leader>Lh` | `:checkhealth core.lang` |

Pack keymaps (buffer-local):

| Pack | Keys |
|---|---|
| Rust | `<leader>R{r,R,t,a,x,d,H,c,p,j,S}`: runnables, rerun, testables, expand macro, explain error, debuggables, hover actions, Cargo.toml, parent module, join lines, structural replace |
| Crates (Cargo.toml) | `<leader>C{v,f,d,u,A}`: versions, features, dependencies, upgrade, upgrade all |
| Python | `<leader>pv` select virtualenv |
| Swift (macOS) | `<leader>X{X,b,r,t,T,d,l,p}`: actions, build, build & run, test, test explorer, device, logs, preview |
| Markdown | `<leader>mo` open in external reader, `<leader>mr` toggle rendering |
| LaTeX | vimtex under `<leader>m`: `<leader>ml` compile, `<leader>mv` view, `<leader>me` errors, `<leader>mt` TOC, ... |
| Typst | `<leader>mp` toggle live preview |

## Git (`<leader>g`)

| Key | Action |
|---|---|
| `]h` / `[h` | Next / previous hunk; `ih` hunk text object |
| `<leader>gs` / `<leader>gr` | Stage / reset hunk (visual: selected lines) |
| `<leader>gS` / `<leader>gR` | Stage / reset buffer |
| `<leader>gu` | Undo stage hunk |
| `<leader>gp` / `<leader>gP` | Preview hunk inline / in a float |
| `<leader>gb` / `<leader>gB` | Blame line / toggle inline blame |
| `<leader>gd` / `<leader>gD` | Diff this against index / HEAD~ |
| `<leader>gI` / `<leader>gw` | Toggle deleted lines / word diff |
| `<leader>gg` | lazygit · `<leader>gl` file log · `<leader>gL` log |
| `<leader>go` | Open in browser (also visual) |
| `<leader>gv{o,c,s,f,h,b}` | Diffview: open, close, staged, file history, repo history, vs HEAD~1 |
| `<leader>gvm` | Merge tool for conflicts: `[x`/`]x` jump, `<leader>co`/`ct`/`cb`/`ca` take ours/theirs/base/all, `dx` delete conflict |

## Debug (`<leader>d`) and tests (`<leader>t`)

| Key | Action | Key | Action |
|---|---|---|---|
| `db` | Toggle breakpoint | `dB` | Conditional breakpoint |
| `dc` | Continue / start | `dl` | Run last |
| `di` / `do` / `dO` | Step into / over / out | `dr` | REPL |
| `du` | Toggle DAP UI | `dx` | Terminate |
| `tn` | Run nearest test | `tf` | Run file |
| `ts` | Run suite | `to` | Test output |
| `tt` | Test summary | `tc` / `tC` / `tL` | Coverage toggle / summary / load |

## AI (`<leader>a`)

Off by default; `<leader>ai` toggles it and offers a restart.

| Key | Action |
|---|---|
| `<leader>ac` / `<leader>af` | Claude Code: toggle / focus |
| `<leader>ar` / `<leader>aC` | Claude Code: resume a session / continue the last |
| `<leader>am` | Claude Code: model |
| `<leader>ab` | Claude Code: add buffer · `<leader>as` add selection (visual) or file (explorer) |
| `<leader>aa` / `<leader>ad` | Accept / deny Claude's proposed diff |
| `<C-.>` | Sidekick: focus the AI CLI (any mode) |
| `<leader>ak` / `<leader>aK` | Sidekick: toggle CLI / pick CLI (claude, codex, gemini, ...) |
| `<leader>ap` / `<leader>at` / `<leader>aF` / `<leader>av` | Sidekick: prompt / send this / send file / send selection |

## UI (`<leader>u`)

| Key | Action | Key | Action |
|---|---|---|---|
| `uf` | Format on save (global, session) | `uF` | Format on save (buffer) |
| `ul` | Linting | `uh` | Inlay hints |
| `uw` | Wrap | `us` | Spell |
| `un` / `ur` | Numbers / relative numbers | `uc` | Conceal |
| `ud` | Dim inactive code | `uD` | Diagnostics as virtual lines |
| `ut` | Sticky context | `uz` | Zen mode |
| `uu` | Undo tree (built-in) | `uC` | Cursor animation |
| `up` | Profiler | | |

`uw us un ur uc ud uD` are persisted in `ui_config.json`; `uf uF ul uh` last
for the session (set defaults in `lua/user/settings.lua`).

## Buffers, windows, terminal, tasks, session

| Key | Action |
|---|---|
| `<leader>bd` / `<leader>bD` | Delete / wipe buffer · `<leader>bo` others · `<leader>bx` all · `<leader>ba` select all |
| `<leader>ws` / `<leader>wv` | Split / vertical split · `<leader>w=` equalize · `<leader>wo` only · `<leader>wz` zoom |
| `<C-\>` | Toggle floating terminal (inside: hide) · `<leader>T{f,h,v}` float / bottom / right |
| `<leader>o{r,s,t,l,a}` | Tasks: run, shell command, panel, restart last, action |
| `<leader>qs` / `<leader>ql` / `<leader>qS` | Restore session for cwd / last / select |
| `<leader>qd` | Don't save the current session · `<leader>qp` toggle auto persistence |
| `<leader>qr` | `:restart` (keeps the session) · `<leader>qq` / `<leader>qQ` quit / quit all |
| `<leader>n{l,h,a,d}` | Last message / history / all / dismiss |
| `<leader>x{x,w,s,l,L,q,t}` | Trouble: diagnostics, buffer diagnostics, symbols, LSP refs, loclist, quickfix, TODOs |

## Colorschemes (`<leader>c`)

| Key | Action |
|---|---|
| `<leader>cc` | Theme picker with live preview (type `dark`/`light` to filter) |
| `<leader>cd` / `<leader>cl` | Last-used dark / light theme |
| `<leader>cp` | txaty (dark or light, following 'background') |
| `<leader>cn` / `<leader>cN` | Next / previous theme |

## Changed in the 2026-10 modernization

| Before | Now |
|---|---|
| `gi` / `gr` (LSP) | Native `gri` / `grr` (+ `grt grn gra grx gO`); `gi` is Vim's again |
| Glance `gp gP gI gY` | `<leader>lp{d,r,i,t}`; native `gp`/`gP`/`gI` are back |
| `]a` / `[a` (parameter) | `],` / `[,`; `]a`/`[a` are the native arglist keys |
| `]c` in diff windows jumped by class | Native next/previous change in diff windows |
| `an` / `in` (mini.ai "next") | Native incremental selection |
| `<leader>le/lE/li` (did not run a refactor) | Working operators; new `<leader>lI` |
| `<C-n>`, `<leader>fe` → nvim-tree | snacks explorer; `<leader>fE` reveals the file |
| `<leader>ug` (tree git status) | Removed |
| git-conflict `co ct cb c0` | `<leader>gvm` merge tool |
| `<leader>r*` (distant remote) | Removed (see README, "Remote editing") |
| `<leader>F*` (Flutter) | Removed |
| Copilot / CopilotChat / avante keys | Claude Code and sidekick keys above |
| `<leader>R*`, `<leader>C*`, `<leader>pv` everywhere | Only in buffers of their language |
| — | New: `<leader>uf uF ul uh uu`, `<leader>qr`, `<leader>gl gL gvm`, `<leader>os`, `<leader>Li Lh`, `<leader>mr`, `<leader>lh` |
