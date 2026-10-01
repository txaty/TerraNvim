-- Offer Neovim 0.12's :restart after a change that only applies on startup
-- (plugin `cond` flags such as the AI toggle or language packs).
--
-- :restart saves the session, quits, starts a new server with the same argv
-- and re-attaches the UI, so the user keeps their buffers.
local M = {}

---@param what string subject for the prompt, e.g. "AI features"
function M.offer(what)
  -- Headless (tests, scripts) has no UI to re-attach.
  if #vim.api.nvim_list_uis() == 0 then
    return
  end
  vim.schedule(function()
    vim.ui.select({ "Restart now", "Later" }, { prompt = what .. " apply after a restart" }, function(choice)
      if choice == "Restart now" then
        vim.cmd.restart()
      end
    end)
  end)
end

return M
