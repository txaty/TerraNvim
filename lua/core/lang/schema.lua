-- Language-pack schema and validator. Used by the smoke test and by
-- :checkhealth core.lang only; nothing requires it at startup.
--
---@class LangPack
---@field name string                         must equal the file name (lua/langs/<name>.lua)
---@field title string                        display name, e.g. "Python"
---@field description string                  one line for :LangPanel
---@field filetypes string[]                  filetypes this pack owns (one owner per filetype)
---@field filetype_add? table                 vim.filetype.add() argument, applied when enabled
---@field grep_type? string                   ripgrep --type for the grep presets
---@field options? table<string, {default: any, choices?: any[], desc: string}>
---@field parsers? string[]|fun(o: table): string[]          treesitter parsers
---@field ts_highlight? table<string, boolean>               false = no treesitter highlight for that ft
---@field servers? table<string, LangServer>|fun(o: table): table<string, LangServer>
---@field tools? string[]|fun(o: table): string[]            extra Mason packages
---@field formatters_by_ft? table|fun(o: table): table       conform.nvim formatters_by_ft
---@field formatters? table|fun(o: table): table             conform.nvim formatter overrides
---@field linters_by_ft? table|fun(o: table): table          nvim-lint linters_by_ft
---@field linters? table|fun(o: table): table                nvim-lint overrides (+ condition)
---@field dap? fun(dap: table, o: table)                     register adapters/configurations
---@field test? {adapter: fun(o: table): table?}             neotest adapter factory
---@field cmp? {providers?: table, per_filetype?: table}|fun(o: table): table
---@field plugins? table[]                    lazy.nvim specs owned by this pack (cond is injected)
---@field keys? LangKey[]|fun(o: table): LangKey[]          buffer-local keymaps / which-key groups
---@field ft_options? table<string, table>|fun(o: table): table  buffer options per filetype
--
---@class LangServer: vim.lsp.Config
---@field mason string|false                  Mason package, or false for system-provided servers
---@field enabled? boolean|fun(o: table): boolean
---@field managed_by? string                  configured by a plugin (rustaceanvim), never enabled here
--
---@class LangKey
---@field [1] string                          lhs
---@field [2]? string|function                rhs (omit for a which-key group entry)
---@field desc? string
---@field group? string                       which-key group name
---@field icon? string
---@field mode? string|string[]
---@field ft? string|string[]                 defaults to the pack's filetypes
---@field expr? boolean
---@field cond? fun(buf: integer): boolean

local M = {}

local FIELDS = {
  name = "string",
  title = "string",
  description = "string",
  filetypes = "table",
  filetype_add = "table",
  grep_type = "string",
  options = "table",
  parsers = "table|function",
  ts_highlight = "table",
  servers = "table|function",
  tools = "table|function",
  formatters_by_ft = "table|function",
  formatters = "table|function",
  linters_by_ft = "table|function",
  linters = "table|function",
  dap = "function",
  test = "table",
  cmp = "table|function",
  plugins = "table",
  keys = "table|function",
  ft_options = "table|function",
}

