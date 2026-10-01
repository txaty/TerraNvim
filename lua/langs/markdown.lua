-- Markdown: marksman for links/headings, render-markdown for in-buffer
-- rendering, and an external-reader opener.
local function open_external()
  local filepath = vim.fn.expand "%:p"
  if not require("core.security").confirm_external("Open markdown file in external reader?", filepath) then
    return
  end
  if vim.fn.has "mac" == 1 and vim.fn.isdirectory "/Applications/Typora.app" == 1 then
    vim.system({ "open", "-a", "Typora", filepath }, { detach = true })
  elseif vim.fn.executable "typora" == 1 then
    vim.system({ "typora", filepath }, { detach = true })
  else
    -- Neovim's opener: open/xdg-open/explorer.exe with the path as one
    -- argument (no cmd.exe re-parsing of & or | in file names).
    vim.ui.open(filepath)
  end
end

return {
  title = "Markdown",
  description = "marksman, render-markdown; optional prettier format and markdownlint",
  filetypes = { "markdown" },
  grep_type = "md",
  options = {
    format = { default = false, choices = { true, false }, desc = "Format with prettier on save" },
    lint = { default = false, choices = { true, false }, desc = "Lint with markdownlint-cli2" },
  },
  parsers = { "markdown", "markdown_inline" },
  servers = {
    marksman = { mason = "marksman" },
  },
  tools = function(o)
    local tools = {}
    if o.format then
      tools[#tools + 1] = "prettierd"
    end
    if o.lint then
      tools[#tools + 1] = "markdownlint-cli2"
    end
    return tools
  end,
  formatters_by_ft = function(o)
    return o.format and { markdown = { "prettierd", "prettier", stop_after_first = true } } or {}
  end,
  formatters = function()
    local trust = require "core.trust"
    return {
      prettier = { command = trust.node_bin "prettier", condition = trust.formatter_condition "prettier" },
      prettierd = { condition = trust.formatter_condition "prettier" },
    }
  end,
  linters_by_ft = function(o)
    return o.lint and { markdown = { "markdownlint-cli2" } } or {}
  end,
  linters = {
    -- markdownlint-cli2 configs can be JavaScript (.markdownlint-cli2.cjs).
    ["markdownlint-cli2"] = {
      condition = function(ctx)
        return require("core.trust").allows("markdownlint-cli2", ctx.buf)
      end,
    },
  },
  plugins = {
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = "markdown",
      dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
      opts = {
        heading = {
          enabled = true,
          sign = true,
          position = "overlay",
          icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
          signs = { "󰫎 " },
          width = "full",
          left_pad = 0,
          right_pad = 0,
          min_width = 0,
        },
        code = {
          enabled = true,
          sign = true,
          style = "full",
          position = "left",
          language_pad = 0,
          disable_background = { "diff" },
          width = "full",
          left_pad = 0,
          right_pad = 0,
          min_width = 0,
        },
        dash = {
          enabled = true,
          icon = "─",
          width = "full",
        },
        bullet = {
          enabled = true,
          icons = { "●", "○", "◆", "◇" },
          left_pad = 0,
          right_pad = 0,
        },
        checkbox = {
          enabled = true,
          unchecked = { icon = "󰄱 " },
          checked = { icon = "󰄵 " },
          custom = {
            todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
          },
        },
        pipe_table = {
          enabled = true,
          preset = "round",
          style = "full",
          cell = "padded",
          padding = 1,
          min_width = 0,
          border = {
            "┌",
            "┬",
            "┐",
            "├",
            "┼",
            "┤",
            "└",
            "┴",
            "┘",
            "│",
            "─",
          },
        },
        callout = {
          note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
          tip = { raw = "[!TIP]", rendered = "󰌵 Tip", highlight = "RenderMarkdownSuccess" },
          important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
          warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
          caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
        },
      },
    },
  },
  keys = {
    { "<leader>m", group = "Markdown", icon = "󰍔" },
    { "<leader>mo", open_external, desc = "Markdown: Open in external reader" },
    { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", desc = "Markdown: Toggle rendering" },
  },
}
