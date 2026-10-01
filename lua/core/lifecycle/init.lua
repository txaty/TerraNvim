-- Lifecycle orchestrator
-- Single point of control for post-startup initialization
-- Ensures deterministic ordering of startup tasks
--
-- DEBUG LOGGING:
--   vim.g.debug_lifecycle = true   -- log lifecycle steps
--   vim.g.debug_plugin_load = true -- log every plugin load (via lazy.nvim)
--
-- Example: nvim --cmd "let g:debug_lifecycle=1" --cmd "let g:debug_plugin_load=1"
local M = {}

local debug_lifecycle = vim.g.debug_lifecycle or false
local debug_plugin_load = vim.g.debug_plugin_load or false
local t0 = 0
local load_log = {} -- Accumulated plugin load events for summary

local function log(msg)
  if debug_lifecycle then
    local elapsed_ms = (vim.uv.hrtime() - t0) / 1e6
    vim.schedule(function()
      vim.notify(string.format("[lifecycle +%.1fms] %s", elapsed_ms, msg), vim.log.levels.DEBUG)
    end)
  end
end

--- Setup lazy.nvim plugin load event logging
--- Registers a User:LazyLoad listener. No need to require lazy.nvim first —
--- the autocmd simply waits for lazy to emit the event, which happens after
--- core.lazy bootstraps lazy.nvim (the next step in core/init.lua).
local function setup_plugin_load_logging()
  if not debug_plugin_load then
    return
  end

  -- Register the listener immediately; lazy.nvim will emit LazyLoad events
  -- once it starts loading plugins during and after VimEnter.
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyLoad",
    callback = function(ev)
      local elapsed_ms = (vim.uv.hrtime() - t0) / 1e6
      local plugin = ev.data or "unknown"
      table.insert(load_log, { time = elapsed_ms, plugin = plugin })
      vim.schedule(function()
        vim.notify(string.format("[plugin +%.1fms] %s", elapsed_ms, plugin), vim.log.levels.DEBUG)
      end)
    end,
  })
end

--- Print summary of plugin load order (for verification)
function M.print_load_summary()
  if #load_log == 0 then
    vim.notify("No plugin load events recorded. Enable with vim.g.debug_plugin_load = true", vim.log.levels.WARN)
    return
  end

  local lines = { "Plugin Load Order:" }
  for i, entry in ipairs(load_log) do
    table.insert(lines, string.format("  %2d. +%6.1fms  %s", i, entry.time, entry.plugin))
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

--- Verify critical load order assumptions
--- Only runs when debug mode is enabled (vim.g.debug_lifecycle or vim.g.debug_plugin_load)
local function verify_load_order()
  if not (vim.g.debug_lifecycle or vim.g.debug_plugin_load) then
    return
  end

  local checks = {
    -- NOTE: dropbar vs lspconfig ordering is intentionally NOT checked here.
    -- Both load on BufReadPre; dropbar hooks into LSP via its own LspAttach autocmd
    -- (registered when dropbar loads) and does not need to precede lspconfig.
    -- LSP servers attach asynchronously after lspconfig.setup(), so dropbar always
    -- has its handler registered before any server attaches, regardless of which
    -- plugin's config() ran first.  The navic-era requirement (navic.attach called
    -- inside lspconfig's LspAttach) no longer applies.
    {
      name = "colorscheme set before UI plugins",
      check = function()
        if not vim.g.colors_name or vim.g.colors_name == "" then
          return false, "No colorscheme set (vim.g.colors_name is nil/empty)"
        end
        return true
      end,
    },
    {
      name = "snacks.nvim loads early (priority=1000, lazy=false)",
      check = function()
        -- Snacks should be first or near-first in load log
        if #load_log > 0 then
          local snacks_idx
          for i, entry in ipairs(load_log) do
            if entry.plugin == "snacks.nvim" then
              snacks_idx = i
              break
            end
          end
          -- Snacks should be in first 3 positions (allow for some variance)
          if snacks_idx and snacks_idx > 3 then
            return false, string.format("snacks.nvim loaded at position %d (expected 1-3)", snacks_idx)
          end
        end
        return true
      end,
    },
    {
      name = "language packs load without errors",
      check = function()
        local errors = require("core.lang").load_errors()
        if next(errors) then
          return false, "failed packs: " .. table.concat(vim.tbl_keys(errors), ", ")
        end
        return true
      end,
    },
  }

  local all_passed = true
  for _, check in ipairs(checks) do
    local ok, err = check.check()
    if not ok then
      all_passed = false
      vim.notify(
        string.format("[lifecycle] ASSERTION FAILED: %s - %s", check.name, err or "unknown"),
        vim.log.levels.ERROR
      )
    else
      log(string.format("✓ assertion passed: %s", check.name))
    end
  end

  if all_passed then
    log "✓ all load order assertions passed"
  end
