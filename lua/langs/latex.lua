-- LaTeX with vimtex (compile/view/TOC) and texlab (completion, references).
-- vimtex mappings live under <leader>m (vimtex_mappings_prefix): <leader>ml
-- compile, <leader>mv view, <leader>me errors, <leader>mt TOC, ...
return {
  title = "LaTeX",
  description = "vimtex (latexmk or tectonic, Skim/zathura/Sumatra), texlab, tex-fmt|latexindent",
  filetypes = { "tex", "plaintex", "bib" },
  grep_type = "tex",
  options = {
    formatter = { default = "tex-fmt", choices = { "tex-fmt", "latexindent" }, desc = "Formatter" },
  },
  -- vimtex provides syntax highlighting (and needs it for its motions and
  -- text objects); treesitter highlighting would replace it.
  ts_highlight = { tex = false, plaintex = false },
  parsers = { "bibtex" },
  servers = function()
    -- Point texlab at the directory vimtex's compiler writes to (see init below),
    -- so it finds the log for its build diagnostics: build/ under latexmk, the
    -- source directory (texlab's default) under tectonic.
    local texlab = { mason = "texlab" }
    if vim.fn.executable "latexmk" == 1 then
      texlab.settings =
        { texlab = { build = { auxDirectory = "build", logDirectory = "build", pdfDirectory = "build" } } }
    end
    return { texlab = texlab }
  end,
  tools = function(o)
    return { o.formatter }
  end,
  formatters_by_ft = function(o)
    return { tex = { o.formatter }, plaintex = { o.formatter } }
  end,
  plugins = {
    {
      "lervag/vimtex",
      -- vimtex is autoload-based and asks not to be lazy-loaded.
      lazy = false,
      init = function()
        if vim.fn.has "mac" == 1 and vim.fn.isdirectory "/Applications/Skim.app" == 1 then
          -- Forward search via Skim's displayline; inverse search is configured
          -- in Skim (Settings > Sync: nvim --headless -c "VimtexInverseSearch %line '%file'").
          vim.g.vimtex_view_method = "skim"
          vim.g.vimtex_view_skim_sync = 1
          vim.g.vimtex_view_skim_activate = 1
        elseif vim.fn.executable "zathura" == 1 then
          vim.g.vimtex_view_method = "zathura"
        elseif vim.fn.has "win32" == 1 then
          vim.g.vimtex_view_method = "general"
          vim.g.vimtex_view_general_viewer = "SumatraPDF"
        end
        vim.g.vimtex_mappings_prefix = "<leader>m"
        vim.g.vimtex_syntax_conceal_disable = 1
        vim.g.vimtex_quickfix_open_on_warning = 1
        -- latexmk ships with TeX Live; a machine with only tectonic (no TeX Live
        -- install) compiles with tectonic instead. vimtex's tectonic backend is
        -- single-shot (no continuous mode), so <leader>ml builds once per press.
        -- latexmk writes to build/. tectonic writes beside the source: it refuses a
        -- missing --outdir, and vimtex (3abfa1f) only creates out_dir subdirectories
        -- for sources in subdirectories, never out_dir itself for a top-level main file.
        if vim.fn.executable "latexmk" == 1 then
          vim.g.vimtex_compiler_method = "latexmk"
          vim.g.vimtex_compiler_latexmk = {
            aux_dir = "build",
            out_dir = "build",
            callback = 1,
            continuous = 1,
            executable = "latexmk",
            options = { "-pdf", "-synctex=1", "-interaction=nonstopmode", "-file-line-error" },
          }
        else
          vim.g.vimtex_compiler_method = "tectonic"
          -- --keep-logs feeds the quickfix list; --synctex keeps Skim forward/inverse search.
          vim.g.vimtex_compiler_tectonic = { out_dir = "", options = { "--keep-logs", "--synctex" } }
        end
      end,
    },
  },
  keys = {
    { "<leader>m", group = "LaTeX", icon = "" },
  },
}
