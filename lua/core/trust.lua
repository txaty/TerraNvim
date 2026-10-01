-- Project trust: may tooling run code that the project controls?
--
-- Opening a file in a cloned repository must not execute anything that repo
-- ships. Untrusted (every project, by default) means:
--   * language servers, linters and formatters come from Mason or PATH, never
--     from the project's node_modules (packs pin `cmd`);
--   * tools whose project configuration is code do not run: luacheck
--     (.luacheckrc), prettier/prettierd (JS configs, local installs), eslint
--     and tailwindcss servers (load the project's JS), markdownlint-cli2
--     (.cjs configs), solhint (plugins), the workspace TypeScript SDK.
-- Trusting a project (:TrustProject) allows them. Language toolchains that
-- build the project (cargo/rust-analyzer build scripts and proc macros,
-- SwiftPM manifests, go, kotlin-lsp's Gradle/Maven import) are not gated:
-- enabling those packs means building.
--
-- Trust is stored in Neovim's own trust database (:trust, vim.secure), read
-- here without prompting: a project is trusted when it, or a parent
-- directory, is allowed there.
local M = {}

local db_path = vim.fn.stdpath "state" .. "/trust"
local db, db_mtime ---@type table<string, string>?, integer?

---@return table<string, string> path -> hash ("directory" for directories, "!" denied)
local function load_db()
  local stat = vim.uv.fs_stat(db_path)
  local mtime = stat and stat.mtime.sec * 1e9 + stat.mtime.nsec or 0
  if db and mtime == db_mtime then
    return db
  end
  db, db_mtime = {}, mtime
  local fd = io.open(db_path, "r")
  if fd then
    for line in fd:lines() do
      local hash, file = line:match "^(%S+) (.+)$"
      if hash then
        db[file] = hash
      end
    end
    fd:close()
  end
  return db
end

---Project root of a buffer or path: its git root, else its directory.
---@param source? integer|string buffer (default current) or path
---@return string
function M.project_root(source)
  if type(source) == "string" then
    return vim.fs.root(source, ".git") or source
  end
  local buf = source or 0
  local name = vim.api.nvim_buf_get_name(buf)
  return vim.fs.root(buf, ".git") or (name ~= "" and vim.fs.dirname(name)) or vim.fn.getcwd()
end

---@param dir string
---@return boolean
function M.is_trusted(dir)
  local path = dir and vim.uv.fs_realpath(dir)
  if not path then
    return false
  end
  local entries = load_db()
  while path do
    local hash = entries[path]
    if hash == "!" then
      return false
    elseif hash == "directory" then
      return true
    end
    local parent = vim.fs.dirname(path)
    path = parent ~= path and parent or nil
  end
  return false
end

local skipped = {} ---@type table<string, string[]>

---Record that a tool did not run because the project is untrusted, and tell
---the user once per project and tool.
---@param what string
---@param dir string project root
function M.skipped(what, dir)
  local list = skipped[dir] or {}
  skipped[dir] = list
  if vim.tbl_contains(list, what) then
    return
  end
  list[#list + 1] = what
  if #vim.api.nvim_list_uis() == 0 then
    return
  end
  vim.schedule(function()
    vim.notify(
      ("Untrusted project %s: not running %s, which executes project code. "):format(
        vim.fn.fnamemodify(dir, ":~"),
        what
      ) .. "Trust it with :TrustProject.",
      vim.log.levels.INFO,
      { title = "Project trust" }
    )
  end)
end

---Is `what` allowed for this buffer/path? Records a skip when it is not.
---@param what string tool name, for the notice
---@param source? integer|string buffer or path
---@return boolean
function M.allows(what, source)
  local root = M.project_root(source)
  if M.is_trusted(root) then
    return true
  end
  M.skipped(what, root)
  return false
end

---conform `condition` for formatters whose project configuration is code.
---@param what string
---@return fun(self: table, ctx: {buf: integer}): boolean
function M.formatter_condition(what)
  return function(_, ctx)
    return M.allows(what, ctx.buf)
  end
end

---conform `command` that prefers the project's node_modules/.bin/<bin> only in
---trusted projects (conform's default always does), else the Mason/PATH one.
---@param bin string
---@return fun(self: table, ctx: {buf: integer, dirname: string}): string
function M.node_bin(bin)
  return function(_, ctx)
    if M.is_trusted(M.project_root(ctx.buf)) then
      local found = vim.fs.find("node_modules/.bin/" .. bin, { path = ctx.dirname, upward = true })[1]
      if found then
        return found
      end
    end
    return bin
  end
end

---Trust a project directory and re-start the servers that were gated on it.
---@param dir? string default: the current buffer's project root
function M.trust(dir)
  dir = dir and vim.fn.fnamemodify(dir, ":p") or M.project_root(0)
  local ok, msg = vim.secure.trust { action = "allow", path = dir }
  if not ok then
    vim.notify("Could not trust " .. dir .. ": " .. msg, vim.log.levels.ERROR)
    return
  end
  skipped[msg] = nil
  vim.notify(("Trusted %s: tools that run project code are allowed there."):format(vim.fn.fnamemodify(msg, ":~")))
  require("core.lang.lsp").restart_trust_gated()
end

return M
