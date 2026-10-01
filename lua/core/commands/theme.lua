-- Theme switching commands
local M = {}

local function picker()
  return require "core.ui.theme_picker"
end

function M.register()
  vim.api.nvim_create_user_command("ThemeSwitch", function(o)
    picker().open(o.args ~= "" and o.args or nil)
  end, {
    nargs = "?",
    complete = function()
      return { "dark", "light" }
    end,
    desc = "Open the theme picker (optionally filtered: dark/light)",
  })

  vim.api.nvim_create_user_command("ThemeDark", function()
    picker().dark()
  end, { desc = "Switch to the last-used dark theme" })

  vim.api.nvim_create_user_command("ThemeLight", function()
    picker().light()
  end, { desc = "Switch to the last-used light theme" })

  vim.api.nvim_create_user_command("ThemeTxaty", function()
    picker().txaty()
  end, { desc = "Switch to the custom txaty theme" })

  vim.api.nvim_create_user_command("ThemeNext", function()
    picker().cycle(1)
  end, { desc = "Cycle to the next theme" })

  vim.api.nvim_create_user_command("ThemePrev", function()
    picker().cycle(-1)
  end, { desc = "Cycle to the previous theme" })
end

return M
