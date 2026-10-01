return {
  {
    "nvim-neotest/neotest",
    keys = {
      {
        "<leader>tn",
        function()
          require("neotest").run.run()
        end,
        desc = "Test: run nearest",
      },
      {
        "<leader>tf",
        function()
          require("neotest").run.run(vim.fn.expand "%")
        end,
        desc = "Test: run file",
      },
      {
        "<leader>ts",
        function()
          require("neotest").run.run { suite = true }
        end,
        desc = "Test: run suite",
      },
      {
        "<leader>to",
        function()
          require("neotest").output.open { enter = true }
        end,
        desc = "Test: open output",
      },
      {
        "<leader>tt",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Test: toggle summary",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      -- Adapters come from the enabled language packs (`test.adapter`); their
      -- plugins are pack-owned lazy specs that load on require.
      local adapters = {}
      local lang = require "core.lang"
      for _, entry in ipairs(lang.collect.tests()) do
        local ok, adapter = pcall(entry.adapter, lang.opts(entry.pack))
        if ok and type(adapter) == "table" and vim.islist(adapter) then
          vim.list_extend(adapters, adapter) -- a pack may return several adapters
        elseif ok and adapter then
          adapters[#adapters + 1] = adapter
        elseif not ok then
          vim.notify(("neotest adapter for %s failed: %s"):format(entry.pack, adapter), vim.log.levels.WARN)
        end
      end

      require("neotest").setup {
        adapters = adapters,
        quickfix = { open = false },
        summary = { animated = false },
      }
    end,
  },

  -- Test coverage gutters
  {
    "andythigpen/nvim-coverage",
    cmd = { "Coverage", "CoverageToggle", "CoverageSummary", "CoverageLoad" },
    keys = {
      { "<leader>tc", "<cmd>CoverageToggle<cr>", desc = "Test: Toggle coverage" },
      { "<leader>tC", "<cmd>CoverageSummary<cr>", desc = "Test: Coverage summary" },
      { "<leader>tL", "<cmd>CoverageLoad<cr>", desc = "Test: Load coverage" },
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      auto_reload = true,
    },
  },
}
