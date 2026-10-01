-- :LangPanel — enable/disable language packs, install their tools, set options.
-- Built on Snacks.picker; falls back to vim.ui.select without snacks.
local M = {}

local function lang()
  return require "core.lang"
end

---@param name string
---@return string
local function summary(name)
  local install = require "core.lang.install"
  local missing = lang().is_enabled(name) and #install.missing_tools { name } + #install.missing_parsers { name } or 0
  return missing > 0 and (" · %d to install"):format(missing) or ""
end

local function items()
  local out = {}
  for _, name in ipairs(lang().names()) do
    local pack = lang().get(name)
    out[#out + 1] = {
      name = name,
      enabled = lang().is_enabled(name),
      text = name .. " " .. (pack.title or "") .. " " .. (pack.description or ""),
      title = pack.title or name,
      description = pack.description or "",
    }
  end
  return out
end

local function toggle(name)
  if lang().is_enabled(name) then
    lang().disable(name)
  else
    lang().enable(name)
  end
end

local function choose_option(name)
  local options = lang().get(name).options or {}
  local keys = vim.tbl_keys(options)
  if #keys == 0 then
    vim.notify((lang().get(name).title or name) .. " has no options")
    return
  end
  table.sort(keys)
  vim.ui.select(keys, {
    prompt = name .. " option",
    format_item = function(key)
      return ("%s = %s  (%s)"):format(key, tostring(lang().opts(name)[key]), options[key].desc)
    end,
  }, function(key)
    if not key then
      return
    end
    local function set(value)
      if value ~= nil then
        vim.cmd.LangOption { args = { name, key, value == "" and '""' or tostring(value) } }
      end
    end
    if options[key].choices then
      vim.ui.select(options[key].choices, { prompt = name .. "." .. key }, set)
    else
      vim.ui.input({ prompt = name .. "." .. key .. ": ", default = tostring(lang().opts(name)[key] or "") }, set)
    end
  end)
end

function M.open()
  local ok, Snacks = pcall(require, "snacks")
  if not ok then
    local list = items()
    vim.ui.select(list, {
      prompt = "Language packs (toggle)",
      format_item = function(item)
        return ("%s %-12s %s"):format(item.enabled and "●" or "○", item.title, item.description)
      end,
    }, function(item)
      if item then
        toggle(item.name)
      end
    end)
    return
  end

  local function act(fn)
    return function(picker, item)
      if item then
        fn(item.name)
        picker:find { refresh = true }
      end
    end
  end

  Snacks.picker.pick {
    title = "Language packs  <CR> toggle · <C-x> install · <C-o> options",
    finder = function()
      return items()
    end,
    format = function(item)
      return {
        { item.enabled and "● " or "○ ", item.enabled and "DiagnosticOk" or "Comment" },
        { ("%-12s"):format(item.title), item.enabled and "Normal" or "Comment" },
        { item.description, "Comment" },
        { summary(item.name), "DiagnosticWarn" },
      }
    end,
    layout = { preset = "select" },
    confirm = act(toggle),
    actions = {
      lang_install = act(function(name)
        require("core.lang.install").ensure({ name }, { force = true })
      end),
      lang_options = function(picker, item)
        if item then
          picker:close()
          choose_option(item.name)
        end
      end,
    },
    win = {
      input = {
        keys = {
          -- Not <C-i>: terminals without CSI-u send it as <Tab>.
          ["<C-x>"] = { "lang_install", mode = { "i", "n" } },
          ["<C-o>"] = { "lang_options", mode = { "i", "n" } },
        },
      },
    },
  }
end

---Notify the status of one pack or all packs.
---@param name? string
function M.status(name)
  local lines = {}
  for _, item in ipairs(items()) do
    if not name or item.name == name then
      lines[#lines + 1] = ("%s %-12s %s%s"):format(
        item.enabled and "●" or "○",
        item.title,
        item.description,
        summary(item.name)
      )
    end
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Language packs" })
end

return M
