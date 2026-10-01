-- Per-machine language-pack state: which packs are enabled and the option
-- values chosen with :LangOption, stored in stdpath("data")/language_config.json.
--
-- "Is pack X enabled?" precedence:
--   1. $NVIM_LANGS (tests/CI; never persisted): all | none | default | a,b,c
--      "default" ignores the JSON file and uses settings langs.default only.
--   2. an explicit value in the JSON file
--   3. settings langs.default
local persist = require "core.persist"

local M = {}

local path = vim.fn.stdpath "data" .. "/language_config.json"

-- Version 1 (core/lang_toggle.lua) stored only explicit toggles and treated a
-- missing key as "enabled". Those packs keep that meaning when read; the file is
-- rewritten as version 2 on the next change. "web" split into typescript + web,
-- and flutter no longer exists.
local V1_KEYS = { "python", "rust", "go", "latex", "typst" }

local data ---@type {languages: table<string, boolean>, options: table<string, table>}?

local function load()
  if data then
    return data
  end
  local raw = persist.load_json(path, {})
  data = { languages = {}, options = {} }
  if raw.version == 2 then
    data.languages = vim.deepcopy(raw.languages or {})
    data.options = vim.deepcopy(raw.options or {})
  elseif type(raw.languages) == "table" then
    local v1 = raw.languages
    for _, key in ipairs(V1_KEYS) do
      data.languages[key] = v1[key] ~= false
    end
    data.languages.typescript = v1.web ~= false
    data.languages.web = v1.web ~= false
  end
  return data
end

local function save()
  persist.save_json(path, { version = 2, languages = data.languages, options = data.options })
end

local env ---@type false|"all"|"none"|"default"|table<string, true>|nil

---@return false|"all"|"none"|"default"|table<string, true>
local function env_override()
  if env ~= nil then
    return env
  end
  local value = vim.env.NVIM_LANGS
  if not value or value == "" then
    env = false
  elseif value == "all" or value == "none" or value == "default" then
    env = value
  else
    env = {}
    for name in value:gmatch "[^,%s]+" do
      env[name] = true
    end
  end
  return env
end

---Is the enabled set forced by $NVIM_LANGS (and therefore not persisted)?
---@return boolean
function M.overridden()
  return env_override() ~= false
end

---@param name string
---@return boolean
function M.is_enabled(name)
  local override = env_override()
  if override == "all" then
    return true
  elseif override == "none" then
    return false
  elseif type(override) == "table" then
    return override[name] == true
  end
  if override ~= "default" then
    local explicit = load().languages[name]
    if explicit ~= nil then
      return explicit
    end
  end
  return vim.tbl_contains(require("core.settings").get "langs.default" or {}, name)
end

---@param name string
---@param enabled boolean
function M.set(name, enabled)
  load().languages[name] = enabled
  save()
end

---Option values chosen with :LangOption (ignored under $NVIM_LANGS).
---@param name string
---@return table
function M.options(name)
  if M.overridden() then
    return {}
  end
  return load().options[name] or {}
end

---@param name string
---@param key string
---@param value any
function M.set_option(name, key, value)
  local options = load().options
  options[name] = options[name] or {}
  options[name][key] = value
  save()
end

return M
