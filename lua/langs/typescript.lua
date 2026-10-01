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
            -- The workspace TypeScript (node_modules/typescript) is project
            -- code; before_init turns this on in trusted projects only.
            autoUseWorkspaceTsdk = false,
            experimental = { completion = { enableServerSideFuzzyMatch = true } },
          },
          typescript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = { completeFunctionCalls = true },
            inlayHints = inlay_hints,
          },
          javascript = { inlayHints = inlay_hints },
        },
        before_init = function(_, config)
          if config.root_dir and require("core.trust").is_trusted(config.root_dir) then
            config.settings.vtsls.autoUseWorkspaceTsdk = true
          end
        end,
      },
      tsc = {
        mason = "tsc",
        enabled = o.server == "tsc",
        -- nvim-lspconfig's tsc probes <root>/node_modules/.bin/tsc --version
        -- while resolving the root, i.e. runs a project binary: use Mason's
        -- tsc and plain root markers instead.
        cmd = { "tsc", "--lsp", "--stdio" },
        root_dir = function(bufnr, on_dir)
          if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
            return -- Deno project
          end
          local markers = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
          on_dir(vim.fs.root(bufnr, { markers, { ".git" } }) or vim.fn.getcwd())
        end,
      },
      -- eslint runs the project's eslint and its JS config: trusted projects
      -- only. Both attach only where the project configures them.
      eslint = {
        mason = "eslint-lsp",
        cmd = { "vscode-eslint-language-server", "--stdio" },
        trust = true,
        settings = { workingDirectories = { mode = "auto" } },
      },
      biome = { mason = "biome", cmd = { "biome", "lsp-proxy" } },
    }
  end,
  tools = { "prettierd", "js-debug-adapter" },
  formatters = function()
    -- prettier loads JS configs/plugins from the project: trusted projects only
    -- (elsewhere vtsls formats). Biome's config is data, but conform would run
    -- the project's node_modules biome: only when trusted.
    local trust = require "core.trust"
    return {
      prettier = { command = trust.node_bin "prettier", condition = trust.formatter_condition "prettier" },
      prettierd = { condition = trust.formatter_condition "prettier" },
      ["biome-check"] = { command = trust.node_bin "biome" },
    }
  end,
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
