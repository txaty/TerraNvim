-- Headless smoke test. Run through scripts/smoke.sh (or `make test`), which
-- sources this file with --cmd so it executes BEFORE init.lua.
--
-- Phase A (now): flag smoke mode, capture errors, snapshot files that must not change.
-- Phase B (after VimEnter + VeryLazy): run the checks, print TAP-ish lines,
-- exit with :cquit on failure.

vim.g.nvim_smoke = true

local uv = vim.uv
local config_dir = vim.fn.stdpath "config"
local data_dir = vim.fn.stdpath "data"

local results = { pass = 0, fail = 0, warn = 0 }
local captured_errors = {}

local function out(line)
  io.stdout:write(line .. "\n")
end

local function ok(name)
  results.pass = results.pass + 1
  out("ok      " .. name)
end

local function fail(name, detail)
  results.fail = results.fail + 1
  out("FAIL    " .. name .. (detail and (": " .. detail) or ""))
end

local function warn(name, detail)
  results.warn = results.warn + 1
  out("warn    " .. name .. (detail and (": " .. detail) or ""))
end

local function check(name, cond, detail)
  if cond then
    ok(name)
  else
    fail(name, detail)
  end
end

---@param path string
---@return string?
local function hash(path)
  local fd = io.open(path, "rb")
  if not fd then
    return nil
  end
  local content = fd:read "*a"
  fd:close()
  return vim.fn.sha256(content)
end

