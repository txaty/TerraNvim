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

---@param count integer distinct terminal per layout
---@param win table snacks.win config
local function toggle(count, win)
  return function()
    Snacks.terminal.toggle(nil, { count = count, win = win })
  end
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        shell = interactive_shell(),
        win = {
          -- Buffer-local to Snacks terminals: <C-\> hides the terminal, while
          -- <C-\><C-n> keeps working in every other terminal.
          keys = { hide_terminal = { "<C-\\>", "hide", mode = "t", desc = "Hide terminal" } },
        },
      },
    },
    keys = {
      { "<C-\\>", toggle(1, { position = "float", border = "rounded" }), desc = "Terminal: Toggle (float)" },
      { "<leader>Tf", toggle(1, { position = "float", border = "rounded" }), desc = "Terminal: Float" },
      { "<leader>Th", toggle(2, { position = "bottom", height = 15 }), desc = "Terminal: Horizontal" },
      { "<leader>Tv", toggle(3, { position = "right", width = 80 }), desc = "Terminal: Vertical" },
    },
  },
}
