-- Installs the Mason packages and treesitter parsers of language packs.
--
-- Mason has no ensure_installed option and nvim-treesitter's main branch
-- ignores one in setup(), so this module is the single installer. Missing
-- items are detected with fs_stat, so mason.nvim is not even loaded when
-- everything is present.
--
-- Automatic installs (settings install.auto) happen the first time a file of an
-- enabled pack is opened, only with a UI attached and never in smoke tests;
-- :LangInstall is the explicit entry point.
local lang = require "core.lang"

local M = {}

local inflight = {} ---@type table<string, true> mason packages being installed
local inflight_parsers = {} ---@type table<string, true>
-- Parsers whose build failed this session. Automatic installs skip them:
-- otherwise every failed build re-attaches the buffer, which starts the
-- install again, in an endless download/compile loop (offline, old CLI, no cc).
local failed_parsers = {} ---@type table<string, true>
local hinted = {} ---@type table<string, true>

local function notify(msg, level)
  vim.schedule(function()
    vim.notify(msg, level or vim.log.levels.INFO, { title = "Language packs" })
  end)
end

---@param pkg string
---@return boolean
function M.mason_installed(pkg)
  return vim.uv.fs_stat(vim.fn.stdpath "data" .. "/mason/packages/" .. pkg) ~= nil
end

---Mason packages of the given packs that are not installed.
---@param list? string[]
---@return string[]
function M.missing_tools(list)
  return vim.tbl_filter(function(pkg)
    return not M.mason_installed(pkg)
  end, lang.collect.tools(list))
end

---@return table<string, true>
local function installed_parsers()
  local ok, config = pcall(require, "nvim-treesitter.config")
  local set = {}
  for _, parser in ipairs(ok and config.get_installed "parsers" or {}) do
    set[parser] = true
  end
  return set
end

---Treesitter parsers of the given packs that are not installed.
---@param list? string[]
---@return string[]
function M.missing_parsers(list)
  local have = installed_parsers()
  return vim.tbl_filter(function(parser)
    return not have[parser]
  end, lang.collect.parsers(list))
end

---Is an unattended install allowed right now?
---@return boolean
function M.auto_allowed()
  return require("core.settings").get "install.auto" == true and not vim.g.nvim_smoke and #vim.api.nvim_list_uis() > 0
end

---Install Mason packages. on_done(failed_count) runs after all finish.
---@param pkgs string[]
---@param on_done? fun(failed: integer)
function M.tools(pkgs, on_done)
  pkgs = vim.tbl_filter(function(pkg)
    return not inflight[pkg] and not M.mason_installed(pkg)
  end, pkgs)
  if #pkgs == 0 then
    if on_done then
      on_done(0)
    end
    return
  end
  for _, pkg in ipairs(pkgs) do
    inflight[pkg] = true
  end

  local registry = require "mason-registry"
  registry.refresh(vim.schedule_wrap(function(refreshed)
    local remaining, failed = #pkgs, 0
    local function finish(pkg, ok, err)
      inflight[pkg] = nil
      if ok then
        require("core.lang.lsp").on_installed(pkg)
      else
        failed = failed + 1
        if err then
          notify(("Failed to install %s: %s"):format(pkg, err), vim.log.levels.WARN)
        end
      end
      remaining = remaining - 1
      if remaining == 0 and on_done then
        on_done(failed)
      end
    end

    for _, pkg in ipairs(pkgs) do
      local found, package = pcall(registry.get_package, pkg)
      if not found then
        finish(
          pkg,
          false,
          refreshed == false and "Mason registry unavailable (offline?)" or "not in the Mason registry"
        )
      elseif not package:is_installable() then
        finish(pkg, false) -- e.g. a macOS-only tool on Linux: skip quietly
      elseif package:is_installing() then
        -- Started elsewhere (:MasonInstall). Mason builds in a staging dir and
        -- moves it into packages/ at the end, so wait for its result instead
        -- of treating it as installed.
        package:once(
          "install:success",
          vim.schedule_wrap(function()
            finish(pkg, true)
          end)
        )
        package:once(
          "install:failed",
          vim.schedule_wrap(function()
            finish(pkg, false)
          end)
        )
      else
        notify("Installing " .. pkg .. " …")
        local started, err = pcall(
          package.install,
          package,
          {},
          vim.schedule_wrap(function(ok, result)
            finish(pkg, ok, not ok and tostring(result) or nil)
            if ok then
              notify("Installed " .. pkg)
            end
          end)
        )
        if not started then
          finish(pkg, false, tostring(err))
        end
      end
    end
  end))
