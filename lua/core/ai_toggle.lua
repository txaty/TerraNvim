-- AI feature toggle.
--
-- Gates copilot.lua, CopilotChat.nvim and avante.nvim through their `cond` in
-- lua/plugins/copilot.lua. `cond` is evaluated when lazy.nvim builds the plugin
-- list, so flipping this only takes effect on the next start — hence the
-- "Restart Neovim" wording. Similar in spirit to Zed's "Disable AI".
--
-- Defaults to OFF (core.settings `ai.enabled`): nothing reaches the network on
-- startup unless asked.
return require("core.persist_flag").new {
  filename = "ai_config.json",
  default = require("core.settings").get "ai.enabled",
  label = "AI features",
  hint = "Restart Neovim to apply changes.",
  restart = true,
}
