-- Cursor restore and view (fold) save/load
local autocmd = vim.api.nvim_create_autocmd
local augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

local M = {}

function M.setup()
  -- Restore cursor position from shada
  autocmd("BufReadPost", {
    group = augroup "restore_cursor",
    pattern = "*",
    callback = function()
      local line = vim.fn.line "'\""
      if
        line > 1
        and line <= vim.fn.line "$"
        and vim.bo.filetype ~= "commit"
        and vim.fn.index({ "xxd", "gitrebase" }, vim.bo.filetype) == -1
      then
        vim.cmd 'normal! g`"'
      end
    end,
  })

  -- View (fold) save/load.
  --
  -- Only folds are persisted; `viewoptions` is set to "folds" in options.lua and
  -- the cursor is restored from shada by the autocmd above.
  --
  -- These run synchronously. An earlier version debounced :mkview through a
  -- 100ms timer, which was silently wrong: :mkview always acts on the *current*
  -- window and buffer, so by the time the timer fired it saved whichever buffer
  -- happened to be focused then — not the one that triggered BufWinLeave. The
  -- has_folds() guard below is what keeps the disk I/O rare.

  ---Should this buffer participate in view save/load at all?
  ---Special buffers (trees, help, terminals) and unnamed buffers have no
  ---meaningful view to persist.
  ---@return boolean
  local function is_view_candidate()
    local ft = vim.bo.filetype
    return vim.fn.expand "%" ~= "" and vim.bo.buftype == "" and ft ~= "help"
  end

  ---Does the current buffer have any folds worth persisting?
  ---With a computed foldmethod (treesitter sets "expr") assume yes. With manual
  ---folds, scan a bounded prefix rather than the whole buffer.
  ---@return boolean
  local function has_folds()
    if vim.wo.foldmethod ~= "manual" then
      return true
    end
    for i = 1, math.min(vim.fn.line "$", 500) do
      if vim.fn.foldlevel(i) > 0 then
        return true
      end
    end
    return false
  end

  autocmd("BufWinLeave", {
    group = augroup "view_saving",
    pattern = "*",
    callback = function()
      if is_view_candidate() and has_folds() then
        pcall(vim.cmd, "mkview")
      end
    end,
  })

  autocmd("BufWinEnter", {
    group = augroup "view_loading",
    pattern = "*",
    callback = function()
      if not is_view_candidate() then
        return
      end
      vim.cmd "silent! loadview"
    end,
  })
end

return M
