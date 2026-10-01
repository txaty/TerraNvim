-- Language-pack commands (see lua/core/lang/).
--   :LangEnable {pack...}   :LangDisable {pack...}   :LangToggle {pack...}
--   :LangStatus [pack]      :LangPanel               :LangInfo (= :checkhealth core.lang)
--   :LangInstall[!] [pack...]   install Mason tools + parsers (! = wait, for headless use)
--   :LangOption {pack} {option} {value}
local M = {}

local function lang()
  return require "core.lang"
end

local function complete_packs(arglead)
  return vim.tbl_filter(function(name)
    return name:find(arglead, 1, true) == 1
  end, lang().names())
end

---@param names string[]
---@return string[] valid
local function known(names)
  local valid = {}
  for _, name in ipairs(names) do
    if lang().get(name) then
      valid[#valid + 1] = name
    else
      vim.notify("Unknown language pack: " .. name, vim.log.levels.ERROR)
    end
  end
  return valid
end

---@param name string
---@param enabled boolean
local function set(name, enabled)
  local changed
  if enabled then
    changed = lang().enable(name)
  else
    changed = lang().disable(name)
  end
  if not changed then
    return
  end
  local title = lang().get(name).title or name
  vim.notify(("%s %s support %s"):format(enabled and "+" or "-", title, enabled and "enabled" or "disabled"))
end

local function complete_option(arglead, cmdline)
  local args = vim.split(cmdline, "%s+", { trimempty = true })
  local count = #args + (cmdline:match "%s$" and 1 or 0)
  local candidates = {}
  if count <= 2 then
    candidates = lang().names()
  elseif count == 3 then
    candidates = vim.tbl_keys((lang().get(args[2]) or {}).options or {})
  elseif count == 4 then
    local spec = ((lang().get(args[2]) or {}).options or {})[args[3]] or {}
    candidates = vim.tbl_map(tostring, spec.choices or {})
  end
  table.sort(candidates)
  return vim.tbl_filter(function(c)
    return c:find(arglead, 1, true) == 1
  end, candidates)
end

function M.register()
  local function packs_command(name, desc, fn)
    vim.api.nvim_create_user_command(name, function(o)
      for _, pack in ipairs(known(o.fargs)) do
        fn(pack)
      end
    end, { nargs = "+", complete = complete_packs, desc = desc })
  end

  packs_command("LangEnable", "Enable language packs", function(pack)
    set(pack, true)
  end)
  packs_command("LangDisable", "Disable language packs", function(pack)
    set(pack, false)
  end)
  packs_command("LangToggle", "Toggle language packs", function(pack)
    set(pack, not lang().is_enabled(pack))
  end)

  vim.api.nvim_create_user_command("LangStatus", function(o)
    require("core.ui.lang_panel").status(o.args ~= "" and o.args or nil)
  end, { nargs = "?", complete = complete_packs, desc = "Show language pack status" })

  vim.api.nvim_create_user_command("LangPanel", function()
    require("core.ui.lang_panel").open()
  end, { desc = "Open the language pack panel" })

  vim.api.nvim_create_user_command("TrustProject", function(o)
    require("core.trust").trust(o.args ~= "" and o.args or nil)
  end, {
    nargs = "?",
    complete = "dir",
    desc = "Trust a project (default: current buffer's) so tools that run project code may run",
  })

  vim.api.nvim_create_user_command("LangInfo", function()
    vim.cmd.checkhealth "core.lang"
  end, { desc = "Language pack health (servers, tools, parsers)" })

  vim.api.nvim_create_user_command("LangInstall", function(o)
    local list = #o.fargs > 0 and known(o.fargs) or lang().enabled()
    -- Explicit request: also retry parsers whose build failed earlier.
    local failed = require("core.lang.install").ensure(list, { sync = o.bang, force = true })
    -- Headless bootstrap (CI): a non-zero exit when something is still missing.
    if o.bang and (failed or 0) > 0 and #vim.api.nvim_list_uis() == 0 then
      io.stderr:write(("LangInstall: %d tools/parsers missing; see :checkhealth core.lang\n"):format(failed))
      vim.cmd "cquit 1"
    end
  end, {
    nargs = "*",
    bang = true,
    complete = complete_packs,
    desc = "Install Mason tools and parsers of language packs (! waits)",
  })

  vim.api.nvim_create_user_command("LangOption", function(o)
    if #o.fargs ~= 3 then
      vim.notify("Usage: :LangOption {pack} {option} {value}", vim.log.levels.ERROR)
      return
    end
    local name, option, raw = o.fargs[1], o.fargs[2], o.fargs[3]
    local spec = ((lang().get(name) or {}).options or {})[option]
    if not spec then
      vim.notify(("Unknown option %s for pack %s"):format(tostring(option), tostring(name)), vim.log.levels.ERROR)
      return
    end
    local value = raw
    if raw == '""' or raw == "''" then
      value = ""
    elseif raw == "true" or raw == "false" then
      value = raw == "true"
    elseif tonumber(raw) then
      value = tonumber(raw)
    end
    if spec.choices and not vim.tbl_contains(spec.choices, value) then
      vim.notify(
        ("%s.%s must be one of: %s"):format(name, option, table.concat(spec.choices, ", ")),
        vim.log.levels.ERROR
      )
      return
    end
    if require("core.lang.state").overridden() then
      vim.notify("$NVIM_LANGS is set: language pack settings are not saved this session", vim.log.levels.WARN)
      return
    end
    require("core.lang.state").set_option(name, option, value)
    lang().invalidate()
    vim.notify(("%s.%s = %s"):format(name, option, tostring(value)))
    require("core.restart").offer((lang().get(name).title or name) .. " option changes")
  end, { nargs = "+", complete = complete_option, desc = "Set a language pack option" })
end

return M
