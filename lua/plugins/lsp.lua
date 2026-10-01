return {
  -- Incremental LSP rename: see changes live as you type
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    keys = {
      {
        "<leader>lr",
        function()
          return ":IncRename " .. vim.fn.expand "<cword>"
        end,
        expr = true,
        desc = "LSP: Incremental Rename",
      },
    },
    opts = {},
  },

  -- Tool installer. Packages of enabled language packs are installed by
  -- core.lang.install (auto on first use, or :LangInstall); Mason's bin dir is
  -- put on PATH at startup by core.lang.setup(), hence PATH = "skip".
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    keys = { { "<leader>lm", "<cmd>Mason<cr>", desc = "LSP: Mason" } },
    opts = { PATH = "skip" },
  },

  -- JSON/YAML schemas for jsonls and yamlls (used by the json and yaml packs).
  { "b0o/SchemaStore.nvim", lazy = true, version = false },

  -- nvim-lspconfig is only a source of lsp/<name>.lua configs for
  -- vim.lsp.config(); which servers run is decided by core.lang.lsp from the
  -- enabled language packs.
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      -- Loads first; its plugin/ file registers completion capabilities for
      -- every server via vim.lsp.config("*").
      { "saghen/blink.cmp", optional = true },
    },
    config = function()
      -- Diagnostic appearance
      -- Respect persisted diagnostic_lines toggle (set by ui_toggle at VimEnter Step 3,
      -- before this config() runs at BufReadPre). If the user had virtual_lines enabled,
      -- restore that mode; otherwise use default virtual_text.
      local use_virtual_lines = vim.g.ui_diagnostic_lines == true
      local diag_opts = {
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
          },
        },
        severity_sort = true,
        float = { border = "rounded" },
      }
      if use_virtual_lines then
        diag_opts.virtual_text = false
        diag_opts.virtual_lines = true
      else
        diag_opts.virtual_text = { prefix = "●", spacing = 4 }
      end
      vim.diagnostic.config(diag_opts)

      local map = vim.keymap.set

      -- LspAttach Autocmd for Keymaps
      -- Use a unique augroup name to avoid conflicts with other plugins
      -- The augroup is created once with clear=true to ensure a clean slate
      --
      -- Extensibility: These keymaps apply to all LSP clients. Language modules
      -- that need different bindings should use their own LspAttach handler with
      -- a client name check (e.g., rustaceanvim uses <leader>R* prefix). If a
      -- per-buffer override mechanism is needed in the future, check for
      -- vim.b.lsp_keymaps_override before setting each keymap.
      -- Buffer-local LSP keymaps. Neovim 0.11/0.12 already map, globally:
      --   K hover, grn rename, gra code action, grr references, gri implementation,
      --   grt type definition, grx run codelens, gO document symbols,
      --   [d ]d diagnostics, <C-s> (insert) signature help, an/in selection range.
      -- Those are deliberately NOT remapped (a buffer-local `gr` would make every
      -- gr* default wait for 'timeoutlen'); only additions live here.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("NvimConfig_LspKeymaps", { clear = true }),
        callback = function(ev)
          local function bmap(lhs, rhs, desc, mode)
            map(mode or "n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          bmap("gd", vim.lsp.buf.definition, "LSP: Go to definition")
          bmap("gD", vim.lsp.buf.declaration, "LSP: Go to declaration")
          bmap("<leader>la", vim.lsp.buf.code_action, "LSP: Code action", { "n", "x" })
          bmap("<leader>ls", vim.lsp.buf.signature_help, "LSP: Signature help")
          bmap("<leader>ld", vim.diagnostic.open_float, "LSP: Line diagnostics")
          bmap("<leader>D", vim.lsp.buf.type_definition, "LSP: Type definition")
          -- <leader>lr is inc-rename (above); <leader>lf is conform (tools.lua).
          -- Workspace folders live under <leader>lw*, not the <leader>w windows group.
          bmap("<leader>lwa", vim.lsp.buf.add_workspace_folder, "LSP: Add workspace folder")
          bmap("<leader>lwr", vim.lsp.buf.remove_workspace_folder, "LSP: Remove workspace folder")
          bmap("<leader>lwl", function()
            vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()), vim.log.levels.INFO)
          end, "LSP: List workspace folders")
        end,
      })

      require("core.lang.lsp").setup()
    end,
  },

  -- Glance: Peek definition/references in floating window (VS Code-style)
  {
    "DNLHC/glance.nvim",
    cmd = "Glance",
    keys = {
      -- Under <leader>lp ("Peek") so native gp/gP/gI keep working.
      { "<leader>lpd", "<cmd>Glance definitions<cr>", desc = "LSP: Peek definitions" },
      { "<leader>lpr", "<cmd>Glance references<cr>", desc = "LSP: Peek references" },
      { "<leader>lpi", "<cmd>Glance implementations<cr>", desc = "LSP: Peek implementations" },
      { "<leader>lpt", "<cmd>Glance type_definitions<cr>", desc = "LSP: Peek type definitions" },
    },
    opts = {
      border = { enable = true },
      height = 20,
    },
  },
}
