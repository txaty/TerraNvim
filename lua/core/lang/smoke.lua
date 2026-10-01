-- Language-pack checks for scripts/smoke.lua (only loaded by the smoke test).
-- Runs against whatever $NVIM_LANGS enabled: default, all or none.
local lang = require "core.lang"

---@param T {check: fun(name: string, cond: any, detail?: string), warn: fun(name: string, detail?: string)}
return function(T)
  local check, warn = T.check, T.warn
  local Config = require "lazy.core.config"

  -- 1. Every pack file loads, is data-only at the top level, and is valid.
  local load_errors = lang.load_errors()
  check("all language packs load", next(load_errors) == nil, vim.inspect(load_errors))

  local impure = {}
  for _, dir in ipairs { "/lua/langs/", "/lua/user/langs/" } do
    for file in vim.fs.dir(vim.fn.stdpath "config" .. dir) do
      if file:match "%.lua$" then
        local chunk = loadfile(vim.fn.stdpath "config" .. dir .. file)
        if chunk then
          local touched = {}
          local env = setmetatable({}, {
            __index = function(_, key)
              touched[key] = true
              return _G[key]
            end,
          })
          setfenv(chunk, env)
          pcall(chunk)
          if touched.require or touched.vim then
            impure[#impure + 1] = file
          end
        end
      end
    end
  end
  check("pack files do no work at load time (no top-level require/vim)", #impure == 0, table.concat(impure, ", "))

  local packs = {}
  for _, name in ipairs(lang.names()) do
    packs[name] = lang.get(name)
  end
  local schema = require "core.lang.schema"
  local problems = schema.validate(packs, schema.shared_repos())
  check("language pack schema", #problems == 0, table.concat(problems, " | "))

  -- 2. Mason package names exist in the local registry copy.
  local registry = vim.fn.stdpath "data" .. "/mason/registries/github/mason-org/mason-registry/registry.json"
  local fd = io.open(registry, "r")
  if fd then
    local known = {}
    for _, pkg in ipairs(vim.json.decode(fd:read "*a")) do
      known[pkg.name] = true
    end
    fd:close()
    local unknown = {}
    for _, pkg in ipairs(lang.collect.tools(lang.names())) do
      if not known[pkg] then
        unknown[#unknown + 1] = pkg
      end
    end
    check("Mason package names exist", #unknown == 0, table.concat(unknown, ", "))
  else
    warn "Mason registry not downloaded; package names not checked"
  end

  local enabled = lang.enabled()
  local disabled = vim.tbl_filter(function(name)
    return not lang.is_enabled(name)
  end, lang.names())

  -- 3. Disabled packs contribute nothing: their plugins are cond=false.
  local loaded_disabled = {}
  for _, name in ipairs(disabled) do
    for _, spec in ipairs(lang.get(name).plugins or {}) do
      local short = (type(spec) == "string" and spec or spec[1]):match "[^/]+$"
      if Config.plugins[short] then
        loaded_disabled[#loaded_disabled + 1] = short
      end
    end
  end
  check("disabled packs' plugins are not active", #loaded_disabled == 0, table.concat(loaded_disabled, ", "))

  -- 4. Open a buffer per owned filetype of enabled packs (this loads
  -- nvim-lspconfig, nvim-lint and the pack plugins, as a real session would).
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  local buffers = {}
  for _, name in ipairs(enabled) do
    for _, ft in ipairs(lang.get(name).filetypes or {}) do
      local file = tmp .. "/sample_" .. ft:gsub("%W", "_")
      vim.cmd.edit(vim.fn.fnameescape(file))
      local buf = vim.api.nvim_get_current_buf()
      vim.bo[buf].filetype = ft
      buffers[#buffers + 1] = { pack = name, ft = ft, buf = buf }
    end
  end
  require("lazy").load { plugins = { "nvim-lspconfig", "conform.nvim", "nvim-lint" } }
  -- core.lang.lsp configures servers one tick after nvim-lspconfig loads.
  vim.wait(2000, function()
    return require("core.lang.lsp").configured == true
  end, 10)

  -- LSP: every server of an enabled pack is configured; disabled packs' are not enabled.
  local lsp_status = require("core.lang.lsp").status()
  local unconfigured, wrongly_enabled, not_running = {}, {}, {}
  for server, entry in pairs(lang.collect.servers()) do
    if not entry.spec.managed_by then
      if not vim.lsp.config[server] then
        unconfigured[#unconfigured + 1] = server
      elseif lsp_status[server] ~= "enabled" then
        not_running[#not_running + 1] = server .. "=" .. tostring(lsp_status[server])
      end
    end
  end
  for server, entry in pairs(lang.collect.servers(disabled)) do
    if not entry.spec.managed_by and vim.lsp.is_enabled(server) then
      wrongly_enabled[#wrongly_enabled + 1] = server
    end
  end
  check("enabled packs' servers have a config", #unconfigured == 0, table.concat(unconfigured, ", "))

  -- Mason-backed servers must not resolve their binary from the project
  -- (nvim-lspconfig's function cmds prefer <root>/node_modules/.bin).
  local function_cmds = {}
  for server, entry in pairs(lang.collect.servers()) do
    local cfg = vim.lsp.config[server]
    if type(entry.spec.mason) == "string" and not entry.spec.managed_by and cfg and type(cfg.cmd) ~= "table" then
      function_cmds[#function_cmds + 1] = server
    end
  end
  check("Mason servers use a pinned cmd (no project binaries)", #function_cmds == 0, table.concat(function_cmds, ", "))
  check("disabled packs' servers are not enabled", #wrongly_enabled == 0, table.concat(wrongly_enabled, ", "))
  if #not_running > 0 then
    table.sort(not_running)
    warn("servers not runnable yet (install with :LangInstall)", table.concat(not_running, ", "))
  end

  -- Formatters and linters: registered and resolvable.
  local conform = require "conform"
  local bad_formatters = {}
  for ft, list in pairs(lang.collect.formatters_by_ft()) do
    local registered = conform.formatters_by_ft[ft]
    -- Values are rebuilt per collect (closures, fresh tables), so compare shape.
    if registered == nil or (type(list) == "table" and not vim.deep_equal(registered, list)) then
      bad_formatters[#bad_formatters + 1] = ft .. " (not registered)"
    end
    if type(list) == "table" then
      for _, formatter in ipairs(list) do
        if not conform.get_formatter_config(formatter) then
          bad_formatters[#bad_formatters + 1] = formatter
        end
      end
    end
  end
  check("formatters registered and known to conform", #bad_formatters == 0, table.concat(bad_formatters, ", "))

  local lint = require "lint"
  local expected_linters = lang.collect.linters_by_ft()
  check(
    "nvim-lint uses exactly the packs' linters",
    vim.deep_equal(lint.linters_by_ft, expected_linters),
    vim.inspect(lint.linters_by_ft)
  )
  local bad_linters = {}
  for _, names in pairs(expected_linters) do
    for _, linter in ipairs(names) do
      if not pcall(function()
        return assert(lint.linters[linter])
      end) then
        bad_linters[#bad_linters + 1] = linter
      end
    end
  end
  check("linters known to nvim-lint", #bad_linters == 0, table.concat(bad_linters, ", "))

  -- Parsers: valid names; installed is a warning only (needs network).
  local parsers = require "nvim-treesitter.parsers"
  local bad_parsers = vim.tbl_filter(function(parser)
    return parsers[parser] == nil
  end, lang.collect.parsers(lang.names()))
  check("parser names known to nvim-treesitter", #bad_parsers == 0, table.concat(bad_parsers, ", "))
  local missing_parsers = require("core.lang.install").missing_parsers()
  if #missing_parsers > 0 then
    warn("parsers not installed (:LangInstall)", table.concat(missing_parsers, ", "))
  end

  -- DAP: packs with a dap() produce configurations.
  if #lang.collect.dap() > 0 then
    require("lazy").load { plugins = { "nvim-dap" } }
    local dap = require "dap"
    local no_config = {}
    for _, entry in ipairs(lang.collect.dap()) do
      local any = false
      for _, ft in ipairs(lang.get(entry.pack).filetypes) do
        any = any or (dap.configurations[ft] ~= nil and #dap.configurations[ft] > 0)
      end
      if not any then
        no_config[#no_config + 1] = entry.pack
      end
    end
    check("DAP configurations registered", #no_config == 0, table.concat(no_config, ", "))
  end

  -- Buffer-local keymaps land on the right buffers.
  local missing_keys = {}
  for _, b in ipairs(buffers) do
    for _, key in ipairs(lang.field(b.pack, "keys") or {}) do
      local fts = key.ft or lang.get(b.pack).filetypes
      fts = type(fts) == "string" and { fts } or fts
      if key[2] and not key.cond and vim.tbl_contains(fts, b.ft) then
        local mode = type(key.mode) == "table" and key.mode[1] or key.mode or "n"
        local map = vim.api.nvim_buf_call(b.buf, function()
          return vim.fn.maparg(key[1], mode, false, true)
        end)
        if map.buffer ~= 1 then
          missing_keys[#missing_keys + 1] = b.pack .. ":" .. key[1]
        end
      end
    end
  end
  check("pack keymaps are buffer-local on their filetypes", #missing_keys == 0, table.concat(missing_keys, ", "))

  -- 5. :checkhealth core.lang reports no errors.
  vim.cmd "silent checkhealth core.lang"
  local report = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  local errors = {}
  for line in report:gmatch "[^\n]+" do
    if line:match "ERROR" then
      errors[#errors + 1] = vim.trim(line)
    end
  end
  check(":checkhealth core.lang has no errors", #errors == 0, table.concat(errors, " | "))
end
