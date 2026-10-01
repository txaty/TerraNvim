local security = require "core.security"

local function invalid_remote_input(input)
  return input:find "[|\n\r;`&$!#]"
end

local function prompt_remote_input(prompt, error_message, title, command)
  return function()
    vim.ui.input({ prompt = prompt }, function(input)
      if not input or input == "" then
        return
      end
      if invalid_remote_input(input) then
        vim.notify(error_message, vim.log.levels.ERROR)
        return
      end
      if security.confirm_external(title, input) then
        vim.cmd { cmd = command, args = { input } }
      end
    end)
  end
end

---Run `callback` only when a distant client is actually connected.
---
---The previous check was `pcall(require, "distant")`, which tested whether the
---*module* loads — it always does, and under lazy.nvim requiring it even loads
---the plugin. So the guard never fired and <leader>rf/<leader>rg silently ran a
---local search while pretending to be remote. distant:active_client_id() is the
---connection state.
---@param callback fun()
---@return fun()
local function with_remote_connection(callback)
  return function()
    local ok, distant = pcall(require, "distant")
    if not ok or not distant:is_initialized() or not distant:active_client_id() then
      vim.notify("Not connected to a remote server. Use <leader>rc to connect.", vim.log.levels.WARN)
      return
    end
    callback()
  end
end

return {
  -- Distant.nvim - Remote development like VS Code Remote
  {
    "chipsenkbeil/distant.nvim",
    branch = "v0.3",
    cmd = {
      "Distant",
      "DistantInstall",
      "DistantLaunch",
      "DistantConnect",
      "DistantOpen",
      "DistantShell",
      "DistantSystemInfo",
      "DistantClientVersion",
    },
    keys = {
      {
        "<leader>rc",
        prompt_remote_input(
          "Remote connection (e.g., ssh://user@host): ",
          "Invalid characters in connection string",
          "Connect to remote host?",
          "DistantLaunch"
        ),
        desc = "Remote: connect to server",
      },
      {
        "<leader>rd",
        function()
          local ok, distant = pcall(require, "distant")
          if ok then
            distant.close()
          else
            vim.notify("Not connected to any remote server", vim.log.levels.WARN)
          end
        end,
        desc = "Remote: disconnect",
      },
      {
        "<leader>ro",
        prompt_remote_input("Remote path to open: ", "Invalid characters in path", "Open remote path?", "DistantOpen"),
        desc = "Remote: open directory/file",
      },
      { "<leader>rs", "<cmd>DistantSystemInfo<cr>", desc = "Remote: system info" },
      {
        "<leader>rS",
        function()
          if security.confirm_external "Open interactive remote shell?" then
            vim.cmd "DistantShell"
          end
        end,
        desc = "Remote: open shell",
      },
      {
        "<leader>rf",
        with_remote_connection(function()
          require("telescope.builtin").find_files()
        end),
        desc = "Remote: find files",
      },
      {
        "<leader>rg",
        with_remote_connection(function()
          require("telescope.builtin").live_grep()
        end),
        desc = "Remote: live grep",
      },
    },
    config = function()
      -- Basic setup for distant.nvim v0.3
      require("distant"):setup()

      -- Auto-attach LSP when opening remote files
      -- NOTE: LspStart uses servers pre-configured by lsp.lua with capabilities
      -- from core/lsp_capabilities.lua. This ensures remote buffers get the same
      -- completion enhancements as local buffers. The generic LspStart command
      -- will pick up the correct server config based on filetype.
      vim.api.nvim_create_autocmd("BufReadPost", {
        group = vim.api.nvim_create_augroup("DistantLspAttach", { clear = true }),
        pattern = "distant://*",
        callback = function()
          if not require("core.settings").get "lsp.auto_start" then
            return
          end
          -- LSP should attach automatically to remote buffers
          -- distant.nvim handles the file system operations transparently
          vim.schedule(function()
            vim.cmd "LspStart"
          end)
        end,
      })

      -- Show notification when connected/disconnected
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("DistantNotifications", { clear = true }),
        pattern = "DistantConnected",
        callback = function()
          vim.notify("Connected to remote server", vim.log.levels.INFO)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("DistantDisconnected", { clear = true }),
        pattern = "DistantDisconnected",
        callback = function()
          vim.notify("Disconnected from remote server", vim.log.levels.INFO)
        end,
      })
    end,
  },

  -- Extend lualine to show remote connection status
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      -- Add remote connection indicator to lualine
      local function distant_status()
        local ok, distant = pcall(require, "distant")
        if not ok then
          return ""
        end

        local client = distant.client()
        if client then
          -- Get connection info if available
          local info = client:system_info()
          if info then
            return " 󰢹 " .. (info.host or "remote")
          end
          return " 󰢹 remote"
        end
        return ""
      end

      -- Ensure sections table exists
      opts.sections = opts.sections or {}
      opts.sections.lualine_c = opts.sections.lualine_c or {}

      -- Insert into lualine_c section (filename area)
      table.insert(opts.sections.lualine_c, { distant_status })

      return opts
    end,
  },
}
