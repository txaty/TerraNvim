-- Language-pack registry.
--
-- A pack is a plain data table in lua/langs/<name>.lua (users add or override
-- packs in lua/user/langs/<name>.lua). Shared plugins (lspconfig, conform,
-- nvim-lint, nvim-dap, neotest, treesitter, blink, which-key) pull what they
-- need from the collectors below when THEY load. Packs never contribute lazy.nvim
-- opts fragments to shared plugins, so a disabled or broken pack cannot
-- reconfigure or disable them. Schema: docs/languages.md, core/lang/schema.lua.
--
-- Every pack file is required at startup (lazy.nvim must see every pack's
-- plugins, see plugin_specs()); pack files are data only, so this costs a few
-- microseconds each. Everything else runs when the consuming plugin loads.
local state = require "core.lang.state"

local M = {}

local config_dir = vim.fn.stdpath "config"
local SOURCES = { config_dir .. "/lua/langs", config_dir .. "/lua/user/langs" }

local packs ---@type table<string, table>?
local names ---@type string[]
local errors ---@type table<string, string>
local cache = {} ---@type table<string, any>

local function load_all()
  if packs then
    return
  end
  packs, names, errors = {}, {}, {}
  for _, dir in ipairs(SOURCES) do
    for file, kind in vim.fs.dir(dir) do
      local id = kind == "file" and file:match "^(.+)%.lua$"
      if id then
        -- loadfile() on the known path instead of require(): it skips the
        -- runtimepath search (~0.1 ms per pack at startup) and still uses the
        -- vim.loader bytecode cache, which replaces the global loadfile.
        local chunk, err = loadfile(dir .. "/" .. file)
        local ok, pack = false, err
        if chunk then
          ok, pack = pcall(chunk)
        end
        if ok and type(pack) == "table" then
          pack.name = pack.name or id
          if not packs[id] then
            names[#names + 1] = id
          end
          packs[id] = pack -- a user pack with the same name replaces the shipped one
        else
          errors[id] = ok and "pack file must return a table" or tostring(pack)
        end
      end
    end
  end
  table.sort(names)
end

---Every pack name, sorted.
---@return string[]
function M.names()
  load_all()
  return names
end

---@param name string
---@return table?
function M.get(name)
  load_all()
  return packs[name]
end

---Packs that failed to load: name -> error.
---@return table<string, string>
function M.load_errors()
  load_all()
  return errors
end

---@param name string
---@return boolean
function M.is_enabled(name)
  return M.get(name) ~= nil and state.is_enabled(name)
end

---Enabled pack names, sorted.
---@return string[]
function M.enabled()
  if not cache.enabled then
    cache.enabled = vim.tbl_filter(M.is_enabled, M.names())
  end
  return cache.enabled
end

---Drop collector caches (after enabling/disabling a pack or changing an option).
function M.invalidate()
  cache = {}
end

---Resolved option values: pack defaults < settings langs.options < :LangOption.
---@param name string
---@return table
function M.opts(name)
  local key = "opts:" .. name
  if cache[key] then
    return cache[key]
  end
  local pack = M.get(name) or {}
  local opts = {}
  for option, spec in pairs(pack.options or {}) do
    opts[option] = spec.default
  end
  local from_settings = (require("core.settings").get "langs.options" or {})[name]
  for option, value in pairs(type(from_settings) == "table" and from_settings or {}) do
    opts[option] = value
  end
  for option, value in pairs(state.options(name)) do
    opts[option] = value
  end
  cache[key] = opts
  return opts
end

local reported = {}

---A pack field, calling it with the pack's options when it is a function.
---@param name string
---@param field string
---@return any
function M.field(name, field)
  local pack = M.get(name)
  local value = pack and pack[field]
  if type(value) ~= "function" then
    return value
  end
  local ok, result = pcall(value, M.opts(name))
  if ok then
    return result
  end
  local id = name .. "." .. field
  if not reported[id] then
    reported[id] = true
    vim.schedule(function()
      vim.notify(("Language pack %s: %s failed: %s"):format(name, field, result), vim.log.levels.ERROR)
    end)
  end
end

---@param list? string[]
local function each(list)
  return ipairs(list or M.enabled())
end

---@param list? string[]
---@param field string
---@return string[]
local function collect_list(list, field)
  local seen, out = {}, {}
  for _, name in each(list) do
    for _, item in ipairs(M.field(name, field) or {}) do
      if not seen[item] then
        seen[item] = true
        out[#out + 1] = item
      end
    end
  end
  return out
end

---@param list? string[]
---@param field string
---@return table
local function collect_map(list, field)
  local out = {}
  for _, name in each(list) do
    for key, value in pairs(M.field(name, field) or {}) do
      out[key] = value
    end
  end
  return out
end

M.collect = {}

---@param list? string[]
---@return string[]
function M.collect.parsers(list)
  return collect_list(list, "parsers")
end

---Language servers of the given (default: enabled) packs whose `enabled`
---predicate holds: config name -> { pack = name, spec = table }.
---@param list? string[]
---@return table<string, {pack: string, spec: table}>
function M.collect.servers(list)
  local out = {}
  for _, name in each(list) do
    for server, spec in pairs(M.field(name, "servers") or {}) do
      local enabled = spec.enabled
      if type(enabled) == "function" then
        enabled = enabled(M.opts(name))
      end
      if enabled ~= false then
        out[server] = { pack = name, spec = spec }
      end
    end
  end
  return out
end

---Mason packages: every server's `mason` package plus `tools`.
---@param list? string[]
---@return string[]
function M.collect.tools(list)
  local seen, out = {}, {}
  local function add(pkg)
    if type(pkg) == "string" and not seen[pkg] then
      seen[pkg] = true
      out[#out + 1] = pkg
    end
  end
  for _, entry in pairs(M.collect.servers(list)) do
    add(entry.spec.mason)
  end
  for _, pkg in ipairs(collect_list(list, "tools")) do
    add(pkg)
  end
  table.sort(out)
  return out
end

---@param list? string[]
function M.collect.formatters_by_ft(list)
  return collect_map(list, "formatters_by_ft")
end

---@param list? string[]
function M.collect.formatters(list)
  return collect_map(list, "formatters")
end

---@param list? string[]
function M.collect.linters_by_ft(list)
  return collect_map(list, "linters_by_ft")
end

---@param list? string[]
function M.collect.linters(list)
  return collect_map(list, "linters")
end

---Filetypes whose treesitter highlighting a pack turns off (e.g. tex: vimtex).
---@param list? string[]
---@return table<string, boolean>
function M.collect.ts_disabled(list)
  local out = {}
  for ft, enabled in pairs(collect_map(list, "ts_highlight")) do
    if enabled == false then
      out[ft] = true
    end
  end
  return out
end

---@param list? string[]
---@return {pack: string, fn: fun(dap: table, opts: table)}[]
function M.collect.dap(list)
  local out = {}
  for _, name in each(list) do
    local fn = (M.get(name) or {}).dap
    if type(fn) == "function" then
      out[#out + 1] = { pack = name, fn = fn }
    end
  end
  return out
end

---@param list? string[]
---@return {pack: string, adapter: fun(opts: table): table?}[]
function M.collect.tests(list)
  local out = {}
  for _, name in each(list) do
    local test = (M.get(name) or {}).test
    if type(test) == "table" and type(test.adapter) == "function" then
      out[#out + 1] = { pack = name, adapter = test.adapter }
    end
  end
  return out
end

---blink.cmp contributions: { providers = {...}, per_filetype = {...} }.
---@param list? string[]
function M.collect.cmp(list)
  local out = { providers = {}, per_filetype = {} }
  for _, name in each(list) do
    local cmp = M.field(name, "cmp") or {}
    for key, value in pairs(cmp.providers or {}) do
      out.providers[key] = value
    end
    for key, value in pairs(cmp.per_filetype or {}) do
      out.per_filetype[key] = value
    end
  end
  return out
end

---ripgrep --type values of enabled packs, for the grep presets.
---@return {label: string, type: string}[]
function M.collect.grep_types()
  local out = {}
  for _, name in each() do
    local pack = M.get(name)
    if pack.grep_type then
      out[#out + 1] = { label = pack.title or name, type = pack.grep_type }
    end
  end
  return out
end

---Pack that owns a filetype (enabled or not).
---@param ft string
---@return string?
function M.owner(ft)
  if not cache.owners then
    cache.owners = {}
    for _, name in ipairs(M.names()) do
      for _, owned in ipairs(M.get(name).filetypes or {}) do
        cache.owners[owned] = cache.owners[owned] or name
      end
    end
  end
  return cache.owners[ft]
end

---lazy.nvim specs for every pack-owned plugin, enabled or not.
---
---Disabled packs' plugins stay in the spec with `cond = false`: lazy.nvim then
---neither loads, installs nor cleans them and keeps their lazy-lock.json entry,
---so the committed lockfile does not depend on which packs a machine enabled.
---(Dropping the specs instead would delete the lockfile entries on every sync.)
---@return table[]
function M.plugin_specs()
  local specs = {}
  for _, name in ipairs(M.names()) do
    for _, spec in ipairs(M.get(name).plugins or {}) do
      local copy = type(spec) == "string" and { spec } or {}
      if type(spec) == "table" then
        for k, v in pairs(spec) do
          copy[k] = v
        end
      end
      local original = copy.cond
      copy.cond = function(...)
        if not M.is_enabled(name) then
          return false
        end
        if type(original) == "function" then
          return original(...)
        end
        return original ~= false
      end
      specs[#specs + 1] = copy
    end
  end
  return specs
end

---Startup wiring. Called from core/init.lua before lazy.nvim.
function M.setup()
  -- Put Mason's bin dir on PATH now rather than when mason.nvim loads, so
  -- conform, nvim-lint, nvim-dap and rustaceanvim find Mason-installed tools
  -- whichever loads first. mason.nvim is configured with PATH = "skip".
  local mason_bin = vim.fn.stdpath "data" .. "/mason/bin"
  local sep = vim.fn.has "win32" == 1 and ";" or ":"
  if not (sep .. (vim.env.PATH or "") .. sep):find(sep .. mason_bin .. sep, 1, true) then
    vim.env.PATH = mason_bin .. sep .. (vim.env.PATH or "")
  end
  vim.env.MASON = vim.fn.stdpath "data" .. "/mason"

  for _, name in ipairs(M.enabled()) do
    local additions = M.get(name).filetype_add
    if additions then
      vim.filetype.add(additions)
    end
  end

  require("core.lang.runtime").setup()
  -- Registered now rather than with the other commands after VimEnter so that
  -- `nvim --headless "+LangInstall!" +qa` works (-c runs before VimEnter).
  require("core.commands.lang").register()
end

---Enable a pack now and persist it.
---@param name string
function M.enable(name)
  state.set(name, true)
  M.invalidate()
  require("core.lang.runtime").activate(name)
end

---Disable a pack now and persist it.
---@param name string
function M.disable(name)
  require("core.lang.runtime").deactivate(name)
  state.set(name, false)
  M.invalidate()
end

return M
