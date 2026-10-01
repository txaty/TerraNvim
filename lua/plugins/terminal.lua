-- Terminals via Snacks.terminal (replaces toggleterm.nvim).
--
-- core/options.lua pins 'shell' to /bin/sh so :!, system() and plugins get a
-- POSIX shell whatever $SHELL is (fish & co. break them). Interactive
-- terminals should still be the user's login shell, so they get $SHELL as an
-- argv list (no re-parsing), but only if it is an absolute path of plain
-- characters to an executable; otherwise they fall back to 'shell'.
local function interactive_shell()
  local shell = vim.env.SHELL
  if type(shell) == "string" and shell:match "^/[%w%._%-/]+$" and vim.fn.executable(shell) == 1 then
    return { shell }
  end
  return vim.o.shell
end

-- Hide key inside the terminals opened here. Not <C-\>: in terminal mode it
-- is the prefix of <C-\><C-n> (back to Normal mode). <C-/> is sent as <C-_>
-- by many terminals, so map both. Passed per toggle() rather than through
-- `opts.terminal.win.keys`, which would reach every Snacks terminal (lazygit,
-- the Claude Code split, ...). Double <Esc> enters Normal mode (snacks default).
local hide_keys = {
  hide_slash = { "<C-/>", "hide", mode = "t", desc = "Hide terminal" },
  hide_underscore = { "<C-_>", "hide", mode = "t", desc = "Hide terminal" },
}

---@param count integer distinct terminal per layout
---@param win table snacks.win config
local function toggle(count, win)
  return function()
    Snacks.terminal.toggle(nil, { count = count, win = vim.tbl_extend("force", win, { keys = hide_keys }) })
  end
end

local float = { position = "float", border = "rounded" }

return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = { shell = interactive_shell() },
    },
    keys = {
      { "<C-\\>", toggle(1, float), desc = "Terminal: Toggle (float)" },
      { "<C-/>", toggle(1, float), desc = "Terminal: Toggle (float)" },
      { "<C-_>", toggle(1, float), desc = "which_key_ignore" },
      { "<leader>Tf", toggle(1, float), desc = "Terminal: Float" },
      { "<leader>Th", toggle(2, { position = "bottom", height = 15 }), desc = "Terminal: Horizontal" },
      { "<leader>Tv", toggle(3, { position = "right", width = 80 }), desc = "Terminal: Vertical" },
    },
  },
}