-- Shared plugins configured by lua/plugins/*. A pack listing one of them would
-- add a lazy.nvim fragment whose injected `cond` disables it for everyone.
M.BASE_PLUGINS = {
  "neovim/nvim-lspconfig",
  "stevearc/conform.nvim",
  "mfussenegger/nvim-lint",
  "mfussenegger/nvim-dap",
  "nvim-neotest/neotest",
  "nvim-neotest/nvim-nio",
  "nvim-treesitter/nvim-treesitter",
  "nvim-treesitter/nvim-treesitter-textobjects",
  "folke/which-key.nvim",
  "folke/snacks.nvim",
  "mason-org/mason.nvim",
  "saghen/blink.cmp",
  "nvim-lua/plenary.nvim",
  "b0o/SchemaStore.nvim",
}

---@param value any
---@param types string e.g. "table|function"
local function is_type(value, types)
  for t in types:gmatch "[^|]+" do
    if type(value) == t then
      return true
    end
  end
  return false
end

---@param pack table
---@param field string
---@param opts table
local function resolve(pack, field, opts)
  local value = pack[field]
  if type(value) == "function" then
    local ok, result = pcall(value, opts)
    return ok and result or nil, not ok and result or nil
  end
  return value
end

---Repos lazy.nvim knows from outside the packs (allowed as pack dependencies).
---@return table<string, true>
function M.shared_repos()
  local pack_repos, shared = {}, {}
  local lang = require "core.lang"
  for _, name in ipairs(lang.names()) do
    for _, spec in ipairs(lang.get(name).plugins or {}) do
      pack_repos[type(spec) == "string" and spec or spec[1]] = true
    end
  end
  local ok, Config = pcall(require, "lazy.core.config")
  for _, plugin in pairs(ok and Config.spec and Config.spec.plugins or {}) do
    if plugin[1] and not pack_repos[plugin[1]] then
      shared[plugin[1]] = true
    end
  end
  return shared
end

---Validate every pack. Returns a list of "pack: problem" strings.
---@param packs table<string, table> name -> pack
---@param shared? table<string, true> repos declared outside packs (allowed as dependencies)
---@return string[]
function M.validate(packs, shared)
  shared = shared or {}
  local problems = {}
  local function problem(name, msg, ...)
    problems[#problems + 1] = name .. ": " .. msg:format(...)
  end

  local ft_owner, server_owner, plugin_owner = {}, {}, {}
  local base = {}
  for _, repo in ipairs(M.BASE_PLUGINS) do
    base[repo] = true
  end

  local names = vim.tbl_keys(packs)
  table.sort(names)
  for _, name in ipairs(names) do
    local pack = packs[name]
    for key, value in pairs(pack) do
      if not FIELDS[key] then
        problem(name, "unknown field %q", key)
      elseif not is_type(value, FIELDS[key]) then
        problem(name, "field %q must be %s, got %s", key, FIELDS[key], type(value))
      end
    end
    if pack.name ~= name then
      problem(name, "name %q does not match the file name", tostring(pack.name))
    end
    for _, required in ipairs { "title", "description", "filetypes" } do
      if pack[required] == nil then
        problem(name, "missing required field %q", required)
      end
    end

    for _, ft in ipairs(pack.filetypes or {}) do
      if ft_owner[ft] then
        problem(name, "filetype %q is already owned by %s", ft, ft_owner[ft])
      end
      ft_owner[ft] = name
    end

    local opts = {}
    for option, spec in pairs(pack.options or {}) do
      if type(spec) ~= "table" or spec.desc == nil then
        problem(name, "option %q needs {default, desc}", option)
      else
        opts[option] = spec.default
        if spec.choices and not vim.tbl_contains(spec.choices, spec.default) then
          problem(name, "option %q default is not one of its choices", option)
        end
      end
    end

    for _, field in ipairs { "parsers", "tools", "servers", "formatters_by_ft", "linters_by_ft", "keys", "cmp" } do
      local _, err = resolve(pack, field, opts)
      if err then
        problem(name, "%s(opts) raised: %s", field, err)
      end
    end

    -- Servers: every variant must be declared, so resolve with each choice.
    local variants = { opts }
    for option, spec in pairs(pack.options or {}) do
      for _, choice in ipairs(spec.choices or {}) do
        variants[#variants + 1] = vim.tbl_extend("force", opts, { [option] = choice })
      end
    end
    local declared = {}
    for _, variant in ipairs(variants) do
      for server, spec in pairs(resolve(pack, "servers", variant) or {}) do
        declared[server] = spec
      end
    end
    for server, spec in pairs(declared) do
      if spec.mason == nil then
        problem(name, 'server %s: set mason = "<package>" or mason = false', server)
      elseif spec.mason ~= false and type(spec.mason) ~= "string" then
        problem(name, "server %s: mason must be a string or false", server)
      end
      if server_owner[server] and server_owner[server] ~= name then
        problem(name, "server %s is already declared by %s", server, server_owner[server])
      end
      server_owner[server] = name
    end

    for i, key in ipairs(resolve(pack, "keys", opts) or {}) do
      if type(key) ~= "table" or type(key[1]) ~= "string" then
        problem(name, "keys[%d] needs a lhs string", i)
      elseif not key.group and not key.desc then
        problem(name, "key %s needs a desc (which-key shows it)", key[1])
      elseif not key.group and key[2] == nil then
        problem(name, "key %s has no rhs", key[1])
      end
    end

    for i, spec in ipairs(pack.plugins or {}) do
      local repo = type(spec) == "string" and spec or (type(spec) == "table" and spec[1])
      if type(repo) ~= "string" then
        problem(name, "plugins[%d] needs a repo string", i)
      else
        if base[repo] then
          problem(name, "plugin %s is shared; packs must not add specs for it", repo)
        end
        if plugin_owner[repo] then
          problem(name, "plugin %s is already owned by %s", repo, plugin_owner[repo])
        end
        plugin_owner[repo] = name
      end
    end

    if pack.test ~= nil and type(pack.test.adapter) ~= "function" then
      problem(name, "test.adapter must be a function")
    end
  end

  -- A dependency that only a pack plugin pulls in would not get the injected
  -- `cond`, so it would be installed and loaded for everyone.
  for _, name in ipairs(names) do
    for _, spec in ipairs(packs[name].plugins or {}) do
      for _, dep in ipairs(type(spec) == "table" and spec.dependencies or {}) do
        local repo = type(dep) == "string" and dep or dep[1]
        if repo and not base[repo] and not shared[repo] and not plugin_owner[repo] then
          problem(name, "dependency %s must also be listed in the pack's plugins", repo)
        end
      end
    end
  end

  return problems
end

return M
