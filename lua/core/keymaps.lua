-- General (non-plugin) keymaps.
--
-- Scope rule: a mapping lives here only when it needs no plugin. Anything that
-- drives a plugin belongs in that plugin's `keys` spec so the plugin stays
-- lazy-loaded. Mappings that drive a core.* module live here and require the
-- module inside the callback, so the module is only loaded when the key is used.
--
-- Overlapping mappings are reported by :checkhealth which-key.
local map = vim.keymap.set

--------------------------------------
-- Insert-mode navigation
--------------------------------------
map("i", "<C-b>", "<ESC>^i", { desc = "Move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "Move end of line" })
map("i", "<C-h>", "<Left>", { desc = "Move left" })
map("i", "<C-l>", "<Right>", { desc = "Move right" })
map("i", "<C-j>", "<Down>", { desc = "Move down" })
map("i", "<C-k>", "<Up>", { desc = "Move up" })
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

--------------------------------------
-- Windows and buffers
--------------------------------------
map("n", "<Esc>", "<cmd>nohlsearch<cr><Esc>", { desc = "Clear search highlight" })
map("n", "<C-h>", "<C-w>h", { desc = "Switch Window left" })
map("n", "<C-l>", "<C-w>l", { desc = "Switch Window right" })
map("n", "<C-j>", "<C-w>j", { desc = "Switch Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Switch Window up" })

map("n", "<TAB>", "<cmd>bnext<CR>", { desc = "Buffer Next" })
map("n", "<S-TAB>", "<cmd>bprev<CR>", { desc = "Buffer Prev" })
-- <leader>b{d,D,o,x} are owned by lua/plugins/ui.lua (Snacks.bufdelete)
map("n", "<leader>ba", "gg<S-v>G", { desc = "Buffer: select entire buffer" })

map("n", "<leader>ws", "<cmd>split<cr>", { desc = "Window: horizontal split" })
map("n", "<leader>wv", "<cmd>vsplit<cr>", { desc = "Window: vertical split" })
map("n", "<leader>w=", "<C-w>=", { desc = "Window: equalize sizes" })
map("n", "<leader>wo", "<cmd>only<cr>", { desc = "Window: close others" })
map("n", "<leader>wz", function()
  if vim.t.zoomed then
    vim.cmd.wincmd "="
    vim.t.zoomed = false
  else
    vim.cmd.wincmd "_"
    vim.cmd.wincmd "|"
    vim.t.zoomed = true
  end
end, { desc = "Window: toggle zoom" })

--------------------------------------
-- Editor basics
--------------------------------------
map("n", ";", ":", { desc = "Command mode" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "General Save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "General Copy whole file" })
map("n", "<leader>sc", "<cmd>nohlsearch<cr>", { desc = "Search: clear highlights" })

--------------------------------------
-- Files
--------------------------------------
-- <C-n> / <leader>fe (explorer) are owned by lua/plugins/snacks.lua.
map("n", "<leader>fW", "<cmd>w<cr>", { desc = "Files: save" })

---Copy a modifier-expanded form of the current file's name to the clipboard.
---@param modifier string vim filename modifier, e.g. ":p", ":.", ":t"
---@param label string what to call it in the notification
local function yank_path(modifier, label)
  return function()
    local path = vim.fn.expand("%" .. modifier)
    if path == "" then
      vim.notify("No file in current buffer", vim.log.levels.WARN)
      return
    end
    vim.fn.setreg("+", path)
    vim.notify(string.format("Copied %s: %s", label, path), vim.log.levels.INFO)
  end
end

map("n", "<leader>fy", yank_path(":p", "absolute path"), { desc = "Files: yank absolute path" })
map("n", "<leader>fY", yank_path(":.", "relative path"), { desc = "Files: yank relative path" })
map("n", "<leader>fN", yank_path(":t", "filename"), { desc = "Files: yank filename" })

--------------------------------------
-- UI/Display toggles (persisted in ui_config.json)
--------------------------------------
---@param opt string key in core.ui_toggle's `defaults`
local function ui_toggle(opt)
  return function()
    require("core.ui_toggle").toggle(opt)
  end
end

map("n", "<leader>uw", ui_toggle "wrap", { desc = "UI: Toggle line wrap" })
map("n", "<leader>us", ui_toggle "spell", { desc = "UI: Toggle spell check" })
map("n", "<leader>un", ui_toggle "number", { desc = "UI: Toggle line numbers" })
map("n", "<leader>ur", ui_toggle "relativenumber", { desc = "UI: Toggle relative numbers" })
map("n", "<leader>uc", ui_toggle "conceallevel", { desc = "UI: Toggle conceal" })
map("n", "<leader>ud", ui_toggle "dim", { desc = "UI: Toggle dim" })
map("n", "<leader>uD", ui_toggle "diagnostic_lines", { desc = "UI: Toggle inline diagnostics" })
map("n", "<leader>uu", function()
  -- Neovim 0.12's built-in undo tree, an optional package loaded on first use.
  vim.cmd.packadd "nvim.undotree"
  vim.cmd.Undotree()
end, { desc = "UI: Undo tree" })

--------------------------------------
-- Colorscheme (core.ui.theme_picker)
--------------------------------------
-- These call the module directly rather than the :Theme* commands: commands are
-- registered from the VimEnter lifecycle, so a keypress during startup would
-- otherwise hit a command that does not exist yet.
---@param method string function name on core.ui.theme_picker
---@param arg? any single argument forwarded to that function
local function theme_picker(method, arg)
  return function()
    require("core.ui.theme_picker")[method](arg)
  end
end

map("n", "<leader>cc", theme_picker "open", { desc = "Color: choose colorscheme" })
map("n", "<leader>cd", theme_picker "dark", { desc = "Color: switch to dark" })
map("n", "<leader>cl", theme_picker "light", { desc = "Color: switch to light" })
map("n", "<leader>cp", theme_picker "txaty", { desc = "Color: switch to txaty" })
map("n", "<leader>cn", theme_picker("cycle", 1), { desc = "Color: next theme" })
map("n", "<leader>cN", theme_picker("cycle", -1), { desc = "Color: previous theme" })

--------------------------------------
-- Session / quit
--------------------------------------
-- <leader>q{s,S,l,d} are owned by lua/plugins/session.lua (persistence.nvim).
map("n", "<leader>qq", "<cmd>q<cr>", { desc = "Quit window" })
map("n", "<leader>qQ", "<cmd>qa!<cr>", { desc = "Quit all" })
map("n", "<leader>qr", "<cmd>restart<cr>", { desc = "Restart Neovim (keeps session)" })
map("n", "<leader>qp", function()
  require("core.session_toggle").toggle()
end, { desc = "Session: toggle auto persistence" })

--------------------------------------
-- Feature toggles (AI / language support)
--------------------------------------
map("n", "<leader>ai", function()
  require("core.ai_toggle").toggle()
end, { desc = "AI: Toggle AI features" })

-- Capital L so the language panel does not collide with the <leader>l* LSP group.
map("n", "<leader>Lp", function()
  require("core.ui.lang_panel").open()
end, { desc = "Language: Packs panel" })
map("n", "<leader>Ls", function()
  require("core.ui.lang_panel").status()
end, { desc = "Language: Pack status" })
map("n", "<leader>Li", function()
  local lang = require "core.lang"
  require("core.lang.install").ensure(lang.enabled(), { force = true })
end, { desc = "Language: Install tools of enabled packs" })
map("n", "<leader>Lh", "<cmd>checkhealth core.lang<cr>", { desc = "Language: Health" })
map("n", "<leader>Lt", function()
  require("core.trust").trust()
end, { desc = "Language: Trust this project" })