end

---Install treesitter parsers (needs the tree-sitter CLI and a C compiler).
---Parsers that failed earlier in the session are skipped unless opts.force.
---@param parsers string[]
---@param on_done? fun()
---@param opts? {force?: boolean}
---@return table? task nvim-treesitter async task (for :wait())
function M.parsers(parsers, on_done, opts)
  opts = opts or {}
  local have = installed_parsers()
  parsers = vim.tbl_filter(function(parser)
    return not have[parser] and not inflight_parsers[parser] and (opts.force or not failed_parsers[parser])
  end, parsers)
  if #parsers == 0 then
    if on_done then
      on_done()
    end
    return
  end
  if vim.fn.executable "tree-sitter" == 0 then
    if not hinted.cli then
      hinted.cli = true
      notify(
        "tree-sitter CLI not found: cannot build parsers ("
          .. table.concat(parsers, ", ")
          .. "). Install it with your package manager or :MasonInstall tree-sitter-cli.",
        vim.log.levels.WARN
      )
    end
    return
  end
  for _, parser in ipairs(parsers) do
    inflight_parsers[parser] = true
    failed_parsers[parser] = nil
  end
  local task = require("nvim-treesitter").install(parsers, { summary = true })
  task:await(vim.schedule_wrap(function()
    local now = installed_parsers()
    local done, failed = {}, {}
    for _, parser in ipairs(parsers) do
      inflight_parsers[parser] = nil
      if now[parser] then
        done[parser] = true
      else
        failed_parsers[parser] = true
        failed[#failed + 1] = parser
      end
    end
    if #failed > 0 then
      notify(
        ("Parser build failed: %s. :checkhealth core.lang shows the prerequisites; :LangInstall retries."):format(
          table.concat(failed, ", ")
        ),
        vim.log.levels.WARN
      )
    end
    -- Start highlighting in buffers opened before their parser existed. Never
    -- install from here: that is what used to loop on failed builds.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local ft = vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype or ""
      if ft ~= "" and done[vim.treesitter.language.get_lang(ft) or ft] then
        require("core.lang.treesitter").attach(buf, { install = false })
      end
    end
    if on_done then
      on_done()
    end
  end))
  return task
end

---Install everything a pack needs.
---@param name string
---@param opts? {sync?: boolean}
function M.ensure_pack(name, opts)
  M.ensure({ name }, opts)
end

---Install everything the given packs need (plus the base parsers). With
---sync = true, block until done and return the number of failures (headless
---bootstrap: `nvim --headless "+LangInstall!" +qa`).
---@param list string[]
---@param opts? {sync?: boolean, force?: boolean}
---@return integer? failed only with sync = true
function M.ensure(list, opts)
  opts = opts or {}
  local tools = M.missing_tools(list)
  local tools_failed ---@type integer?
  M.tools(tools, function(failed)
    tools_failed = failed
  end)
  local parsers = M.missing_parsers(list)
  vim.list_extend(parsers, require("core.lang.treesitter").base_parsers)
  local task = M.parsers(parsers, nil, { force = opts.force })
  if not opts.sync then
    return
  end
  if task then
    task:pwait(300000) -- pwait: a timeout or error must not skip the tool wait
  end
  -- Also wait for installs of the same packages started earlier (auto-install).
  vim.wait(600000, function()
    if tools_failed == nil then
      return false
    end
    for _, pkg in ipairs(tools) do
      if inflight[pkg] then
        return false
      end
    end
    return true
  end, 200)
  local failed = #M.missing_tools(list) + #M.missing_parsers(list)
  return failed
end

local seen = {} ---@type table<string, true> packs already checked this session

---First file of an enabled pack opened this session: install what is missing.
---@param name string
function M.on_first_use(name)
  if seen[name] then
    return
  end
  seen[name] = true
  if not M.auto_allowed() then
    return
  end
  vim.schedule(function()
    M.ensure { name }
  end)
end

return M
