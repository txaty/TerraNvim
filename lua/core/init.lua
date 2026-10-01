-- Core bootstrap sequence
--
-- 0. loader   — enable bytecode cache BEFORE any module loads
-- 1. options  — vim.opt/vim.g settings (leader, netrw, editor defaults)
-- 2. keymaps  — general keybindings (plugin keymaps live in plugin specs)
-- 3. autocmds — core event handlers (filetype, cursor, persistence, ui_state)
-- 4. lifecycle — registers VimEnter autocmd for the deterministic startup
--               sequence (colorscheme → ui_toggle → session → nvim_tree →
--               commands → reconcile → cleanup)
-- 5. keymap_audit — registers VeryLazy autocmd for conflict detection
-- 6. lazy     — bootstraps lazy.nvim and imports all plugins/* specs
--
-- Timing guarantee: steps 1-5 complete synchronously before any plugin loads.
-- VimEnter fires after init.lua returns and the UI draws the first frame.

-- Enable bytecode cache early so core modules benefit on subsequent startups.
-- lazy.nvim calls this again during setup() (idempotent).
vim.loader.enable()

require "core.options"
require "core.keymaps"
require("core.autocmds").setup()
require("core.lifecycle").setup()
require("core.keymap_audit").setup()
require "core.lazy"
