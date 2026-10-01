-- AI feature toggle commands: :AIToggle / :AIEnable / :AIDisable / :AIStatus
local M = {}

function M.register()
  require("core.commands.flag_commands").register {
    prefix = "AI",
    module = "core.ai_toggle",
    label = "AI features",
    toggle_desc = "Toggle AI features (Claude Code, Sidekick)",
  }
end

return M