end

--- Re-trigger buffer events for session-restored buffers.
--- persistence.nvim restores buffers via `:source` which does NOT fire
--- BufReadPre/BufReadPost/FileType events.  Lazy-loaded plugins (LSP,
--- treesitter, gitsigns, lint, …) depend on these events to load and
--- attach.  This function emits the events synthetically so every
--- buffer gets full editor support.
---
---@param on_complete? function Optional callback invoked after all events are triggered
local function retrigger_buffer_events(on_complete)
  vim.schedule(function()
    local bufs = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
        table.insert(bufs, buf)
      end
    end
    if #bufs == 0 then
      if on_complete then
        on_complete()
      end
      return
    end

    -- Phase 1: Emit BufReadPre/BufReadPost so lazy.nvim loads plugins
    -- that trigger on these events (LSP, treesitter, gitsigns, lint, …).
    for _, buf in ipairs(bufs) do
      pcall(vim.api.nvim_exec_autocmds, "BufReadPre", { buffer = buf })
    end
    for _, buf in ipairs(bufs) do
      pcall(vim.api.nvim_exec_autocmds, "BufReadPost", { buffer = buf, modeline = false })
    end

    -- Phase 2: Emit FileType so servers registered with vim.lsp.enable()
    -- (which listens on FileType) attach to the restored buffers.
    for _, buf in ipairs(bufs) do
      local ft = vim.bo[buf].filetype
      if ft and ft ~= "" then
        pcall(vim.api.nvim_exec_autocmds, "FileType", { buffer = buf, pattern = ft })
      end
    end

    -- Signal completion to allow dependent operations to proceed
    if on_complete then
      -- Defer callback one more tick to ensure plugin handlers have run
      vim.schedule(on_complete)
    end
  end)
end

-- ============================================================================
-- Declarative Lifecycle Steps
-- ============================================================================
-- Each step declares its timing mode:
--   "sync"            — runs immediately in order
--   "scheduled"       — runs on next vim.schedule tick
--   "very_lazy"       — waits for User:VeryLazy event
--   "deferred"        — runs after delay_ms milliseconds
--
-- Steps with `condition` are skipped when the condition returns false.
-- Steps with `needs_session` only run when a session was restored.
-- ============================================================================

local ok_ui, ui_toggle

