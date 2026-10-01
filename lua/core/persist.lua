-- Unified JSON config persistence with caching
-- Consolidates duplicate load/save patterns from ai_toggle, lang_toggle, ui_toggle, theme
local M = {}
local cache = {} -- Keyed by filepath

local function allowed_roots()
  return {
    vim.fn.stdpath "data",
    vim.fn.stdpath "state",
    vim.fn.stdpath "cache",
  }
end

local function is_within_allowed_roots(path)
  local abs_path = vim.fn.fnamemodify(path, ":p")
  local real_path = vim.uv.fs_realpath(abs_path)
  if not real_path then
    return false
  end

  for _, root in ipairs(allowed_roots()) do
    local real_root = vim.uv.fs_realpath(root)
    if real_root then
      local prefix = real_root:sub(-1) == "/" and real_root or (real_root .. "/")
      if real_path == real_root or real_path:find("^" .. vim.pesc(prefix)) then
        return true
      end
    end
  end

  return false
end

local function validate_write_path(filepath)
  local abs_path = vim.fn.fnamemodify(filepath, ":p")
  local parent = vim.fn.fnamemodify(abs_path, ":h")
  local existing = vim.uv.fs_lstat(abs_path)

  if existing and existing.type == "link" then
    return false, "Refusing to write through symlink"
  end

  if vim.fn.isdirectory(parent) ~= 1 then
    vim.fn.mkdir(parent, "p", "0700")
  end

  if not is_within_allowed_roots(parent) then
    return false, "Write path outside Neovim-controlled directories"
  end

  if existing and not is_within_allowed_roots(abs_path) then
    return false, "Write target outside Neovim-controlled directories"
  end

  return true
end

--- Load JSON config with caching
---@param filepath string Full path to JSON file
---@param default table Default value if file doesn't exist
---@return table config
function M.load_json(filepath, default)
  if cache[filepath] ~= nil then
    return cache[filepath]
  end

  local stat = vim.uv.fs_stat(filepath)
  if not stat then
    cache[filepath] = default or {}
    return cache[filepath]
  end

  local fd = vim.uv.fs_open(filepath, "r", 438)
  if not fd then
    cache[filepath] = default or {}
    return cache[filepath]
  end

  local content = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)

  if not content or content == "" then
    cache[filepath] = default or {}
    return cache[filepath]
  end

  local ok, result = pcall(vim.json.decode, content)
  if not ok then
    vim.notify("persist: failed to decode " .. filepath .. " — " .. tostring(result), vim.log.levels.WARN)
  end
  cache[filepath] = (ok and type(result) == "table") and result or (default or {})
  return cache[filepath]
end

--- Save table to JSON config
---@param filepath string Full path to JSON file
---@param config table Config to save
function M.save_json(filepath, config)
  if vim.g.nvim_smoke then
    return true -- smoke tests must not touch persisted state (scripts/smoke.lua)
  end
  local ok, err = validate_write_path(filepath)
  if not ok then
    vim.notify("Blocked JSON write: " .. err, vim.log.levels.ERROR)
    return false
  end

  local json_str = vim.json.encode(config)
  local fd = vim.uv.fs_open(filepath, "w", 438)
  if fd then
    vim.uv.fs_write(fd, json_str, 0)
    vim.uv.fs_close(fd)
  end
  cache[filepath] = nil -- Invalidate cache
  return fd ~= nil
end

---@param filepath string
---@param lines string[]
---@return boolean
function M.save_lines(filepath, lines)
  if vim.g.nvim_smoke then
    return true
  end
  local ok, err = validate_write_path(filepath)
  if not ok then
    vim.notify("Blocked file write: " .. err, vim.log.levels.ERROR)
    return false
  end

  local fd = vim.uv.fs_open(filepath, "w", 438)
  if not fd then
    return false
  end

  local content = table.concat(lines, "\n")
  if #lines > 0 then
    content = content .. "\n"
  end
  vim.uv.fs_write(fd, content, 0)
  vim.uv.fs_close(fd)
  return true
end

--- Invalidate cache for filepath
---@param filepath string Full path to JSON file
function M.invalidate(filepath)
  cache[filepath] = nil
end

return M
