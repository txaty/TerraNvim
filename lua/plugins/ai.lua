-- AI integrations, off by default and gated by :AIToggle / <leader>ai
-- (core.ai_toggle; `cond` is evaluated at startup, so toggling offers :restart).
--
-- claudecode.nvim: Claude Code's IDE protocol (the one the VS Code/JetBrains
--   extensions use). Claude sees the current selection and open files, and its
--   edits open as native diffs to accept (<leader>aa) or deny (<leader>ad).
-- sidekick.nvim: a persistent terminal for any AI CLI (claude, codex, gemini,
--   copilot, opencode, ...) with send-context helpers. Its Copilot next-edit
--   suggestions are disabled: they need copilot-language-server running in every
--   buffer. Enable with nes = { enabled = true } and vim.lsp.enable("copilot").
local function ai_enabled()
  return require("core.ai_toggle").is_enabled()
end

local function cli(fn, args)
  return function()
    require("sidekick.cli")[fn](args)
  end
end

return {
  {
    "coder/claudecode.nvim",
    cond = ai_enabled,
    -- Track main: the last tag (v0.3.0, 2025-09) predates options and fixes
    -- the README documents. lazy-lock.json pins the commit.
    version = false,
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSelectModel",
      "ClaudeCodeAdd",
      "ClaudeCodeSend",
      "ClaudeCodeSendText",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeStatus",
      "ClaudeCodeStart",
      "ClaudeCodeStop",
      "ClaudeCodeOpen",
      "ClaudeCodeClose",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeCloseAllDiffs",
    },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Claude: Toggle" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude: Focus" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Claude: Resume session" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Claude: Continue last session" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Claude: Select model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: Add buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "x", desc = "Claude: Send selection" },
      { "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", ft = "snacks_picker_list", desc = "Claude: Add file" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: Deny diff" },
    },
    opts = {
      terminal = { provider = "snacks", split_side = "right", split_width_percentage = 0.35 },
    },
  },

  {
    "folke/sidekick.nvim",
    cond = ai_enabled,
    version = "*",
    cmd = "Sidekick",
    keys = {
      { "<c-.>", cli "focus", mode = { "n", "t", "i", "x" }, desc = "Sidekick: Focus CLI" },
      { "<leader>ak", cli "toggle", desc = "Sidekick: Toggle CLI" },
      { "<leader>aK", cli("select", { filter = { installed = true } }), desc = "Sidekick: Select CLI" },
      { "<leader>ap", cli "prompt", mode = { "n", "x" }, desc = "Sidekick: Prompt" },
      { "<leader>at", cli("send", { msg = "{this}" }), mode = { "n", "x" }, desc = "Sidekick: Send this" },
      { "<leader>aF", cli("send", { msg = "{file}" }), desc = "Sidekick: Send file" },
      { "<leader>av", cli("send", { msg = "{selection}" }), mode = "x", desc = "Sidekick: Send selection" },
    },
    opts = {
      nes = { enabled = false },
      copilot = { status = { enabled = false } },
      cli = { picker = "snacks", win = { layout = "right" } },
    },
  },
}
