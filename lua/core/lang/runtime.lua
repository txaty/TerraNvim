-- Per-buffer side of language packs: one FileType autocmd that applies the
-- enabled packs' buffer-local keymaps (and which-key groups) and filetype
-- options, triggers first-use installs, and hints when a file belongs to a
-- disabled pack. Also live-(de)activates packs for :LangEnable/:LangDisable.
local lang = require "core.lang"

local M = {}

local group = vim.api.nvim_create_augroup("core_lang_runtime", { clear = true })
local wk_queue = {} ---@type table[]
local hinted = {} ---@type table<string, true>
local applied = {} ---@type table<integer, {pack: string, mode: string|string[], lhs: string}[]>

---Register which-key specs without loading which-key early: specs are queued
---until whichkey.lua's config() calls flush().
---@param spec table
function M.wk_add(spec)
  if package.loaded["which-key"] then
    require("which-key").add(spec)
  else
    wk_queue[#wk_queue + 1] = spec
  end
end

function M.wk_flush()
  local queued = wk_queue
  wk_queue = {}
  local wk = require "which-key"
  for _, spec in ipairs(queued) do
    if not spec.buffer or vim.api.nvim_buf_is_valid(spec.buffer) then
      wk.add(spec)
    end
  end
end

---@param key table pack key spec
---@param pack table
---@param ft string
local function key_applies(key, pack, ft)
  local fts = key.ft or pack.filetypes or {}
  fts = type(fts) == "string" and { fts } or fts
  return vim.tbl_contains(fts, ft)
end

---@param buf integer
---@param name string pack name
local function apply_pack(buf, name)
  local ft = vim.bo[buf].filetype
  local pack = lang.get(name)

  local options = (lang.field(name, "ft_options") or {})[ft]
  for option, value in pairs(options or {}) do
    vim.opt_local[option] = value
  end
  -- A pack that forces wrap (prose) wins over the global wrap toggle, which
  -- core.ui_toggle re-applies on BufWinEnter.
  if options and options.wrap == true then
    vim.b[buf].prose_wrap = true
  end

  for _, key in ipairs(lang.field(name, "keys") or {}) do
    if key_applies(key, pack, ft) and (not key.cond or key.cond(buf)) then
      if key.group then
        M.wk_add { key[1], group = key.group, icon = key.icon, buffer = buf, mode = key.mode }
      elseif key[2] then
        local mode = key.mode or "n"
        vim.keymap.set(mode, key[1], key[2], {
          buffer = buf,
          desc = key.desc,
          expr = key.expr,
          silent = key.silent ~= false,
        })
        applied[buf] = applied[buf] or {}
        table.insert(applied[buf], { pack = name, mode = mode, lhs = key[1] })
      end
    end
  end
end

---Packs that contribute to a filetype: its owner plus packs whose keys or
---ft_options name it (e.g. rust's crates keys on toml).
---@param ft string
---@return string[]
local function contributors(ft)
  local out = {}
  for _, name in ipairs(lang.enabled()) do
    local pack = lang.get(name)
    local options = lang.field(name, "ft_options")
    local contributes = vim.tbl_contains(pack.filetypes or {}, ft) or (options and options[ft] ~= nil)
    if not contributes then
      for _, key in ipairs(lang.field(name, "keys") or {}) do
        if key_applies(key, pack, ft) then
          contributes = true
          break
        end
      end
    end
    if contributes then
      out[#out + 1] = name
    end
  end
  return out
end

---@param buf integer
local function on_filetype(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return
  end
  local ft = vim.bo[buf].filetype
  local owner = lang.owner(ft)

  if owner and not lang.is_enabled(owner) then
    if not hinted[owner] and require("core.settings").get "langs.hint_disabled" and #vim.api.nvim_list_uis() > 0 then
      hinted[owner] = true
      vim.schedule(function()
        vim.notify(
          ("%s support is off. Enable it with :LangEnable %s (or <leader>Lp)."):format(
            lang.get(owner).title or owner,
            owner
          ),
          vim.log.levels.INFO,
          { title = "Language packs" }
        )
      end)
    end
  end

  for _, name in ipairs(contributors(ft)) do
    apply_pack(buf, name)
  end

  if owner and lang.is_enabled(owner) then
    require("core.lang.install").on_first_use(owner)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(ev)
      on_filetype(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(ev)
      applied[ev.buf] = nil
    end,
  })
end

---@param name string
---@return integer[] loaded buffers whose filetype the pack owns
local function owned_buffers(name)
  local fts = lang.get(name).filetypes or {}
  return vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf) and vim.tbl_contains(fts, vim.bo[buf].filetype)
  end, vim.api.nvim_list_bufs())
end

---Apply a newly enabled pack to the running session as far as possible, and
---offer :restart for the parts that only take effect on startup.
---@param name string
function M.activate(name)
  local list = { name }
  local lsp = require "core.lang.lsp"
  if lsp.ready then -- otherwise nvim-lspconfig's config() picks the pack up when it loads
    lsp.configure(list)
  end
  if package.loaded.conform then
    local conform = require "conform"
    conform.formatters_by_ft = vim.tbl_extend("force", conform.formatters_by_ft, lang.collect.formatters_by_ft(list))
    conform.formatters = vim.tbl_extend("force", conform.formatters, lang.collect.formatters(list))
  end
  if package.loaded.lint then
    require("core.lang.lint").apply(list)
  end
  if package.loaded.dap then
    for _, entry in ipairs(lang.collect.dap(list)) do
      pcall(entry.fn, require "dap", lang.opts(entry.pack))
    end
  end
  for _, buf in ipairs(owned_buffers(name)) do
    on_filetype(buf)
    require("core.lang.treesitter").attach(buf)
  end
  require("core.lang.install").ensure(list)

  local pack = lang.get(name)
  local needs_restart = pack.test ~= nil or pack.cmp ~= nil
  local plugins = require("lazy.core.config").plugins
  for _, spec in ipairs(pack.plugins or {}) do
    local short = type(spec) == "table" and spec.name or (type(spec) == "string" and spec or spec[1]):match "[^/]+$"
    if not plugins[short] then
      needs_restart = true
    end
  end
  if needs_restart then
    require("core.restart").offer((pack.title or name) .. " plugins")
  end
end

---Undo what activate() can undo live; plugins stay loaded until restart.
---@param name string
function M.deactivate(name)
  local list = { name }
  require("core.lang.lsp").disable(list)
  if package.loaded.conform then
    local conform = require "conform"
    for ft in pairs(lang.collect.formatters_by_ft(list)) do
      conform.formatters_by_ft[ft] = nil
    end
  end
  if package.loaded.lint then
    local lint = require "lint"
    for ft in pairs(lang.collect.linters_by_ft(list)) do
      lint.linters_by_ft[ft] = nil
    end
  end
  for buf, maps in pairs(applied) do
    for i = #maps, 1, -1 do
      local map = maps[i]
      if map.pack == name and vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.keymap.del, map.mode, map.lhs, { buffer = buf })
        table.remove(maps, i)
      end
    end
  end
end

return M
