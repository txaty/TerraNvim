-- Automatic cleanup for temporary and cache files
-- Minimizes disk footprint without removing any plugins
local M = {}
local persist = require "core.persist"

-- Configuration
local config = {
  log_max_age_days = 7,
  swap_max_age_days = 1,
  luac_max_age_days = 30,
  lsp_log_max_age_days = 7,
  undo_max_age_days = 30,
  session_max_age_days = 90,
  throttle_hours = 24,
}

-- Paths
local state_path = vim.fn.stdpath "state"
local cache_path = vim.fn.stdpath "cache"
local data_path = vim.fn.stdpath "data"

-- Helper: get file modification time
local function get_mtime(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.mtime.sec or nil
end

-- Helper: check if file is older than N days
local function is_older_than_days(path, days)
  local mtime = get_mtime(path)
  if not mtime then
    return false
  end
  local now = os.time()
  local age_seconds = now - mtime
  local age_days = age_seconds / (24 * 60 * 60)
  return age_days > days
end

-- Accumulated errors from safe_delete calls within a clean_all() run
local cleanup_errors = {}

-- Helper: safe delete with path validation
-- @param path string: path to delete
-- @param expected_prefix string: directory the path must reside under
-- @param flags? string: optional flags for vim.fn.delete (e.g. "rf" for recursive)
local function safe_delete(path, expected_prefix, flags)
  -- Resolve symlinks to prevent traversal via symlinked paths
  local real_path = vim.uv.fs_realpath(path)
  local real_prefix = vim.uv.fs_realpath(expected_prefix)
  if not real_path or not real_prefix then
    return false, "Could not resolve path"
  end

  -- Validate resolved path starts with resolved prefix (ensure trailing / to avoid prefix collisions)
  local norm_prefix = real_prefix:sub(-1) == "/" and real_prefix or (real_prefix .. "/")
  if not real_path:find("^" .. vim.pesc(norm_prefix)) and real_path ~= real_prefix then
    return false, "Path outside expected directory"
  end

  local ok, err = pcall(function()
    if flags then
      vim.fn.delete(path, flags)
    else
      vim.fn.delete(path)
    end
  end)
  if not ok then
    table.insert(cleanup_errors, string.format("%s: %s", path, tostring(err)))
  end
  return ok, err
end

-- Helper: list files in directory with pattern
---@param dir string
---@param pattern string? Lua pattern matched against the file name
---@return string[]
local function list_files(dir, pattern)
  local files = {}
  local handle = vim.uv.fs_scandir(dir)
  if not handle then
    return files
  end

  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if type == "file" and (not pattern or name:match(pattern)) then
      table.insert(files, dir .. "/" .. name)
    end
  end
  return files
end

-- Clean log files older than 7 days
function M.clean_logs()
  local log_files = {
    state_path .. "/lsp.log",
    state_path .. "/mason.log",
    state_path .. "/luasnip.log",
    state_path .. "/neotest.log",
    state_path .. "/nio.log",
    state_path .. "/lazy.log",
    state_path .. "/conform.log",
  }

  local cleaned = 0
  for _, log_file in ipairs(log_files) do
    if vim.fn.filereadable(log_file) == 1 then
      if is_older_than_days(log_file, config.log_max_age_days) then
        local ok = safe_delete(log_file, state_path)
        if ok then
          cleaned = cleaned + 1
        end
      end
    end
  end
  return cleaned
end

-- Clean orphaned swap files
function M.clean_swap()
  local swap_dir = state_path .. "/swap"
  if vim.fn.isdirectory(swap_dir) ~= 1 then
    return 0
  end

  local swap_files = list_files(swap_dir, "%.sw[a-z]$")
  local cleaned = 0

  for _, swap_file in ipairs(swap_files) do
    -- Check if swap file is old enough
    if is_older_than_days(swap_file, config.swap_max_age_days) then
      -- Try to determine if the original file is being edited
      -- Swap files encode the original path in their name
      local basename = vim.fn.fnamemodify(swap_file, ":t")
      -- Extract original filename from swap name (roughly)
      local original_name = basename:gsub("^%%", "/"):gsub("%%", "/"):gsub("%.sw[a-z]$", "")

      -- Check if any buffer is editing this file
      local is_active = false
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          local buf_name = vim.api.nvim_buf_get_name(buf)
          if
            buf_name == original_name or vim.fn.fnamemodify(buf_name, ":p") == vim.fn.fnamemodify(original_name, ":p")
          then
            is_active = true
            break
          end
        end
      end

      if not is_active then
        local ok = safe_delete(swap_file, swap_dir)
        if ok then
          cleaned = cleaned + 1
        end
      end
    end
  end
  return cleaned
end

-- Clean view files for non-existent source files
function M.clean_views()
  local view_dir = state_path .. "/view"
  if vim.fn.isdirectory(view_dir) ~= 1 then
    return 0
  end

  local view_files = list_files(view_dir, nil)
  local cleaned = 0

  for _, view_file in ipairs(view_files) do
    -- View filenames encode the original path with = instead of /
    local basename = vim.fn.fnamemodify(view_file, ":t")
    -- Remove the trailing =X.vim suffix
    local encoded_path = basename:gsub("=[0-9]*%.vim$", "")
    -- Decode: ~ -> home, = -> /
    local original_path = encoded_path:gsub("^~", vim.env.HOME or ""):gsub("=", "/")

    -- Check if original file still exists
    if vim.fn.filereadable(original_path) ~= 1 then
      local ok = safe_delete(view_file, view_dir)
      if ok then
        cleaned = cleaned + 1
      end
    end
  end
  return cleaned
end

-- Sweep a directory of files older than `days`.
-- clean_luac_cache/clean_undo/clean_sessions were four copies of this loop that
-- differed only in directory, age limit, and filename pattern.
---@param dir string Directory to sweep; also the prefix safe_delete validates against
---@param days number Delete files whose mtime is older than this many days
---@param pattern string? Lua pattern the file name must match (nil = all files)
---@return integer cleaned Number of files removed
local function sweep_older_than(dir, days, pattern)
  if vim.fn.isdirectory(dir) ~= 1 then
    return 0
  end

  local cleaned = 0
  for _, file in ipairs(list_files(dir, pattern)) do
    if is_older_than_days(file, days) then
      if safe_delete(file, dir) then
        cleaned = cleaned + 1
      end
    end
  end
  return cleaned
end

-- Clean luac cache files
function M.clean_luac_cache()
  return sweep_older_than(cache_path .. "/luac", config.luac_max_age_days, "%.luac$")
end

-- Clean undo files
function M.clean_undo()
  return sweep_older_than(state_path .. "/undo", config.undo_max_age_days)
end

-- Clean session files
function M.clean_sessions()
  return sweep_older_than(state_path .. "/sessions", config.session_max_age_days, "%.vim$")
end

-- Clean LSP server logs
function M.clean_lsp_logs()
  local mason_packages = data_path .. "/mason/packages"
  if vim.fn.isdirectory(mason_packages) ~= 1 then
    return 0
  end

  local cleaned = 0

  -- Find all log directories within mason packages
  local handle = vim.uv.fs_scandir(mason_packages)
  if not handle then
    return 0
  end

  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if type == "directory" then
      local log_dir = mason_packages .. "/" .. name .. "/log"
      if vim.fn.isdirectory(log_dir) == 1 then
        local log_files = list_files(log_dir, nil)
        for _, log_file in ipairs(log_files) do
          if is_older_than_days(log_file, config.lsp_log_max_age_days) then
            local ok = safe_delete(log_file, mason_packages)
            if ok then
              cleaned = cleaned + 1
            end
          end
        end
      end
    end
  end
  return cleaned
end

-- Get last cleanup timestamp
local function get_last_cleanup_time()
  local timestamp_file = state_path .. "/cleanup_last_run"
  if vim.fn.filereadable(timestamp_file) ~= 1 then
    return 0
  end

  local content = vim.fn.readfile(timestamp_file)
  if #content > 0 then
    return tonumber(content[1]) or 0
  end
  return 0
end

-- Save cleanup timestamp
local function save_cleanup_time()
  local timestamp_file = state_path .. "/cleanup_last_run"
  persist.save_lines(timestamp_file, { tostring(os.time()) })
end

--- Is startup cleanup both enabled (settings `cleanup.auto`) and outside its
--- throttle window? Single owner of that decision.
---@return boolean
function M.should_run()
  if not require("core.settings").get "cleanup.auto" then
    return false
  end

  local hours_since = (os.time() - get_last_cleanup_time()) / (60 * 60)
  return hours_since >= config.throttle_hours
end

-- Run all cleanup functions
function M.clean_all(verbose)
  cleanup_errors = {}

  local results = {
    logs = M.clean_logs(),
    swap = M.clean_swap(),
    views = M.clean_views(),
    luac = M.clean_luac_cache(),
    lsp_logs = M.clean_lsp_logs(),
    undo = M.clean_undo(),
    sessions = M.clean_sessions(),
  }

  local total = results.logs
    + results.swap
    + results.views
    + results.luac
    + results.lsp_logs
    + results.undo
    + results.sessions

  if verbose then
    local msg = string.format(
      "Cleanup complete:\n"
        .. "  - Log files: %d\n"
        .. "  - Swap files: %d\n"
        .. "  - View files: %d\n"
        .. "  - Luac cache: %d\n"
        .. "  - LSP logs: %d\n"
        .. "  - Undo files: %d\n"
        .. "  - Session files: %d\n"
        .. "  - Total: %d items removed",
      results.logs,
      results.swap,
      results.views,
      results.luac,
      results.lsp_logs,
      results.undo,
      results.sessions,
      total
    )
    if #cleanup_errors > 0 then
      msg = msg .. string.format("\n  - Errors: %d", #cleanup_errors)
      for _, err in ipairs(cleanup_errors) do
        msg = msg .. "\n    " .. err
      end
    end
    vim.notify(msg, vim.log.levels.INFO)
  elseif #cleanup_errors > 0 then
    vim.notify(
      string.format("Cleanup: %d error(s). Run :CleanupNvim for details.", #cleanup_errors),
      vim.log.levels.WARN
    )
  end

  return results, total
end

--- Auto cleanup (called on startup). Opt-in and throttled via should_run().
---@return boolean ran
function M.auto_cleanup()
  if not M.should_run() then
    return false
  end

  -- Run cleanup silently
  pcall(M.clean_all, false)
  save_cleanup_time()
  return true
end

-- Manual cleanup command (always runs, shows summary)
function M.manual_cleanup()
  M.clean_all(true)
  save_cleanup_time()
end

return M