local steps = {
  {
    name = "colorscheme",
    mode = "sync",
    fn = function()
      require("core.lifecycle.colorscheme").restore()
    end,
  },
  {
    name = "ui_state init",
    mode = "sync",
    -- Must run before session restore so that plugins loading on BufReadPre
    -- (e.g., lsp.lua reading vim.g.ui_diagnostic_lines) see correct state.
    fn = function()
      ok_ui, ui_toggle = pcall(require, "core.ui_toggle")
      if ok_ui then
        ui_toggle.init()
      end
    end,
  },
  {
    name = "session restore",
    mode = "sync",
    fn = function(ctx)
      -- :restart (Neovim 0.12) saves and restores its own session; restoring
      -- the persistence.nvim one on top would replace it.
      if vim.v.startreason == "restart" then
        log "session restore skipped (:restart restores its own session)"
        ctx.session_restored = false
      elseif require("core.session_toggle").is_enabled() then
        ctx.session_restored = require("core.lifecycle.session").restore()
      else
        log "session restore skipped (disabled by default)"
        ctx.session_restored = false
      end
    end,
  },
  {
    name = "ui_state apply_dim",
    mode = "sync",
    -- Apply dim state after Snacks has loaded (early priority plugin)
    fn = function()
      if ok_ui then
        ui_toggle.apply_dim()
      end
    end,
  },
  {
    name = "buffer events + dependent UI",
    mode = "sync",
    -- IMPORTANT: retrigger_buffer_events() is async. UI operations that depend on
    -- fully initialized buffers (ui_toggle.apply_all, nvim_tree.auto_open) must
    -- wait until buffer events settle to avoid race conditions.
    fn = function(ctx)
      if ctx.session_restored then
        retrigger_buffer_events(function()
          log "buffer events complete"
          if ok_ui then
            ui_toggle.apply_all()
            log "ui_state apply_all (after buffer events)"
          end
          require("core.lifecycle.nvim_tree").auto_open(true)
          log "nvim_tree auto_open (after buffer events)"
        end)
      else
        require("core.lifecycle.nvim_tree").auto_open(false)
        log "nvim_tree auto_open (no session)"
      end
    end,
  },
  {
    name = "commands",
    mode = "scheduled",
    -- Deferred — rarely needed in first ms after VimEnter
    fn = function()
      local ok_cmd, commands = pcall(require, "core.commands")
      if ok_cmd and commands.register_all then
        commands.register_all()
      end
    end,
  },
  {
    name = "keymap audit",
    mode = "sync",
    -- Opt-in via vim.g.debug_keymaps for early detection before VeryLazy.
    -- keymap_audit.setup() in core/init.lua also runs full_audit() on VeryLazy.
    condition = function()
      return vim.g.debug_keymaps
    end,
    fn = function()
      require("core.keymap_audit").check()
    end,
  },
  {
    name = "reconcile",
    mode = "very_lazy",
    -- Bufferline highlights the active tab by comparing nvim_get_current_buf()
    -- against its tab list. Wait for VeryLazy (after bufferline.setup()) then
    -- move focus to a real file buffer so the tabline renders correctly.
    needs_session = true,
    fn = function()
      require("core.lifecycle.reconcile").ensure_focus()
    end,
  },
  {
    name = "cleanup",
    mode = "deferred",
    delay_ms = 2000,
    -- Deferred 2s to keep it off the startup path. core.cleanup.auto_cleanup()
    -- owns both gates (the settings `cleanup.auto` opt-in and the 24h
    -- throttle) and reports whether it actually ran; duplicating either check
    -- here is what let the enable/disable flags drift apart previously.
    fn = function()
      local ok, cleanup = pcall(require, "core.cleanup")
      if ok then
        local ran = cleanup.auto_cleanup()
        log(ran and "cleanup executed" or "cleanup skipped (disabled or throttled)")
      end
    end,
  },
  {
    name = "verify load order",
    mode = "deferred",
    delay_ms = 100,
    -- Deferred slightly to allow lazy-loaded plugins to finish loading
    fn = function()
      verify_load_order()
    end,
  },
}

--- Run the startup sequence in deterministic order
--- Called from VimEnter autocmd
function M.run_sequence()
  -- Preserve t0 if already set by setup() for plugin load logging
  if t0 == 0 then
    t0 = vim.uv.hrtime()
  end
  log "start"

  -- Shared context passed between steps (e.g., session_restored flag)
  local ctx = {}

  for _, step in ipairs(steps) do
    -- Check condition gate
    if step.condition and not step.condition() then
      log(step.name .. " skipped (condition)")
      goto continue
    end

    -- Check session gate
    if step.needs_session and not ctx.session_restored then
      log(step.name .. " skipped (no session)")
      goto continue
    end

    if step.mode == "sync" then
      step.fn(ctx)
      log(step.name)
    elseif step.mode == "scheduled" then
      local s = step
      vim.schedule(function()
        s.fn(ctx)
        log(s.name .. " (scheduled)")
      end)
    elseif step.mode == "very_lazy" then
      local s = step
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          vim.schedule(function()
            s.fn(ctx)
            log(s.name .. " (very_lazy)")
          end)
        end,
      })
    elseif step.mode == "deferred" then
      local s = step
      vim.defer_fn(function()
        s.fn(ctx)
        log(s.name .. " (deferred)")
      end, step.delay_ms or 0)
    end

    ::continue::
  end

  log "run_sequence complete (sync portion)"
end

--- Setup the lifecycle VimEnter autocmd
function M.setup()
  -- Initialize timing reference point early for plugin load logging
  t0 = vim.uv.hrtime()

  -- Setup plugin load logging before any plugins load
  setup_plugin_load_logging()

  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("NvimLifecycle", { clear = true }),
    once = true,
    nested = true,
    callback = function()
      M.run_sequence()
    end,
  })
end

return M
