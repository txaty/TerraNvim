-- Session management lifecycle module
-- Handles session save/restore with persistence.nvim
local M = {}

local directory_argument = false

---`nvim <dir>`: make <dir> the working directory. Pickers, grep, lazygit and
---the per-directory session are all keyed on the cwd.
function M.enter_directory_argument()
  local arg = vim.fn.argc() == 1 and vim.fn.argv(0) or nil
  if arg and vim.fn.isdirectory(arg) == 1 then
    directory_argument = true
    vim.cmd.cd { args = { vim.fn.fnameescape(arg) } }
  end
end

--- Determine if session should be restored based on startup arguments
--- @return boolean
function M.should_restore()
  local argc = vim.fn.argc()

  -- No arguments: restore session
  if argc == 0 then
    return true
  end

  -- Single argument: check if it's empty, ".", or a directory (already
  -- entered by enter_directory_argument(), so a relative path no longer resolves)
  if argc == 1 and directory_argument then
    return true
  end
  if argc == 1 then
    local arg = vim.fn.argv(0)
    if arg == "" or arg == "." or vim.fn.isdirectory(arg) == 1 then
      return true
    end
  end

  -- Multiple arguments or specific file: don't restore
  return false
end

--- Check if a session file exists for current directory
--- @return boolean
function M.has_session()
  local ok, persistence = pcall(require, "persistence")
  if not ok then
    return false
  end

  local session_file = persistence.current()
  return vim.fn.filereadable(session_file) == 1
end

---Close snacks explorer pickers now. picker:close() closes its windows on the
---next tick, which is too late when a session is about to be sourced.
---@return boolean was_open
local function close_explorer()
  if not package.loaded.snacks then
    return false
  end
  local pickers = Snacks.picker.get { source = "explorer" }
  for _, picker in ipairs(pickers) do
    picker:close()
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if ft == "snacks_layout_box" or ft:match "^snacks_picker" then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  return #pickers > 0
end

--- Restore session if conditions are met
--- @return boolean True if session was restored
function M.restore()
  if not M.should_restore() then
    return false
  end

  local ok, persistence = pcall(require, "persistence")
  if not ok then
    return false
  end

  local session_file = persistence.current()
  if vim.fn.filereadable(session_file) ~= 1 then
    return false
  end

  -- `nvim <dir>`: snacks.explorer (replace_netrw) is already open. Sourcing
  -- the session over its windows loses the first session window and leaves a
  -- zero-width split, so close it first and reopen it afterwards.
  local reopen_explorer = close_explorer()
  local success = pcall(persistence.load)
  if reopen_explorer then
    vim.schedule(function()
      local win = vim.api.nvim_get_current_win()
      Snacks.explorer()
      -- Keep the cursor in the restored file, not the sidebar.
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_set_current_win(win)
        end
      end)
    end)
  end
  return success
end

return M
