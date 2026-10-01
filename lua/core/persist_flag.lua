-- Factory for a boolean feature flag persisted as JSON under stdpath("data").
--
-- core.ai_toggle and core.session_toggle were the same module written twice:
-- load a one-key JSON file, expose is_enabled/enable/disable/toggle/status, and
-- notify with a per-feature sentence. Only the filename, the default, and the
-- wording differed. This factory holds the shared behaviour so those modules
-- are just their configuration.
--
-- Not to be confused with core.lang.state, which persists a *map* of
-- per-language flags and has its own registry and notifications.

local persist = require "core.persist"

local M = {}

---@class PersistFlagOpts
---@field filename string  Basename under stdpath("data"), e.g. "ai_config.json"
---@field default boolean  Value used when the file does not exist yet
---@field label string     Subject of the notification, e.g. "AI features"
---@field hint string      Trailing sentence, e.g. "Restart Neovim to apply changes."
---@field on_set? fun(enabled: boolean)  Called after a successful write
---@field restart? boolean  Offer :restart after a change (core.restart)

---Create a persisted boolean flag module.
---@param opts PersistFlagOpts
---@return table
function M.new(opts)
  local flag = {}
  local config_path = vim.fn.stdpath "data" .. "/" .. opts.filename

  --- Read the persisted state.
  ---@return boolean
  function flag.is_enabled()
    local config = persist.load_json(config_path, {})
    -- Explicit nil check rather than `~= false`: an absent key must fall back
    -- to the module's default, which is not always `true`.
    if config.enabled == nil then
      return opts.default
    end
    return config.enabled == true
  end

  ---@param enabled boolean
  local function set(enabled)
    persist.save_json(config_path, { enabled = enabled })
    if opts.on_set then
      opts.on_set(enabled)
    end
    vim.notify(
      string.format(
        "%s %s %s. %s",
        enabled and "✓" or "✗",
        opts.label,
        enabled and "enabled" or "disabled",
        opts.hint
      ),
      vim.log.levels.INFO
    )
    if opts.restart then
      require("core.restart").offer(opts.label)
    end
  end

  function flag.enable()
    set(true)
  end

  function flag.disable()
    set(false)
  end

  function flag.toggle()
    set(not flag.is_enabled())
  end

  --- Current state as a word, for status commands.
  ---@return string
  function flag.status()
    return flag.is_enabled() and "enabled" or "disabled"
  end

  return flag
end

return M