-- Files that a smoke run must never write: the committed lockfile and every
-- persisted JSON state file in the data dir.
local watched = { config_dir .. "/lazy-lock.json" }
for name, kind in vim.fs.dir(data_dir) do
  if kind == "file" and name:match "%.json$" then
    watched[#watched + 1] = data_dir .. "/" .. name
  end
end
local before = {}
for _, path in ipairs(watched) do
  before[path] = hash(path) or "<absent>"
end

---JSON state files present in the data dir now.
local function data_json_files()
  local files = {}
  for name, kind in vim.fs.dir(data_dir) do
    if kind == "file" and name:match "%.json$" then
      files[#files + 1] = data_dir .. "/" .. name
    end
  end
  return files
end

-- Record ERROR notifications made before noice takes over vim.notify (at
-- VeryLazy). After that, noice's own history is read (noice_errors()):
-- re-wrapping vim.notify would make noice report it as overwritten.
local function wrap_notify()
  local inner = vim.notify
  vim.notify = function(msg, level, opts)
    if level and level >= vim.log.levels.ERROR then
      captured_errors[#captured_errors + 1] = tostring(msg)
    end
    return inner(msg, level, opts)
  end
end
wrap_notify()

---ERROR notifications noice has recorded (it owns vim.notify after VeryLazy).
---@return string[]
local function noice_errors()
  local manager = package.loaded["noice.message.manager"]
  if not manager then
    return {}
  end
  local errs = {}
  for _, message in ipairs(manager.get({ event = "notify" }, { history = true })) do
    if message.level == "error" then
      errs[#errs + 1] = message:content()
    end
  end
  return errs
end

---Collect error-looking lines from :messages.
local function message_errors()
  local msgs = vim.api.nvim_exec2("messages", { output = true }).output or ""
  local errs = {}
  for line in msgs:gmatch "[^\n]+" do
    if line:match "^E%d+:" or line:match "^Error" or line:match "^Lua:" or line:match "stack traceback" then
      errs[#errs + 1] = line
    end
  end
  return errs
end

local M = {}
M.check, M.ok, M.fail, M.warn = check, ok, fail, warn

--------------------------------------------------------------------------------
-- Checks
--------------------------------------------------------------------------------
local function check_startup()
  -- v:errmsg is also set by errors swallowed with :silent!, so it is a hint, not a failure.
  if vim.v.errmsg ~= "" then
    warn("v:errmsg is set", vim.v.errmsg)
  end

  local msg_errs = message_errors()
  check("no errors in :messages", #msg_errs == 0, table.concat(msg_errs, " | "))

  local notified = vim.list_extend(vim.deepcopy(captured_errors), noice_errors())
  check("no ERROR notifications", #notified == 0, table.concat(notified, " | "))

  local Config = require "lazy.core.config"
  local spec_errs = {}
  for _, n in ipairs(Config.spec and Config.spec.notifs or {}) do
    if n.level >= vim.log.levels.WARN then
      spec_errs[#spec_errs + 1] = n.msg
    end
  end
  check("lazy spec has no warnings/errors", #spec_errs == 0, table.concat(spec_errs, " | "))

  local broken = {}
  for name, plugin in pairs(Config.plugins) do
    if plugin._ and plugin._.has_errors then
      broken[#broken + 1] = name
    end
  end
  check("no plugin failed to load", #broken == 0, table.concat(broken, ", "))

  local missing = {}
  for name, plugin in pairs(Config.plugins) do
    if not (plugin._ and plugin._.installed) then
      missing[#missing + 1] = name
    end
  end
  if #missing > 0 then
    table.sort(missing)
    warn("plugins not installed (run :Lazy install)", table.concat(missing, ", "))
  end
end

local function check_no_writes()
  local changed = {}
  for _, path in ipairs(watched) do
    if (hash(path) or "<absent>") ~= before[path] then
      changed[#changed + 1] = vim.fn.fnamemodify(path, ":t")
    end
  end
  for _, path in ipairs(data_json_files()) do
    if before[path] == nil then
      changed[#changed + 1] = vim.fn.fnamemodify(path, ":t") .. " (created)"
    end
  end
  check("lockfile and persisted state untouched", #changed == 0, table.concat(changed, ", "))
end

-- Optional suites contributed by the config itself (language packs etc.).
-- Each module returns function(M) and uses M.check/M.warn.
local function run_suites()
  local suites = { "core.lang.smoke" }
  for _, mod in ipairs(suites) do
    local found, suite = pcall(require, mod)
    check("suite " .. mod .. " loads", found and type(suite) == "function", tostring(suite))
    if found and type(suite) == "function" then
      local success, err = pcall(suite, M)
      check("suite " .. mod .. " ran", success, tostring(err))
    end
  end
end

---Errors raised while the suites ran (often scheduled, so let the event loop
---drain first): new :messages errors and new ERROR notifications.
local function check_late_errors(messages_before, notified_before, noice_before)
  vim.wait(300, function()
    return false
  end)
  local late = {}
  local seen = {}
  for _, line in ipairs(messages_before) do
    seen[line] = (seen[line] or 0) + 1
  end
  for _, line in ipairs(message_errors()) do
    if (seen[line] or 0) > 0 then
      seen[line] = seen[line] - 1
    else
      late[#late + 1] = line
    end
  end
  for i = notified_before + 1, #captured_errors do
    late[#late + 1] = captured_errors[i]
  end
  local noice_now = noice_errors()
  for i = noice_before + 1, #noice_now do
    late[#late + 1] = noice_now[i]
  end
  check("no errors while the suites ran", #late == 0, table.concat(late, " | "))
end

local function finish()
  check_no_writes()
  out(string.format("-- %d passed, %d failed, %d warnings", results.pass, results.fail, results.warn))
  vim.cmd(results.fail > 0 and "cquit 1" or "qa!")
end

local function run()
  local success, err = xpcall(function()
    check_startup()
    local messages_before, notified_before, noice_before = message_errors(), #captured_errors, #noice_errors()
    run_suites()
    check_late_errors(messages_before, notified_before, noice_before)
  end, debug.traceback)
  if not success then
    fail("smoke harness crashed", err)
  end
  finish()
end

-- Safety net: never hang CI.
local timer = uv.new_timer()
timer:start(
  60000,
  0,
  vim.schedule_wrap(function()
    fail("smoke timed out", "VeryLazy never fired or a check hung")
    finish()
  end)
)

-- lazy.nvim fires VeryLazy from UIEnter, which never happens without a UI.
-- Emulate the UI attaching so VeryLazy plugins load exactly as in a real session.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      if not vim.g.did_very_lazy then
        vim.api.nvim_exec_autocmds("UIEnter", { modeline = false })
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    -- Let scheduled/deferred startup work (lifecycle steps, commands) settle.
    vim.defer_fn(run, 500)
  end,
})
