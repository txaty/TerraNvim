-- Theme picker (<leader>cc, :ThemeSwitch) on Snacks.picker, with live preview.
--
-- Only registry themes are listed (Snacks' own colorschemes picker lists every
-- colors/* file and previews with a bare :colorscheme, skipping the registry's
-- background/globals/setup). Moving the cursor previews without saving;
-- <CR> applies and saves; closing any other way restores the previous theme.
-- :ThemeSwitch dark / light lists one variant.
local theme = require "core.theme"

local M = {}

---@param filter? string "dark"/"light" lists only that variant; anything else
---is used as the initial search pattern
function M.open(filter)
  local variant = (filter == "dark" or filter == "light") and filter or nil
  local original = theme.current() or theme.saved()
  local ok, Snacks = pcall(require, "snacks")
  if not ok then
    vim.ui.select(theme.names(), { prompt = "Theme" }, function(name)
      if name then
        theme.apply(name)
      end
    end)
    return
  end

  local items = {}
  for _, name in ipairs(variant and theme.names_by_variant(variant) or theme.names()) do
    local info = theme.registry[name]
    local item = {
      name = name,
      text = ("%s %s %s"):format(name, info.variant, info.description),
      variant = info.variant,
      description = info.description,
      current = name == original,
    }
    table.insert(items, item.current and 1 or #items + 1, item)
  end

  local confirmed, closed = false, false
  local timer = assert(vim.uv.new_timer())

  Snacks.picker.pick {
    title = "Themes",
    items = items,
    pattern = not variant and filter or nil,
    layout = { preset = "vscode" },
    format = function(item)
      return {
        { item.current and "● " or "  ", "DiagnosticOk" },
        { ("%-24s"):format(item.name) },
        { ("%-6s"):format(item.variant), "Comment" },
        { item.description, "Comment" },
      }
    end,
    on_change = function(_, item)
      if not item then
        return
      end
      -- Debounced so scrolling quickly does not apply every theme on the way.
      timer:stop()
      timer:start(
        80,
        0,
        vim.schedule_wrap(function()
          if not closed then
            theme.apply(item.name, { save = false, notify = false })
          end
        end)
      )
    end,
    confirm = function(picker, item)
      confirmed = true
      picker:close()
      if item then
        theme.apply(item.name)
      end
    end,
    on_close = function()
      closed = true
      timer:stop()
      if not timer:is_closing() then
        timer:close()
      end
      if not confirmed and original then
        vim.schedule(function()
          theme.apply(original, { save = false, notify = false })
        end)
      end
    end,
  }
end

---Apply the next/previous registry theme (dark ones first, then light).
---@param direction 1|-1
function M.cycle(direction)
  local names = theme.names()
  local current = theme.current() or theme.saved()
  local index = 0
  for i, name in ipairs(names) do
    if name == current then
      index = i
      break
    end
  end
  theme.apply(names[(index - 1 + direction) % #names + 1])
end

function M.dark()
  return theme.switch_to "dark"
end

function M.light()
  return theme.switch_to "light"
end

function M.txaty()
  return theme.apply(vim.o.background == "light" and "txaty-light" or "txaty")
end

return M
