-- Go: gopls (gofumpt formatting, staticcheck), golangci-lint v2, delve, neotest-golang.
return {
  title = "Go",
  description = "gopls, goimports+gofumpt, golangci-lint, delve, neotest-golang",
  filetypes = { "go", "gomod", "gowork", "gosum", "gotmpl" },
  grep_type = "go",
  parsers = { "go", "gomod", "gowork", "gosum", "gotmpl" },
  servers = {
    gopls = {
      mason = "gopls",
      settings = {
        gopls = {
          gofumpt = true,
          usePlaceholders = true,
          completeUnimported = true,
          staticcheck = true,
          semanticTokens = true,
          analyses = { unusedparams = true, unusedwrite = true, nilness = true },
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
        },
      },
    },
  },
  tools = { "goimports", "gofumpt", "golangci-lint", "delve", "gotestsum", "gomodifytags", "impl" },
  formatters_by_ft = { go = { "goimports", "gofumpt" } },
  linters_by_ft = { go = { "golangcilint" } },
  dap = function(dap)
    dap.adapters.delve = {
      type = "server",
      port = "${port}",
      executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } },
    }
    dap.configurations.go = {
      { type = "delve", name = "Debug file", request = "launch", program = "${file}" },
      { type = "delve", name = "Debug package", request = "launch", program = "${fileDirname}" },
      { type = "delve", name = "Debug test (file)", request = "launch", mode = "test", program = "${file}" },
      {
        type = "delve",
        name = "Debug test (package)",
        request = "launch",
        mode = "test",
        program = "${fileDirname}",
      },
      {
        type = "delve",
        name = "Attach to process",
        request = "attach",
        mode = "local",
        processId = function()
          return require("dap.utils").pick_process()
        end,
      },
    }
  end,
  test = {
    adapter = function()
      local runner = vim.fn.executable "gotestsum" == 1 and "gotestsum" or "go"
      return require "neotest-golang" { runner = runner }
    end,
  },
  plugins = {
    { "fredrikaverpil/neotest-golang", version = "*", lazy = true },
  },
}
