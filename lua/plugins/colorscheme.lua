-- Colorscheme plugins. All lazy without a trigger: core.theme loads the one it
-- applies (lazy.load), so unused themes cost nothing at startup. The registry
-- of selectable variants lives in lua/core/theme.lua; `opts` here are merged
-- into the setup() calls core.theme makes for themes that need one.
--
-- Curated for maintenance and coverage: every plugin ships dark and light
-- variants. Plus the built-in txaty themes (lua/core/theme_txaty*.lua).
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    -- auto_integrations styles every installed plugin catppuccin supports.
    opts = { flavour = "mocha", auto_integrations = true },
  },
  { "folke/tokyonight.nvim", lazy = true, opts = {} },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = { commentStyle = { italic = true }, keywordStyle = { italic = true } },
  },
  {
    "sainnhe/everforest",
    lazy = true,
    init = function()
      vim.g.everforest_background = "medium"
      vim.g.everforest_better_performance = 1
    end,
  },
  { "EdenEast/nightfox.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  {
    "sainnhe/gruvbox-material",
    lazy = true,
    init = function()
      vim.g.gruvbox_material_background = "medium"
      vim.g.gruvbox_material_foreground = "material"
      vim.g.gruvbox_material_better_performance = 1
    end,
  },
  { "navarasu/onedark.nvim", lazy = true, opts = {} },
  {
    "scottmckendry/cyberdream.nvim",
    lazy = true,
    opts = { transparent = false, italic_comments = true },
  },
  { "craftzdog/solarized-osaka.nvim", lazy = true, opts = {} },
  { "Mofiqul/vscode.nvim", lazy = true, opts = { italic_comments = true } },
  { "miikanissi/modus-themes.nvim", lazy = true, opts = {} },
}
