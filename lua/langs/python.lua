-- Python: basedpyright (or pyright) for types, ruff for lint/format/imports.
return {
  title = "Python",
  description = "basedpyright|pyright, ruff, debugpy, neotest-python, venv-selector",
  filetypes = { "python" },
  grep_type = "py",
  options = {
    server = { default = "basedpyright", choices = { "basedpyright", "pyright" }, desc = "Type-checking server" },
    type_checking = {
      default = "standard",
      choices = { "off", "basic", "standard", "strict" },
      desc = "typeCheckingMode",
    },
  },
  parsers = { "python" },
  servers = function(o)
    local analysis = { typeCheckingMode = o.type_checking, autoImportCompletions = true }
    return {
      basedpyright = {
        mason = "basedpyright",
        enabled = o.server == "basedpyright",
        settings = { basedpyright = { analysis = analysis } },
      },
      pyright = {
        mason = "pyright",
        enabled = o.server == "pyright",
        settings = { python = { analysis = analysis } },
      },
      ruff = {
        mason = "ruff",
        -- Hover comes from the type checker; ruff's would duplicate it.
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
      },
    }
  end,
  tools = { "debugpy" },
  formatters_by_ft = { python = { "ruff_organize_imports", "ruff_format" } },
  dap = function()
    -- debugpy from Mason ships its own venv; fall back to the PATH python.
    local mason_python = vim.fn.stdpath "data" .. "/mason/packages/debugpy/venv/bin/python"
    require("dap-python").setup(vim.uv.fs_stat(mason_python) and mason_python or "python3")
  end,
  test = {
    adapter = function()
      return require "neotest-python" { dap = { justMyCode = false } }
    end,
  },
  plugins = {
    { "mfussenegger/nvim-dap-python", lazy = true },
    { "nvim-neotest/neotest-python", lazy = true },
    {
      "linux-cultist/venv-selector.nvim",
      cmd = "VenvSelect",
      opts = { options = { picker = "snacks" } },
    },
  },
  keys = {
    { "<leader>p", group = "Python", icon = "󰌠" },
    { "<leader>pv", "<cmd>VenvSelect<cr>", desc = "Python: Select virtualenv" },
  },
  ft_options = { python = { foldenable = false } },
}
