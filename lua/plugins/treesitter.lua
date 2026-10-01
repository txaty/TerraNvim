return {
  {
    -- branch = "main" (not "master"): the master branch is archived and its
    -- query_predicates.lua is incompatible with Neovim 0.12+, which changed
    -- match tables from single TSNodes to arrays of TSNodes. This caused the
    -- "attempt to call method 'range' (a nil value)" conceal_line error on
    -- every markdown open. The main branch removes query_predicates.lua
    -- entirely (directives upstreamed to Neovim core) and requires Neovim 0.11+.
    -- API change: require("nvim-treesitter").setup(opts) replaces the old
    -- require("nvim-treesitter.configs").setup(opts) pattern. ensure_installed
    -- is passed directly to setup(); the .install() method no longer exists.
    -- lazy = false: the main branch README explicitly states it does not support
    -- lazy-loading.
    "nvim-treesitter/nvim-treesitter",
    version = false,
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
    },
    config = function(_, opts)
      -- setup() accepts ensure_installed directly in the main branch API
      require("nvim-treesitter").setup(opts)

      -- Enable treesitter highlighting and indentation for all filetypes
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      -- Set folding after treesitter loads (deferred from options.lua for faster startup)
      -- Use native Neovim 0.11+ foldexpr (faster than vimscript nvim_treesitter#foldexpr)
      vim.opt.foldmethod = "expr"
      vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end,
  },

  -- Treesitter textobjects.
  -- branch = "main": the main branch is a full rewrite. Config is no longer
  -- nested under nvim-treesitter.configs — it is a standalone plugin with an
  -- explicit setup() call and direct vim.keymap.set() calls per operation,
  -- replacing the old declarative opts.textobjects table.
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local move = require "nvim-treesitter-textobjects.move"
      local swap = require "nvim-treesitter-textobjects.swap"

      -- Selection (af/if, ac/ic, ...) is owned by mini.ai (lua/plugins/mini-ai.lua),
      -- which reuses these queries; this plugin only provides motions and swaps.
      require("nvim-treesitter-textobjects").setup { move = { set_jumps = true } }

      ---@param lhs string
      ---@param fn "goto_next_start"|"goto_next_end"|"goto_previous_start"|"goto_previous_end"
      ---@param query string
      local function map_move(lhs, fn, query)
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          -- ]c/[c are also Vim's "next/previous change" in diff mode; keep that
          -- meaning there (same approach as LazyVim).
          if vim.wo.diff and lhs:find "[cC]" then
            return vim.cmd("normal! " .. vim.v.count1 .. lhs)
          end
          move[fn](query, "textobjects")
        end, { desc = fn:gsub("_", " "):gsub("^goto ", "") .. " " .. query })
      end

      map_move("]f", "goto_next_start", "@function.outer")
      map_move("]F", "goto_next_end", "@function.outer")
      map_move("[f", "goto_previous_start", "@function.outer")
      map_move("[F", "goto_previous_end", "@function.outer")
      map_move("]c", "goto_next_start", "@class.outer")
      map_move("]C", "goto_next_end", "@class.outer")
      map_move("[c", "goto_previous_start", "@class.outer")
      map_move("[C", "goto_previous_end", "@class.outer")
      -- Parameters use ], / [, so Neovim's default ]a/[a (arglist) keep working.
      map_move("],", "goto_next_start", "@parameter.inner")
      map_move("[,", "goto_previous_start", "@parameter.inner")

      vim.keymap.set("n", "<leader>sa", function()
        swap.swap_next "@parameter.inner"
      end, { desc = "Swap next parameter" })
      vim.keymap.set("n", "<leader>sA", function()
        swap.swap_previous "@parameter.inner"
      end, { desc = "Swap prev parameter" })
    end,
  },

  -- Sticky context header (shows function/class scope at top)
  {
    "nvim-treesitter/nvim-treesitter-context",
    -- VeryLazy: context header appears after first paint, not blocking initial render
    -- Still available for all editing; keys also trigger loading
    event = "VeryLazy",
    opts = {
      enable = true,
      max_lines = 3,
      min_window_height = 20,
      mode = "cursor",
    },
    keys = {
      {
        "<leader>ut",
        function()
          require("treesitter-context").toggle()
        end,
        desc = "UI: Toggle context",
      },
      {
        "gC",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Go to context",
      },
    },
  },
}
