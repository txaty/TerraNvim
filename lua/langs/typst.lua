-- Typst: tinymist (LSP, typstyle formatting) and typst-preview (live preview).
return {
  title = "Typst",
  description = "tinymist (+typstyle formatting), typst-preview",
  filetypes = { "typst" },
  grep_type = "typst",
  parsers = { "typst" },
  servers = {
    tinymist = { mason = "tinymist", settings = { formatterMode = "typstyle" } },
  },
  plugins = {
    {
      "chomosuke/typst-preview.nvim",
      version = "1.*",
      cmd = { "TypstPreview", "TypstPreviewToggle", "TypstPreviewUpdate" },
      -- Use Mason's tinymist instead of downloading its own (older) copy.
      -- websocat is still downloaded on first preview (not in Mason).
      opts = { dependencies_bin = { tinymist = "tinymist" } },
    },
  },
  keys = {
    { "<leader>m", group = "Typst", icon = "" },
    { "<leader>mp", "<cmd>TypstPreviewToggle<cr>", desc = "Typst: Toggle preview" },
  },
}
