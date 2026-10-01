local opt = vim.opt
local g = vim.g

--------------------------------------
-- Globals
--------------------------------------
g.mapleader = " "
g.maplocalleader = " "

-- Disable netrw: snacks.explorer replaces it (explorer.replace_netrw)
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1

-- Disable unused language providers to suppress "Some Neovim features have
-- been disabled" startup warning. This config uses no Python/Ruby/Node/Perl
-- legacy plugins; all tooling is managed by Mason + LSP instead.
g.loaded_python3_provider = 0
g.loaded_ruby_provider = 0
g.loaded_node_provider = 0
g.loaded_perl_provider = 0

-- Built-in EditorConfig support (runtime/plugin/editorconfig.lua). It only
-- sets a fixed, safe subset of buffer options (indent, eol, charset, trailing
-- whitespace, max_line_length), so it is on unless the user opts out.
g.editorconfig = require("core.settings").get "editorconfig"

--------------------------------------
-- Security
--------------------------------------
opt.modeline = false -- Disable modeline execution (prevents untrusted files from setting options)
opt.modelines = 0 -- Defense-in-depth: zero modeline scan range even if modeline is re-enabled
opt.exrc = false -- Disable project-local .nvim.lua / .exrc execution
opt.secure = true -- Restrict :autocmd, :write, :shell in any sourced file not owned by user
if vim.fn.has "win32" == 1 then
  opt.shell = "cmd.exe"
else
  opt.shell = "/bin/sh"
end

local state_path = vim.fn.stdpath "state"
local state_dirs = {
  state_path .. "/backup",
  state_path .. "/shada",
  state_path .. "/swap",
  state_path .. "/undo",
  state_path .. "/view",
}

local state_dir_warnings = {}

local function ensure_private_dir(dir)
  if vim.fn.isdirectory(dir) == 1 then
    return true
  end

  local ok, err = pcall(vim.fn.mkdir, dir, "p", "0700")
  if ok or vim.fn.isdirectory(dir) == 1 then
    return true
  end

  if state_dir_warnings[dir] then
    return false
  end

  state_dir_warnings[dir] = true
  vim.schedule(function()
    vim.notify(string.format("Failed to create state directory %s: %s", dir, tostring(err)), vim.log.levels.WARN)
  end)

  return false
end

for _, dir in ipairs(state_dirs) do
  ensure_private_dir(dir)
end

opt.backup = false
opt.writebackup = false
opt.directory = state_path .. "/swap//"
opt.undodir = state_path .. "/undo//"
opt.viewdir = state_path .. "/view//"
opt.shadafile = state_path .. "/shada/main.shada"

--------------------------------------
-- Options
--------------------------------------
opt.laststatus = 3 -- global statusline
opt.showmode = false

opt.clipboard = "unnamedplus"
opt.cursorline = true
opt.cursorlineopt = "number"

-- Indenting
opt.expandtab = true
opt.shiftwidth = 2
opt.smartindent = true
opt.tabstop = 2
opt.softtabstop = 2

opt.fillchars = { eob = " " }
opt.ignorecase = true
opt.smartcase = true
opt.mouse = "a"

-- Numbers
opt.number = true
opt.numberwidth = 2
opt.ruler = false

-- Disable nvim intro
opt.shortmess:append "sI"

opt.signcolumn = "yes"
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.timeoutlen = 400
opt.undofile = true

-- Shada limits: 100 file marks, 50 lines/register, skip >10KB items
opt.shada = "'100,<50,s10,h"

-- interval for writing swap file to disk, also used by gitsigns
opt.updatetime = 250

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
opt.whichwrap:append "<>[]hl"

-- Folding (foldmethod/foldexpr set by treesitter after it loads)
opt.foldlevel = 99
opt.foldmethod = "manual"

-- View options: only save folds (cursor restored by BufReadPost autocmd)
opt.viewoptions = "folds"

--------------------------------------
-- UI Polish
--------------------------------------
opt.cmdheight = 0 -- Hide cmdline when not in use (works with noice.nvim)
opt.scrolloff = 8 -- Keep 8 lines visible above/below cursor
opt.sidescrolloff = 8 -- Keep 8 columns visible left/right of cursor
opt.pumheight = 10 -- Limit popup menu height
opt.confirm = true -- Confirm before closing unsaved buffers
opt.wrap = false -- Disable line wrap by default
opt.linebreak = true -- Wrap at word boundaries when wrap is enabled
opt.list = true -- Show invisible characters
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- Subtle indicators
