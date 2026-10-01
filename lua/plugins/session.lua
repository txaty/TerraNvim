return {
  {
    "folke/persistence.nvim",
    lazy = true, -- Loaded on demand by lifecycle (session.restore() at VimEnter)
    -- scope.nvim must be loaded BEFORE persistence.load() fires PersistenceLoadPost,
    -- otherwise scope's handler (ScopeLoadState) is never registered at session restore.
    -- Declaring it as a dependency guarantees scope loads first regardless of its own
    -- VeryLazy trigger in ui.lua.
    dependencies = { "tiagovla/scope.nvim" },
    opts = {
      -- Session options: UI state is persisted via ui_config.json (source of truth)
      -- Theme persistence is handled separately by theme.lua
      -- NOTE: "globals" intentionally excluded to avoid conflicts with JSON configs
      -- (vim.g.ui_* from session would override ui_config.json, causing inconsistencies)
      options = { "buffers", "curdir", "tabpages", "winsize", "help", "skiprtp" },
    },
    config = function(_, opts)
      require("persistence").setup(opts)
      -- The explorer sidebar is a picker; :mksession would save its windows as
      -- empty splits. Close it before the session is written.
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceSavePre",
        group = vim.api.nvim_create_augroup("persistence_explorer", { clear = true }),
        callback = function()
          if package.loaded.snacks then
            for _, picker in ipairs(Snacks.picker.get { source = "explorer" }) do
              picker:close()
            end
          end
        end,
      })
    end,
    -- Note: Session auto-save and auto-restore are handled in core/autocmds.lua
    -- This ensures autocmds are registered before VimEnter fires
    keys = {
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "Restore Session",
      },
      {
        "<leader>qS",
        function()
          require("persistence").select()
        end,
        desc = "Select Session",
      },
      {
        "<leader>ql",
        function()
          require("persistence").load { last = true }
        end,
        desc = "Restore Last Session",
      },
      {
        "<leader>qd",
        function()
          require("persistence").stop()
        end,
        desc = "Don't Save Current Session",
      },
    },
  },
}
