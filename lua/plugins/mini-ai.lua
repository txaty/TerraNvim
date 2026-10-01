return {
  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    opts = function()
      local ai = require "mini.ai"
      return {
        n_lines = 500,
        -- mini.ai's defaults map `an`/`in` ("around/inside next"), which would
        -- shadow Neovim 0.12's native incremental selection (v_an / v_in, LSP
        -- selectionRange or treesitter). Disable them; `a`/`i` with a count work.
        mappings = { around_next = "", inside_next = "" },
        custom_textobjects = {
          o = ai.gen_spec.treesitter { -- code block
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          },
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().-()</[^/]->)$" },
        },
      }
    end,
  },
}
