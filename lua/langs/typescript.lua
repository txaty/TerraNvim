-- TypeScript / JavaScript (incl. React). vtsls by default; TypeScript 7's native
-- `tsc --lsp` is one :LangOption away (faster, but Vue/Svelte/Astro/MDX still
-- need tsserver plugins and therefore vtsls). Formatting follows the project:
-- Biome when biome.json exists, otherwise prettier.
local inlay_hints = {
  enumMemberValues = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  parameterNames = { enabled = "literals" },
  parameterTypes = { enabled = true },
  propertyDeclarationTypes = { enabled = true },
  variableTypes = { enabled = false },
}

local FILETYPES = { "javascript", "javascriptreact", "typescript", "typescriptreact" }

return {
  title = "TypeScript",
  description = "vtsls|tsc (TS 7), eslint, biome|prettier, js-debug-adapter, vitest/jest",
  filetypes = FILETYPES,
  grep_type = "ts",
  options = {
    server = { default = "vtsls", choices = { "vtsls", "tsc" }, desc = "Language server (tsc = TypeScript 7 native)" },
    formatter = {
      default = "auto",
      choices = { "auto", "biome", "prettier" },
      desc = "auto = biome with biome.json, else prettier",
    },
  },
  parsers = { "javascript", "typescript", "tsx", "jsdoc" },
  servers = function(o)
    return {
      vtsls = {
        mason = "vtsls",
        enabled = o.server == "vtsls",
        settings = {
          complete_function_calls = true,
          vtsls = {
            enableMoveToFileCodeAction = true,
            autoUseWorkspaceTsdk = true,
            experimental = { completion = { enableServerSideFuzzyMatch = true } },
          },
          typescript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = { completeFunctionCalls = true },
            inlayHints = inlay_hints,
          },
          javascript = { inlayHints = inlay_hints },
        },
      },
      tsc = { mason = "tsc", enabled = o.server == "tsc" },
      -- Both only attach inside projects that configure them (eslint config /
      -- biome.json), so they are safe to keep on.
      eslint = { mason = "eslint-lsp", settings = { workingDirectories = { mode = "auto" } } },
      biome = { mason = "biome" },
    }
  end,
  tools = { "prettierd", "js-debug-adapter" },
  formatters_by_ft = function(o)
    local function pick(buf)
      if o.formatter == "biome" or (o.formatter == "auto" and vim.fs.root(buf, { "biome.json", "biome.jsonc" })) then
        return { "biome-check" }
      end
      return { "prettierd", "prettier", stop_after_first = true }
    end
    local map = {}
    for _, ft in ipairs(FILETYPES) do
      map[ft] = pick
    end
    return map
  end,
  dap = function(dap)
    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = { command = "js-debug-adapter", args = { "${port}" } },
    }
    for _, ft in ipairs(FILETYPES) do
      dap.configurations[ft] = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch file (node)",
          program = "${file}",
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach to process (node --inspect)",
          processId = function()
            return require("dap.utils").pick_process()
          end,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
      }
    end
  end,
  test = {
    -- Both adapters detect their own projects (vitest/jest in package.json).
    adapter = function()
      return { require "neotest-vitest", require "neotest-jest" {} }
    end,
  },
  plugins = {
    { "marilari88/neotest-vitest", lazy = true },
    { "nvim-neotest/neotest-jest", lazy = true },
  },
}
