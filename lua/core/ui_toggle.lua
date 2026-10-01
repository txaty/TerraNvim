-- UI toggle module with JSON file persistence
-- Stores state in ~/.local/share/nvim/ui_config.json (source of truth)
-- Also maintains vim.g.ui_* globals for session compatibility and runtime access
local M = {}

local persist = require "core.persist"

-- Default states (used when no config file exists)
local defaults = {
  wrap = false,
  spell = false,
  number = true,
  relativenumber = true,
  conceallevel = 2,
  dim = false, -- Snacks dim mode (session-persistent)
  diagnostic_lines = false, -- virtual_lines diagnostics (Zed-style)
}

-- JSON config file path
local config_path = vim.fn.stdpath "data" .. "/ui_config.json"

-- The subset of `defaults` that maps 1:1 onto window-local vim options.
-- `dim` and `diagnostic_lines` are excluded: they are not window
-- options and are applied through their own code paths.
local WINDOW_OPTIONS = { "wrap", "spell", "number", "relativenumber", "conceallevel" }

-- Note: load is called lazily in init() or on first access
-- This avoids disk I/O at require-time for faster startup

local initialized = false

--- Initialize UI state from JSON config, session globals, or defaults
--- Precedence: JSON file > vim.g global (session) > default
--- Idempotent: safe to call multiple times (early returns after first run)
function M.init()
  if initialized then
    return
  end
  initialized = true

  local cached_config = persist.load_json(config_path, {})

  for opt, default in pairs(defaults) do
    local global_key = "ui_" .. opt
    -- JSON takes precedence, then session global, then default
    if cached_config[opt] ~= nil then
      vim.g[global_key] = cached_config[opt]
    elseif vim.g[global_key] == nil then
      vim.g[global_key] = default
    end
  end
end

--- Apply the current UI state to one window.
---
--- No time-based throttle: an earlier version skipped any call landing within
--- 50ms of the previous one, which meant a window opened during a burst (a
--- split, or session restore) kept stale settings until the next event. The
--- per-option equality check below is what actually avoids redundant work —
--- writing a window option is only done when the value really differs.
---@param win? number Window handle (0 for current window)
function M.apply(win)
  win = (win == nil or win == 0) and vim.api.nvim_get_current_win() or win
  if not initialized then
    M.init()
  end

  -- Only ordinary file windows follow the UI toggles: floats (pickers, hover,
  -- notifications) and special buffers (terminals, help, quickfix, plugin UIs)
  -- set their own window options and must not get numbers/wrap/spell forced on.
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" then
    return
  end

  for _, opt in ipairs(WINDOW_OPTIONS) do
    local want = vim.g["ui_" .. opt]
    -- Prose buffers (markdown, tex, ...) always wrap; see vim.b.prose_wrap.
    if opt == "wrap" and vim.b[buf].prose_wrap then
      want = true
    end
    if want ~= nil and vim.wo[win][opt] ~= want then
      vim.wo[win][opt] = want
    end
  end
end

--- Toggle a UI option
---@param opt string Option name (wrap, spell, number, relativenumber, conceallevel, dim, diagnostic_lines)
function M.toggle(opt)
  local global_key = "ui_" .. opt
  local current = vim.g[global_key]
  local new_value

  if opt == "conceallevel" then
    -- Toggle between 0 and 2
    new_value = current == 0 and 2 or 0
  else
    -- Boolean toggle
    new_value = not current
  end

  -- Special handling for dim: requires Snacks to be loaded
  if opt == "dim" then
    M.set_dim(new_value)
    return
  end

  -- Special handling for diagnostic_lines: swap vim.diagnostic.config modes
  if opt == "diagnostic_lines" then
    vim.g[global_key] = new_value
    local cached_config = persist.load_json(config_path, {})
    cached_config[opt] = new_value
    persist.save_json(config_path, cached_config)

    if new_value then
      -- Disable tiny-inline-diagnostic when switching to virtual_lines
      local tid_ok, tid = pcall(require, "tiny-inline-diagnostic")
      if tid_ok and tid.disable then
        tid.disable()
      end
      vim.diagnostic.config { virtual_text = false, virtual_lines = true }
    else
      vim.diagnostic.config { virtual_lines = false }
      -- Re-enable tiny-inline-diagnostic if available, otherwise fall back to default virtual_text
      local tid_ok, tid = pcall(require, "tiny-inline-diagnostic")
      if tid_ok and tid.enable then
        vim.diagnostic.config { virtual_text = false }
        tid.enable()
      else
        vim.diagnostic.config { virtual_text = { prefix = "●", spacing = 4 } }
      end
    end

    local display = new_value and "virtual_lines" or "virtual_text"
    vim.notify(string.format("UI: diagnostics = %s", display), vim.log.levels.INFO)
    return
  end

  -- Update global
  vim.g[global_key] = new_value

  -- Persist to JSON
  local cached_config = persist.load_json(config_path, {})
  cached_config[opt] = new_value
  persist.save_json(config_path, cached_config)

  -- Apply to current window (for standard vim options)
  vim.wo[opt] = new_value

  -- Notify user
  local display = type(new_value) == "boolean" and (new_value and "on" or "off") or tostring(new_value)
  vim.notify(string.format("UI: %s = %s", opt, display), vim.log.levels.INFO)
end

--- Set dim state explicitly (idempotent)
---@param enabled boolean
---@param opts? table {persist?: boolean, notify?: boolean}
function M.set_dim(enabled, opts)
  opts = opts or {}
  local persist_enabled = opts.persist ~= false
  local notify_enabled = opts.notify ~= false

  if not initialized then
    M.init()
  end

  vim.g.ui_dim = enabled

  if persist_enabled then
    local cached_config = persist.load_json(config_path, {})
    cached_config.dim = enabled
    persist.save_json(config_path, cached_config)
  end

  local snacks_ok, Snacks = pcall(require, "snacks")
  if not snacks_ok then
    if notify_enabled then
      vim.notify("Snacks.nvim not available", vim.log.levels.WARN)
    end
    return
  end

  local current = Snacks.dim.enabled
  if current ~= enabled then
    if enabled then
      Snacks.dim.enable()
    else
      Snacks.dim.disable()
    end
  end

  if notify_enabled then
    local display = enabled and "on" or "off"
    vim.notify(string.format("UI: dim = %s", display), vim.log.levels.INFO)
  end
end

--- Every toggleable option name, sorted.
--- Derived from `defaults` so callers (e.g. :UIStatus) cannot drift out of sync
--- with the actual set of options the way a hand-maintained list did.
---@return string[]
function M.option_names()
  local names = vim.tbl_keys(defaults)
  table.sort(names)
  return names
end

--- Get current state of an option
--- Auto-initializes on first access if init() hasn't been called yet
---@param opt string Option name
---@return any
function M.get(opt)
  if not initialized then
    M.init()
  end
  return vim.g["ui_" .. opt]
end

--- Apply UI state to ALL windows (used after session restore).
---
--- Delegates to M.apply so there is exactly one definition of "what the UI
--- state means for a window". The previous inline version used
--- `vim.g.ui_number or true`, which evaluates to `true` whenever the user had
--- turned the option off — silently resurrecting disabled options on restore.
function M.apply_all()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      M.apply(win)
    end
  end
end

--- Apply dim state based on persisted preference
--- Called during lifecycle init after Snacks has loaded
--- Snacks loads early (priority=1000, lazy=false) so it's available at VimEnter
function M.apply_dim()
  if not initialized then
    M.init()
  end

  M.set_dim(vim.g.ui_dim, { persist = false, notify = false })
end

return M
