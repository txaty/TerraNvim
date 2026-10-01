return {
  {
    "folke/persistence.nvim",
    -- Loaded at VimEnter by core/lifecycle/init.lua when session persistence
    -- is on (restore + its own VimLeavePre autosave), otherwise by the keys.
    lazy = true,
    -- scope.nvim must be loaded BEFORE persistence.load() fires PersistenceLoadPost,
    -- otherwise scope's handler (ScopeLoadState) is never registered at session restore.
    -- Declaring it as a dependency guarantees scope loads first regardless of its own
    -- VeryLazy trigger in ui.lua.
    dependencies = { "tiagovla/scope.nvim" },
    -- 'sessionoptions' is set in core/options.lua (persistence.nvim has no
    -- option of its own for it).
    opts = {},
    config = function(_, opts)
      local persistence = require "persistence"
      persistence.setup(opts)
      -- setup() starts the VimLeavePre autosave; manual use (<leader>qs) with
      -- session persistence turned off must not start saving sessions.
      if not require("core.session_toggle").is_enabled() then
        persistence.stop()
      end
    end,
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
