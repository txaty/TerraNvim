-- Per-buffer treesitter attach, used by the nvim-treesitter FileType autocmd
-- (lua/plugins/treesitter.lua) and after a parser finishes installing.
local M = {}

-- Parsers every setup wants, with no owning pack: Neovim's own filetypes,
-- injections used almost everywhere (regex, diff) and markdown for LSP hovers.
M.base_parsers = { "c", "diff", "lua", "markdown", "markdown_inline", "query", "regex", "vim", "vimdoc" }

---@param buf integer
function M.attach(buf)
  local ft = vim.bo[buf].filetype
  if ft == "" or vim.bo[buf].buftype ~= "" and vim.bo[buf].buftype ~= "help" then
    return
  end
  local lang = vim.treesitter.language.get_lang(ft) or ft
  local core_lang = require "core.lang"
  if core_lang.collect.ts_disabled()[ft] then
    return
  end

  if pcall(vim.treesitter.start, buf, lang) then
    -- nvim-treesitter's indentexpr returns -1 ("keep current indent") for
    -- languages without an indents query, which is worse than Vim's own
    -- indent; only use it where the query exists.
    if vim.treesitter.query.get(lang, "indents") then
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
    return
  end

  -- No parser yet. Install it if an enabled pack (or the base list) wants it.
  local owner = core_lang.owner(ft)
  local wanted = vim.tbl_contains(M.base_parsers, lang)
    or (owner and core_lang.is_enabled(owner) and vim.tbl_contains(core_lang.collect.parsers { owner }, lang))
  local install = require "core.lang.install"
  if wanted and install.auto_allowed() then
    install.parsers { lang }
  end
end

return M
