return {
  {
    "jake-stewart/multicursor.nvim",
    keys = {
      {
        "<C-Up>",
        function()
          require("multicursor-nvim").lineAddCursor(-1)
        end,
        desc = "Multi-Cursor: add above",
      },
      {
        "<C-Down>",
        function()
          require("multicursor-nvim").lineAddCursor(1)
        end,
        desc = "Multi-Cursor: add below",
      },
      {
        "gb",
        function()
          require("multicursor-nvim").matchAddCursor(1)
        end,
        desc = "Multi-Cursor: add next match",
      },
      {
        "gB",
        function()
          require("multicursor-nvim").matchAddCursor(-1)
        end,
        desc = "Multi-Cursor: add prev match",
      },
      {
        "<leader>va",
        function()
          require("multicursor-nvim").matchAllAddCursors()
        end,
        desc = "Multi-Cursor: add all matches",
      },
    },
    config = function()
      local mc = require "multicursor-nvim"
      mc.setup()
      -- These keys only exist while extra cursors are active, so <Esc> keeps
      -- its plain meaning (and :nohlsearch from core/keymaps.lua) otherwise.
      mc.addKeymapLayer(function(layer_set)
        layer_set({ "n", "x" }, "<left>", mc.prevCursor)
        layer_set({ "n", "x" }, "<right>", mc.nextCursor)
        layer_set("n", "<esc>", function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          else
            mc.clearCursors()
          end
        end)
      end)
    end,
  },
}
