-- Central, user-facing behaviour switches.
--
-- Precedence (highest first):
--   1. runtime overrides from M.set()/M.toggle() — session only, never persisted
--   2. lua/user/settings.lua (optional, gitignored; see settings.example.lua)
--   3. M.defaults below
--
-- Tables merge key by key; lists (e.g. langs.default) replace wholesale, so a
-- user list is never merged index-by-index with the default one. Unknown keys
-- in the user file are reported once, which catches typos early.
--
-- Feature flags that the user flips from inside Neovim and expects to survive a
-- restart (AI, session persistence, language packs) are persisted by their own
-- modules; the values here are only their defaults.
local M = {}

M.defaults = {
  lsp = {
    auto_start = true, -- start servers of enabled language packs automatically
  },
  format = {
    on_save = true, -- conform format-on-save (toggle: <leader>uf, buffer: <leader>uF)
    timeout_ms = 1000,
  },
  lint = {
    enabled = true, -- nvim-lint on read/write/insert-leave (toggle: <leader>ul)
  },
  install = {
    -- Install missing Mason tools and treesitter parsers of ENABLED language
    -- packs the first time one of their files is opened (needs network, never
    -- runs headless). :LangInstall always works.
    auto = true,
  },
  langs = {
    -- Packs enabled on a fresh install; :LangEnable/:LangPanel persist changes
    -- per machine. The full list is in lua/langs/.
    default = { "lua", "bash", "json", "yaml", "toml", "markdown" },
    hint_disabled = true, -- suggest :LangEnable when opening a file of a disabled pack
    options = {}, -- per-pack option defaults, e.g. { typescript = { server = "tsc" } }
  },
  session = {
    persistence = true, -- default for :SessionToggle (auto save + restore per cwd)
  },
  cleanup = {
    -- Startup sweep of stale logs/swap/undo/views (core/cleanup.lua). Off by
    -- default because it deletes files (undo history older than 30 days);
    -- :CleanupNvim always works.
    auto = false,
  },
  ai = {
    enabled = false, -- default for :AIToggle; AI plugins need accounts and network
  },
  editorconfig = true, -- honour .editorconfig (Neovim built-in, safe subset of options)
  theme = {
    -- Used when nothing is saved yet and by <leader>cd/<leader>cl before a
    -- dark/light theme was picked. Names: :ThemeSwitch or lua/core/theme.lua.
    dark = "catppuccin-mocha",
    light = "catppuccin-latte",
  },
}

local merged ---@type table?
local overrides = {} ---@type table<string, any>

local function is_list(v)
  return type(v) == "table" and (vim.islist(v) or next(v) == nil)
end

---"list", "map", "table" (empty: either) or the Lua type.
local function shape(v)
  if type(v) ~= "table" or next(v) == nil then
    return type(v)
  end
  return vim.islist(v) and "list" or "map"
end

---Does a user value fit where the default is?
local function compatible(default, value)
  local a, b = shape(default), shape(value)
  return a == b or (type(default) == "table" and type(value) == "table" and (a == "table" or b == "table"))
end

---Merge `src` into a copy of `dst`. Lists replace; maps merge recursively.
---@param dst table
---@param src table
---@param path string
---@param unknown string[]
local function merge(dst, src, path, unknown)
  local result = vim.deepcopy(dst)
  for key, value in pairs(src) do
    local here = path == "" and tostring(key) or (path .. "." .. tostring(key))
    local current = dst[key]
    if current == nil then
      unknown[#unknown + 1] = here
      result[key] = value
    elseif not compatible(current, value) then
      -- Wrong type (e.g. langs.default = "python"): keep the default rather
      -- than let one typo stop the whole config from starting.
      unknown[#unknown + 1] = here .. " (expected " .. (shape(current) == "list" and "a list" or type(current)) .. ")"
    elseif type(current) == "table" and not is_list(current) and type(value) == "table" then
      result[key] = merge(current, value, here, unknown)
    else
      result[key] = value
    end
  end
  return result
end

local function user_settings()
  local path = vim.fn.stdpath "config" .. "/lua/user/settings.lua"
  if not vim.uv.fs_stat(path) then
    return {}
  end
  local ok, user = pcall(require, "user.settings")
  if not ok or type(user) ~= "table" then
    vim.schedule(function()
      vim.notify("lua/user/settings.lua must return a table: " .. tostring(user), vim.log.levels.WARN)
    end)
    return {}
  end
  return user
end

local function resolve()
  if merged then
    return merged
  end
  local unknown = {}
  merged = merge(M.defaults, user_settings(), "", unknown)
  if #unknown > 0 then
    vim.schedule(function()
      vim.notify("Ignored in lua/user/settings.lua: " .. table.concat(unknown, ", "), vim.log.levels.WARN)
    end)
  end
  return merged
end

---Read a setting by dotted path, e.g. get("format.on_save").
---@param path string
---@return any
function M.get(path)
  if overrides[path] ~= nil then
    return overrides[path]
  end
  local node = resolve()
  for part in path:gmatch "[^.]+" do
    if type(node) ~= "table" then
      return nil
    end
    node = node[part]
  end
  return node
end

---Override a setting for the rest of this session.
---@param path string
---@param value any
function M.set(path, value)
  overrides[path] = value
end

---Flip a boolean setting for the rest of this session.
---@param path string
---@return boolean new_value
function M.toggle(path)
  local value = not M.get(path)
  M.set(path, value)
  return value
end

return M
