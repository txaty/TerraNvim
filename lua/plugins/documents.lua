-- Document preparation systems: LaTeX (vimtex) and Typst
return {
  {
    "lervag/vimtex",
    cond = function()
      return require("core.lang_toggle").is_enabled "latex"
    end,
    ft = "tex",
    lazy = true,
    config = function()
      -- Skim as the PDF viewer: vimtex drives forward search via Skim's bundled
      -- `displayline`. Inverse search (Cmd-Shift-click in Skim) is configured on
      -- the Skim side (Settings > Sync: Custom, nvim --headless -c "VimtexInverseSearch ...").
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_activate = 1

      -- Disable concealment for better readability
      vim.g.vimtex_syntax_conceal_disable = 1

      -- Configure the compiler method to use latexmk with pdflatex
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        build_dir = "build", -- Use 'build' directory for output files
        callback = 1,
        continuous = 1,
        executable = "latexmk",
        options = {
          "-pdf", -- Compile to PDF using pdflatex
          "-synctex=1", -- Enable SyncTeX for forward and inverse search
          "-interaction=nonstopmode", -- Continue compiling even if errors occur
          "-file-line-error", -- Display errors with file and line number
          "-aux-directory=build",
          "-output-directory=build",
        },
      }

      -- Buffer-local diagnostic config for TeX files only
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "tex",
        group = vim.api.nvim_create_augroup("VimtexDiagnostics", { clear = true }),
        callback = function()
          vim.diagnostic.config({
            virtual_text = true,
            signs = true,
            underline = true,
            severity_sort = true,
            update_in_insert = false,
          }, vim.api.nvim_create_namespace "vimtex")
        end,
      })

      -- Automatically open the quickfix window on warnings
      vim.g.vimtex_quickfix_open_on_warning = 1
    end,
  },

  {
    "chomosuke/typst-preview.nvim",
    cond = function()
      return require("core.lang_toggle").is_enabled "typst"
    end,
    ft = "typst",
    version = "1.*",
  },
}
