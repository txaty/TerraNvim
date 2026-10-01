return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      -- Keep blame available on demand; disable background blame updates by default.
      current_line_blame = false,
      current_line_blame_opts = {
        delay = 300,
      },
      on_attach = function(bufnr)
        local gs = require "gitsigns"
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Navigation.
        -- next_hunk/prev_hunk are deprecated aliases; nav_hunk is the current API.
        map("n", "]h", function()
          gs.nav_hunk "next"
        end, "Git: Next hunk")
        map("n", "[h", function()
          gs.nav_hunk "prev"
        end, "Git: Previous hunk")

        -- Actions
        map("n", "<leader>gs", gs.stage_hunk, "Git: Stage hunk")
        map("v", "<leader>gs", function()
          gs.stage_hunk { vim.fn.line ".", vim.fn.line "v" }
        end, "Git: Stage hunk")
        map("n", "<leader>gr", gs.reset_hunk, "Git: Reset hunk")
        map("v", "<leader>gr", function()
          gs.reset_hunk { vim.fn.line ".", vim.fn.line "v" }
        end, "Git: Reset hunk")
        map("n", "<leader>gS", gs.stage_buffer, "Git: Stage buffer")
        map("n", "<leader>gR", gs.reset_buffer, "Git: Reset buffer")
        -- gitsigns marks undo_stage_hunk deprecated (in 1.x <leader>gs already
        -- toggles: stage_hunk on a staged hunk unstages it). Kept as an explicit
        -- "unstage" key because it still works and there is no direct
        -- replacement that is distinct from <leader>gs.
        map("n", "<leader>gu", gs.undo_stage_hunk, "Git: Undo stage hunk")
        map("n", "<leader>gp", gs.preview_hunk_inline, "Git: Preview hunk inline")
        map("n", "<leader>gP", gs.preview_hunk, "Git: Preview hunk (float)")
        map("n", "<leader>gb", function()
          gs.blame_line { full = true }
        end, "Git: Blame line")
        map("n", "<leader>gB", gs.toggle_current_line_blame, "Git: Toggle blame")
        map("n", "<leader>gd", gs.diffthis, "Git: Diff this")
        map("n", "<leader>gD", function()
          gs.diffthis "~"
        end, "Git: Diff against HEAD")
        -- gitsigns marks toggle_deleted deprecated in favour of
        -- preview_hunk_inline (<leader>gp), but that previews one hunk while
        -- this toggles deleted lines buffer-wide. No supported equivalent, so
        -- it stays.
        map("n", "<leader>gI", gs.toggle_deleted, "Git: Toggle inline deleted")
        map("n", "<leader>gw", gs.toggle_word_diff, "Git: Toggle word diff")

        -- Text object
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Git: Select hunk")
      end,
    },
  },
  {
    -- Maintained fork of sindrets/diffview.nvim (unmaintained since 2024).
    -- Same `diffview` module and :Diffview* commands.
    "dlyongemallo/diffview-plus.nvim",
    version = "*",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
      "DiffviewRefresh",
    },
    opts = {
      enhanced_diff_hl = true,
      -- Sessions are restored at VimEnter, before this cmd-lazy plugin loads,
      -- so its SessionLoadPost replay never runs; don't write the
      -- <session>.diffview.json sidecars nobody reads.
      restore_session = false,
      view = {
        default = { layout = "diff2_horizontal" },
        -- 3-way merge view used during merges/rebases with conflicts
        -- (replaces git-conflict.nvim): [x ]x jump, <leader>co/ct/cb/ca pick
        -- ours/theirs/base/all, dx deletes the conflict region.
        merge_tool = { layout = "diff3_mixed", disable_diagnostics = true },
      },
      file_panel = {
        listing_style = "list",
        win_config = { position = "left", width = 35 },
      },
    },
    -- Prefix is <leader>gv ("git view"), not <leader>gd.
    -- gitsigns maps a buffer-local <leader>gd (diff this). A complete mapping
    -- that is also the prefix of longer mappings is ambiguous: Neovim has to
    -- wait the full 'timeoutlen' (400ms here) before it can fire the short one.
    -- Under <leader>gd* every diff-this press stalled. Splitting the prefixes
    -- makes both immediate.
    keys = {
      { "<leader>gvo", "<cmd>DiffviewOpen<cr>", desc = "Diffview: open" },
      { "<leader>gvc", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
      { "<leader>gvf", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: file history" },
      { "<leader>gvs", "<cmd>DiffviewOpen --staged<cr>", desc = "Diffview: staged changes" },
      { "<leader>gvh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: repo history" },
      { "<leader>gvb", "<cmd>DiffviewOpen HEAD~1<cr>", desc = "Diffview: compare prev commit" },
      { "<leader>gvm", "<cmd>DiffviewOpen<cr>", desc = "Diffview: resolve merge conflicts" },
    },
  },

  -- lazygit in a float (replaces lazygit.nvim); `configure` makes lazygit use
  -- the current colorscheme and open files in this Neovim.
  {
    "folke/snacks.nvim",
    opts = { lazygit = { configure = true } },
    keys = {
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "Git: lazygit",
      },
      {
        "<leader>gl",
        function()
          Snacks.lazygit.log_file()
        end,
        desc = "Git: lazygit file log",
      },
      {
        "<leader>gL",
        function()
          Snacks.lazygit.log()
        end,
        desc = "Git: lazygit log",
      },
    },
  },
}
