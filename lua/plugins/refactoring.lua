-- refactoring.nvim 2.x: extract/inline function and variable (treesitter + LSP).
--
-- 2.0 replaced refactor("<name>") with one operator per refactoring. Each
-- returns an operator string ("g@"), so the mappings MUST be `expr = true`; in
-- normal mode they take a motion/textobject (e.g. <leader>leif extracts the
-- inner function body, <leader>lE_ the current line). The 1.x mappings here had
-- no `expr`, so they never actually ran a refactoring.
return {
  {
    "ThePrimeagen/refactoring.nvim",
    -- async.nvim is only needed on Neovim 0.12 (0.13 ships the API); drop it then.
    dependencies = { "lewis6991/async.nvim" },
    keys = {
      {
        "<leader>le",
        function()
          return require("refactoring").extract_func()
        end,
        mode = { "n", "x" },
        expr = true,
        desc = "Refactor: Extract function",
      },
      {
        "<leader>lE",
        function()
          return require("refactoring").extract_var()
        end,
        mode = { "n", "x" },
        expr = true,
        desc = "Refactor: Extract variable",
      },
      {
        "<leader>li",
        function()
          return require("refactoring").inline_var()
        end,
        mode = { "n", "x" },
        expr = true,
        desc = "Refactor: Inline variable",
      },
      {
        "<leader>lI",
        function()
          return require("refactoring").inline_func()
        end,
        mode = { "n", "x" },
        expr = true,
        desc = "Refactor: Inline function",
      },
      {
        "<leader>lR",
        function()
          require("refactoring").select_refactor()
        end,
        mode = { "n", "x" },
        desc = "Refactor: Menu",
      },
    },
  },
}
