-- Language servers of enabled packs → vim.lsp.config() / vim.lsp.enable().
--
-- Servers are enabled because an enabled pack declares them, not because Mason
-- happens to have them installed: a disabled pack's servers never start, and
-- servers outside Mason (sourcekit-lsp from Xcode, forge lsp) work the same way.
-- Configs come from nvim-lspconfig's lsp/<name>.lua on the runtimepath, merged
-- with the pack's table. Capabilities come from blink.cmp, which registers them
-- for '*' in its plugin/ file (it is a dependency of nvim-lspconfig).
local lang = require "core.lang"

local M = {}

-- Keys that belong to the pack schema, not to vim.lsp.Config.
local RESERVED = { mason = true, enabled = true, managed_by = true, trust = true }

local trust_gated = {} ---@type table<string, true> servers that need a trusted project

---@type table<string, "enabled"|"pending"|"missing"|"managed"|"disabled">
local status = {}
local pending = {} ---@type table<string, string[]> mason package -> servers waiting for it

---@param pkg string
local function mason_installed(pkg)
  return vim.uv.fs_stat(vim.fn.stdpath "data" .. "/mason/packages/" .. pkg) ~= nil
end

---Can this server be started right now?
---@param cfg vim.lsp.Config
---@param spec table pack server spec
local function runnable(cfg, spec)
  if type(cfg.cmd) == "table" then
    return vim.fn.executable(cfg.cmd[1]) == 1
  end
  -- cmd is a function (e.g. tsc resolves a project-local binary); trust the
  -- Mason package when there is one, otherwise assume the system provides it.
  if type(spec.mason) == "string" then
    return mason_installed(spec.mason)
  end
  return true
end

---Servers marked `trust = true` load project code (eslint, tailwindcss): only
---give them a root, and so a client, in trusted projects (core.trust). The
---project is checked before nvim-lspconfig's own root_dir runs, since root_dir
---functions may execute project files too.
---@param name string
---@param base vim.lsp.Config lspconfig + pack config
---@return fun(bufnr: integer, on_dir: fun(root?: string))
local function trusted_root(name, base)
  return function(bufnr, on_dir)
    if not require("core.trust").allows(name, bufnr) then
      return
    end
    if type(base.root_dir) == "function" then
      return base.root_dir(bufnr, on_dir)
    end
    on_dir(vim.fs.root(bufnr, base.root_markers or { ".git" }))
  end
end

---@param name string
---@param spec table
---@return table
local function to_config(name, spec)
  local cfg = {}
  for key, value in pairs(spec) do
    if not RESERVED[key] then
      cfg[key] = value
    end
  end
  if spec.trust then
    trust_gated[name] = true
    cfg.root_dir = trusted_root(name, vim.tbl_extend("force", vim.lsp.config[name] or {}, cfg))
  end
  return cfg
end

---Decide whether a configured server can start now; returns true if so.
---@param name string
---@param spec table
---@return boolean? start
local function enable(name, spec)
  local cfg = vim.lsp.config[name]
  if not cfg then
    status[name] = "missing"
    vim.schedule(function()
      vim.notify(
        ("LSP %s: no config (not in nvim-lspconfig and the pack sets no cmd)"):format(name),
        vim.log.levels.WARN
      )
    end)
    return
  end
  if runnable(cfg, spec) then
    status[name] = "enabled"
    return true
  elseif type(spec.mason) == "string" then
    -- Enabled by on_installed() once core.lang.install finishes the package.
    pending[spec.mason] = pending[spec.mason] or {}
    table.insert(pending[spec.mason], name)
    status[name] = "pending"
  else
    status[name] = "missing"
  end
end

---Configure (and, with lsp.auto_start, enable) the servers of the given packs.
---@param list? string[] pack names; default: all enabled packs
function M.configure(list)
  local auto_start = require("core.settings").get "lsp.auto_start"
  local start = {}
  for name, entry in pairs(lang.collect.servers(list)) do
    if entry.spec.managed_by then
      status[name] = "managed"
    elseif #vim.api.nvim_get_runtime_file("lsp/" .. name .. ".lua", false) == 0 and not entry.spec.cmd then
      -- Unknown config name (typo, or not in nvim-lspconfig) and no cmd of
      -- our own: vim.lsp.config() would accept it and the server would just
      -- never start. Report it instead.
      status[name] = "missing"
      vim.schedule(function()
        vim.notify(
          ("Language pack %s: no LSP config named %s (not in nvim-lspconfig, no cmd)"):format(entry.pack, name),
          vim.log.levels.WARN
        )
      end)
    else
      vim.lsp.config(name, to_config(name, entry.spec))
      if not auto_start then
        status[name] = "disabled"
      elseif enable(name, entry.spec) then
        start[#start + 1] = name
      end
    end
  end
  -- One call: after VimEnter every vim.lsp.enable() re-runs FileType handling
  -- for all loaded buffers, so enabling servers one by one multiplies that.
  if #start > 0 then
    vim.lsp.enable(start)
  end
end

M.ready = false

---Called by nvim-lspconfig's config(). Runs once.
---
---Deferred one tick: nvim-lspconfig loads on BufReadPre, i.e. while a file is
---being read. After VimEnter, vim.lsp.enable() runs FileType for every loaded
---buffer, which marks the buffer being read as "filetype already set" so its
---own detection (setf) is skipped and it ends up with no filetype at all
---(seen on the first window of a restored session). On the next tick the read
---has finished and enable() attaches to it like to every other buffer.
function M.setup()
  M.ready = true
  vim.schedule(function()
    M.configure()
    M.configured = true
  end)
end

---Stop and disable the servers of the given packs.
---@param list string[]
function M.disable(list)
  for name, entry in pairs(lang.collect.servers(list)) do
    if not entry.spec.managed_by and status[name] == "enabled" then
      vim.lsp.enable(name, false)
    end
    status[name] = nil
  end
end

---A Mason package finished installing: start servers that were waiting for it.
---vim.lsp.enable() re-fires FileType for open buffers, so they attach now.
---@param pkg string
function M.on_installed(pkg)
  for _, name in ipairs(pending[pkg] or {}) do
    -- Still pending: the pack may have been disabled while it installed.
    if status[name] == "pending" then
      vim.lsp.enable(name)
      status[name] = "enabled"
    end
  end
  pending[pkg] = nil
end

---After :TrustProject: re-run FileType matching for the trust-gated servers
---so they attach to the now-trusted project's open buffers.
function M.restart_trust_gated()
  local names = vim.tbl_filter(function(name)
    return status[name] == "enabled"
  end, vim.tbl_keys(trust_gated))
  if #names > 0 then
    vim.lsp.enable(names)
  end
end

---Server name -> status, for :checkhealth core.lang and the language panel.
---@return table<string, string>
function M.status()
  return status
end

return M
