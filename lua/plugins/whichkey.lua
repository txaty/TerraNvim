return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 200,
      icons = {
        breadcrumb = "»",
        separator = "→",
        group = "+",
        mappings = true,
      },
      win = {
        border = "rounded",
        padding = { 1, 2 },
      },
      layout = {
        spacing = 3,
      },
    },
    config = function(_, opts)
      local wk = require "which-key"
      wk.setup(opts)

      -- Register key groups with icons for visual consistency.
      -- Keep this list in sync with the prefixes actually in use — an
      -- unregistered prefix shows up in the which-key popup as a bare key with
      -- no label, and a registered-but-unused one advertises a group that is
      -- empty. Groups are verified against docs/keymaps.md.
      wk.add {
        -- Groups (prefixes with several mappings underneath)
        { "<leader>a", group = "AI", icon = "󰚩" },
        { "<leader>b", group = "Buffers", icon = "󰈔" },
        { "<leader>c", group = "Colors", icon = "󰏘" },
        { "<leader>C", group = "Crates", icon = "󰏗" },
        { "<leader>d", group = "Debug", icon = "󰃤" },
        { "<leader>f", group = "Find", icon = "󰍉" },
        { "<leader>F", group = "Flutter", icon = "󰙅" },
        { "<leader>g", group = "Git", icon = "󰊢" },
        { "<leader>gv", group = "Diffview", icon = "󰆏" },
        { "<leader>i", group = "Image", icon = "󰋩" },
        { "<leader>l", group = "LSP", icon = "󰒋" },
        { "<leader>L", group = "Language", icon = "󰗊" },
        { "<leader>lp", group = "LSP Peek", icon = "󰈈" },
        { "<leader>lw", group = "LSP Workspace", icon = "󰉖" },
        { "<leader>m", group = "Markdown", icon = "󰍔" },
        { "<leader>n", group = "Notify", icon = "󰂞" },
        { "<leader>o", group = "Tasks", icon = "󰑮" },
        { "<leader>p", group = "Python", icon = "󰌠" },
        { "<leader>q", group = "Session", icon = "󰁯" },
        { "<leader>r", group = "Remote", icon = "󰢹" },
        { "<leader>R", group = "Rust", icon = "󱘗" },
        { "<leader>s", group = "Search/Symbols", icon = "󰑑" },
        { "<leader>t", group = "Test", icon = "󰙨" },
        { "<leader>T", group = "Terminal", icon = "" },
        { "<leader>u", group = "UI/Display", icon = "󰙵" },
        { "<leader>v", group = "Multi-Cursor", icon = "󰇀" },
        { "<leader>w", group = "Windows", icon = "󰖲" },
        { "<leader>x", group = "Diagnostics", icon = "󰒡" },

        -- Standalone mappings that would otherwise render unlabelled
        { "<leader>.", icon = "󰎚", desc = "Scratch buffer" },
        { "<leader>D", icon = "󰊕", desc = "LSP: Type definition" },
        { "<leader>H", icon = "󰋜", desc = "Dashboard (Home)" },
        { "<leader>j", icon = "󰗈", desc = "Split/Join toggle" },
        { "<leader>S", icon = "󰛔", desc = "Search & Replace" },
      }
    end,
  },
}
