-- nvim-lint wiring for language packs (used by lua/plugins/tools.lua).
--
-- linters_by_ft is REPLACED by the enabled packs' table: nvim-lint ships
-- defaults (vale, jsonlint, hadolint, ...) that would otherwise run on files
-- whose pack is disabled, and mason-nvim-lint used to install them all.
local lang = require "core.lang"

local M = {}

local conditions = {} ---@type table<string, fun(ctx: {buf: integer, filename: string, dirname: string}): boolean>

---Merge the given packs' linters into nvim-lint.
---@param list? string[] pack names; default: enabled packs
function M.apply(list)
  local lint = require "lint"
  if not list then
    lint.linters_by_ft = {}
  end
  for ft, names in pairs(lang.collect.linters_by_ft(list)) do
    lint.linters_by_ft[ft] = names
  end
  for name, override in pairs(lang.collect.linters(list)) do
    if type(override) == "function" then
      override(lint)
    else
      local spec = vim.deepcopy(override)
      conditions[name] = spec.condition
      spec.condition = nil
      if next(spec) then
        local base = lint.linters[name]
        if type(base) == "function" then
          base = base()
        end
        lint.linters[name] = vim.tbl_deep_extend("force", base or {}, spec)
      end
    end
  end
end

---@param name string
---@param buf integer
---@return boolean
local function runnable(name, buf)
  local ok, linter = pcall(function()
    return require("lint").linters[name]
  end)
  if not ok or not linter then
    return false
  end
  if type(linter) == "function" then
    linter = linter()
  end
  local cmd = type(linter.cmd) == "function" and linter.cmd() or linter.cmd
  if type(cmd) ~= "string" or vim.fn.executable(cmd) == 0 then
    return false
  end
  local condition = conditions[name]
  if condition then
    local filename = vim.api.nvim_buf_get_name(buf)
    return condition { buf = buf, filename = filename, dirname = vim.fs.dirname(filename) } == true
  end
  return true
end

---Lint the current buffer with the linters that are installed and whose
---condition holds (e.g. luacheck only with a .luacheckrc).
function M.try()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" or not require("core.settings").get "lint.enabled" or vim.b[buf].lint == false then
    return
  end
  local lint = require "lint"
  local names = {}
  -- Compound filetypes ("yaml.docker-compose") use the linters of each part.
  for _, ft in ipairs(vim.split(vim.bo[buf].filetype, ".", { plain = true })) do
    for _, name in ipairs(lint.linters_by_ft[ft] or {}) do
      if runnable(name, buf) and not vim.tbl_contains(names, name) then
        names[#names + 1] = name
      end
    end
  end
  if #names > 0 then
    lint.try_lint(names)
  end
end

return M
