-- Core bootstrap sequence
--
-- 0. loader    — enable the bytecode cache BEFORE any module loads
-- 1. options   — vim.opt/vim.g settings (leader, security, editor defaults)
-- 2. keymaps   — plugin-free keybindings (plugin keymaps live in plugin specs)
-- 3. lang      — language packs: Mason PATH, filetypes, FileType dispatcher,
--                :Lang* commands (core/lang/)
-- 4. autocmds  — core event handlers (filetype, cursor, persistence, ui_state)
-- 5. lifecycle — registers the VimEnter sequence (colorscheme → ui_toggle →
--                session → buffer events → commands → cleanup)
-- 6. lazy      — bootstraps lazy.nvim and imports lua/plugins/*
--
-- Steps 1-5 run synchronously before any plugin loads. VimEnter fires after
-- init.lua returns.

-- Enable bytecode cache early so core modules benefit on subsequent startups.
-- lazy.nvim calls this again during setup() (idempotent).
vim.loader.enable()

require "core.options"
require "core.keymaps"
require("core.lang").setup()
require("core.autocmds").setup()
require("core.lifecycle").setup()
require "core.lazy"
