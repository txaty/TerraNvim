-- Rust via rustaceanvim, which owns rust-analyzer (never configure it through
-- vim.lsp/lspconfig as well, or two clients attach).
---@param cmd string|table argument for vim.cmd.RustLsp
local function rust_lsp(cmd)
  return function()
    vim.cmd.RustLsp(cmd)
  end
end

local function is_cargo_toml(buf)
  return vim.fs.basename(vim.api.nvim_buf_get_name(buf)) == "Cargo.toml"
end

local function crates(fn)
  return function()
    require("crates")[fn]()
  end
end

return {
  title = "Rust",
  description = "rustaceanvim (rust-analyzer, clippy), crates.nvim, codelldb, neotest",
  filetypes = { "rust" },
  grep_type = "rust",
  parsers = { "rust" },
  servers = {
    rust_analyzer = { mason = "rust-analyzer", managed_by = "rustaceanvim" },
  },
  tools = { "codelldb" },
  formatters_by_ft = { rust = { "rustfmt" } },
  test = {
    adapter = function()
      return require "rustaceanvim.neotest"
    end,
  },
  plugins = {
    {
      "mrcjkb/rustaceanvim",
      version = "^9",
      -- rustaceanvim lazy-loads itself through its ftplugin; its README asks not
      -- to lazy-load the plugin.
      lazy = false,
      init = function()
        -- Configure rustaceanvim before plugin loads.
        --
        -- Setting names below are validated against `rust-analyzer
        -- --print-config-schema`. rust-analyzer silently ignores unknown keys, so
        -- a stale name is invisible at runtime — the feature just never turns on.
        -- Several keys here were renamed upstream and have been migrated:
        --   cargo.allFeatures      -> cargo.features = "all"
        --   cargo.runBuildScripts  -> cargo.buildScripts.enable
        --   cargo.loadOutDirMacros -> (removed; covered by buildScripts.enable)
        --   checkOnSave = {table}  -> checkOnSave = <boolean> + check.*
        --   hover.documentation    -> hover.documentation.enable
        --   hover.actions.enabled  -> hover.actions.enable
        --   inlayHints.showParameterNames -> inlayHints.parameterHints.enable
        -- Inlay-hint prefixes/alignment are no longer server settings at all;
        -- rendering is the client's job (`vim.lsp.inlay_hint`).
        -- `server.default_settings` is rustaceanvim's documented key for the
        -- rust-analyzer settings table.
        vim.g.rustaceanvim = {
          -- LSP configuration
          server = {
            default_settings = {
              ["rust-analyzer"] = {
                -- Workspace and discovery
                workspace = {
                  symbol = {
                    search = {
                      kind = "all_symbols",
                    },
                  },
                },

                -- Cargo configuration
                cargo = {
                  features = "all", -- Analyze all feature combinations
                  buildScripts = {
                    enable = true, -- Run build scripts (build.rs) for accurate analysis
                  },
                },

                -- Proc macro support
                procMacro = {
                  enable = true, -- Enable procedural macro expansion
                  server = "prefer", -- Prefer server-side macro expansion
                },

                -- Diagnostics
                diagnostics = {
                  enable = true,
                  disabled = {},
                  warningsAsHint = {},
                  warningsAsInfo = {},
                },

                -- Check on save: the flag is a boolean; the command it runs lives
                -- under `check.*`. Passing a table to checkOnSave makes
                -- rust-analyzer reject the whole block, so clippy never ran.
                checkOnSave = true,
                check = {
                  command = "clippy",
                  extraArgs = { "--all-targets", "--all-features" },
                },

                -- Hover actions
                hover = {
                  documentation = { enable = true },
                  actions = { enable = true },
                },

                -- Inlay hints
                inlayHints = {
                  parameterHints = { enable = true },
                  chainingHints = { enable = true },
                },

                -- Completion
                completion = {
                  privateEditable = {
                    enable = false,
                  },
                },

                -- Imports
                imports = {
                  granularity = {
                    group = "module",
                  },
                  prefix = "self",
                },

                -- Assist
                assist = {
                  emitMustUse = true,
                },
              },
            },
          },

          -- rustaceanvim finds codelldb (Mason, installed by this pack) or lldb-dap.
          dap = {},

          -- rustaceanvim's own `tools` table. Keys here are rustaceanvim options,
          -- NOT rust-tools.nvim ones — the old `enable_all_diagnostics` and the
          -- `tools.inlay_hints` block were rust-tools leftovers that rustaceanvim
          -- ignores (inlay hints are server settings + vim.lsp.inlay_hint now).
          tools = {
            float_win_config = {
              -- Configuration for floating windows (e.g., hover, method signature)
              border = "rounded",
            },
            enable_clippy = true,
            reload_workspace_from_cargo_toml = true,
          },
        }
      end,
    },
    {
      "saecki/crates.nvim",
      event = { "BufRead Cargo.toml" },
      opts = { lsp = { enabled = true, actions = true, completion = true, hover = true } },
    },
  },
  keys = {
    { "<leader>R", group = "Rust", icon = "󱘗" },
    { "<leader>Rr", rust_lsp "runnables", desc = "Rust: Runnables" },
    { "<leader>RR", rust_lsp { "runnables", bang = true }, desc = "Rust: Rerun last" },
    { "<leader>Rt", rust_lsp "testables", desc = "Rust: Testables" },
    { "<leader>Ra", rust_lsp "expandMacro", desc = "Rust: Expand macro" },
    { "<leader>Rx", rust_lsp "explainError", desc = "Rust: Explain error" },
    { "<leader>Rd", rust_lsp "debuggables", desc = "Rust: Debuggables" },
    { "<leader>RH", rust_lsp { "hover", "actions" }, desc = "Rust: Hover actions" },
    { "<leader>Rc", rust_lsp "openCargo", desc = "Rust: Open Cargo.toml" },
    { "<leader>Rp", rust_lsp "parentModule", desc = "Rust: Parent module" },
    { "<leader>Rj", rust_lsp "joinLines", desc = "Rust: Join lines" },
    { "<leader>RS", rust_lsp "ssr", desc = "Rust: Structural search/replace" },
    -- crates.nvim, only in Cargo.toml
    { "<leader>C", group = "Crates", icon = "󰏗", ft = "toml", cond = is_cargo_toml },
    { "<leader>Cv", crates "show_versions_popup", desc = "Crates: Versions", ft = "toml", cond = is_cargo_toml },
    { "<leader>Cf", crates "show_features_popup", desc = "Crates: Features", ft = "toml", cond = is_cargo_toml },
    {
      "<leader>Cd",
      crates "show_dependencies_popup",
      desc = "Crates: Dependencies",
      ft = "toml",
      cond = is_cargo_toml,
    },
    { "<leader>Cu", crates "upgrade_crate", desc = "Crates: Upgrade crate", ft = "toml", cond = is_cargo_toml },
    {
      "<leader>CA",
      crates "upgrade_all_crates",
      desc = "Crates: Upgrade all crates",
      ft = "toml",
      cond = is_cargo_toml,
    },
  },
}
