return {
  {
    "mfussenegger/nvim-dap",
    lazy = true, -- Loaded on-demand via keymaps
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
    },
    keys = {
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle breakpoint",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
        end,
        desc = "Conditional breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Continue / run",
      },
      {
        "<leader>dl",
        function()
          require("dap").run_last()
        end,
        desc = "Run last",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "Step over",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_out()
        end,
        desc = "Step out",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "Toggle UI",
      },
      {
        "<leader>dx",
        function()
          require("dap").terminate()
          require("dapui").close()
        end,
        desc = "Terminate",
      },
    },
    config = function()
      local dap = require "dap"
      local dapui = require "dapui"

      -- Signs
      local signs = {
        DapBreakpoint = { text = "B", texthl = "DiagnosticError", linehl = "", numhl = "" },
        DapStopped = { text = ">", texthl = "DiagnosticWarn", linehl = "DiffChange", numhl = "" },
        DapBreakpointRejected = { text = "x", texthl = "DiagnosticInfo", linehl = "", numhl = "" },
      }

      for name, sign in pairs(signs) do
        vim.fn.sign_define(name, sign)
      end

      -- DAP UI Setup
      dapui.setup {
        floating = { border = "rounded" },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.60 },
              { id = "stacks", size = 0.20 },
              { id = "watches", size = 0.20 },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            position = "bottom",
            size = 12,
          },
        },
      }

      -- Listeners
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      -- Defer language-specific DAP configs loading (only load when needed)
      -- Respects lang_toggle: disabled languages skip their DAP config
      --
      -- Modules live in lua/dap_configs/, not lua/dap/. The latter shares a
      -- require namespace with nvim-dap's own lua/dap/ tree, so both
      -- directories fed the same `dap.*` module path and resolution depended on
      -- runtimepath order — fine only for as long as no filename collided.
      --
      -- NOTE: This FileType autocmd fires once=true. For buffers opened before this
      -- plugin loads (e.g., session-restored buffers), lifecycle/init.lua's
      -- retrigger_buffer_events() emits synthetic FileType events to ensure DAP
      -- configs are loaded. Without that retrigger, DAP configs would never load
      -- for pre-existing buffers.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("DapLangConfigs", { clear = true }),
        pattern = { "c", "cpp", "go", "javascript", "typescript" },
        once = true,
        callback = function()
          vim.schedule(function()
            local function load_dap_config(name, lang)
              if lang then
                local lt_ok, lt = pcall(require, "core.lang_toggle")
                if lt_ok and not lt.is_enabled(lang) then
                  return
                end
              end
              local ok, err = pcall(require, "dap_configs." .. name)
              if not ok and (type(err) ~= "string" or not err:match "module .* not found") then
                vim.notify("DAP config error (" .. name .. "): " .. tostring(err), vim.log.levels.WARN)
              end
            end
            load_dap_config("cpp", "cpp")
            load_dap_config("go", "go")
            load_dap_config("web", "web")
          end)
        end,
      })
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    lazy = true, -- Loaded as dependency of nvim-dap
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    lazy = true, -- Loaded as dependency of nvim-dap
    dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
    opts = { commented = true },
  },
  -- JavaScript/TypeScript debug adapter
  {
    "mxsdev/nvim-dap-vscode-js",
    ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    opts = {
      adapters = { "node", "chrome", "pwa-node" },
    },
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    cmd = { "DapInstall", "DapUninstall" },
    dependencies = {
      "mason-org/mason.nvim",
      "mfussenegger/nvim-dap",
    },
    opts = {
      ensure_installed = { "codelldb", "python", "js-debug-adapter", "delve" },
      automatic_installation = false,
    },
  },
}
