-- Custom "txaty" theme: Highlight group definitions
-- Accepts a palette table (from theme_txaty_colors.lua) and sets all highlight groups
--
-- Organized by category:
--   Editor UI → Syntax → Treesitter → LSP Semantic Tokens → Diagnostics →
--   Diff/Git → Plugin highlights (alphabetical)

---@param p table Palette table with color values
return function(p)
  local hl = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- ==========================================================================
  -- Editor UI (~30 groups)
  -- ==========================================================================
  hl("Normal", { fg = p.fg, bg = p.bg })
  hl("NormalFloat", { fg = p.fg, bg = p.bg_alt })
  hl("NormalNC", { fg = p.fg_dim, bg = p.bg })
  hl("FloatBorder", { fg = p.border, bg = p.bg_alt })
  hl("FloatTitle", { fg = p.fg, bg = p.bg_alt, bold = true })

  hl("Cursor", { fg = p.bg, bg = p.fg })
  hl("CursorLine", { bg = p.bg_highlight })
  hl("CursorColumn", { bg = p.bg_highlight })
  hl("CursorLineNr", { fg = p.fg, bg = p.bg_highlight })
  hl("LineNr", { fg = p.fg_muted })
  hl("SignColumn", { bg = p.bg })
  hl("FoldColumn", { fg = p.fg_muted, bg = p.bg })
  hl("Folded", { fg = p.fg_dim, bg = p.bg_dark })

  hl("VertSplit", { fg = p.border })
  hl("WinSeparator", { fg = p.border })
  hl("StatusLine", { fg = p.fg, bg = p.bg_alt })
  hl("StatusLineNC", { fg = p.fg_muted, bg = p.bg_dark })
  hl("TabLine", { fg = p.fg_dim, bg = p.bg_dark })
  hl("TabLineFill", { bg = p.bg_dark })
  hl("TabLineSel", { fg = p.fg, bg = p.bg, bold = true })

  -- Search and selection
  hl("Search", { fg = p.fg, bg = p.match })
  hl("IncSearch", { fg = p.bg, bg = p.accent1 })
  hl("CurSearch", { fg = p.bg, bg = p.accent1, bold = true })
  hl("Visual", { bg = p.bg_visual })
  hl("VisualNOS", { bg = p.bg_visual })

  -- Popup menu
  hl("Pmenu", { fg = p.fg, bg = p.bg_alt })
  hl("PmenuSel", { fg = p.fg, bg = p.bg_highlight, bold = true })
  hl("PmenuSbar", { bg = p.bg_dark })
  hl("PmenuThumb", { bg = p.border })

  -- Messages
  hl("ErrorMsg", { fg = p.error })
  hl("WarningMsg", { fg = p.warning })
  hl("MoreMsg", { fg = p.accent2 })
  hl("ModeMsg", { fg = p.fg_dim })
  hl("Question", { fg = p.accent3 })

  -- Misc UI
  hl("MatchParen", { fg = p.fg, bg = p.bg_highlight, bold = true })
  hl("NonText", { fg = p.fg_muted })
  hl("Whitespace", { fg = p.fg_muted })
  hl("EndOfBuffer", { fg = p.fg_muted })
  hl("SpecialKey", { fg = p.fg_muted })
  hl("Directory", { fg = p.accent3 })
  hl("Title", { fg = p.fg, bold = true })
  hl("Conceal", { fg = p.fg_dim })
  hl("ColorColumn", { bg = p.bg_highlight })

  -- ==========================================================================
  -- Syntax (~25 groups)
  -- ==========================================================================
  hl("Comment", { fg = p.fg_dim, italic = true })
  hl("Constant", { fg = p.accent1 })
  hl("String", { fg = p.accent1 })
  hl("Character", { fg = p.accent1 })
  hl("Number", { fg = p.accent1 })
  hl("Boolean", { fg = p.accent1 })
  hl("Float", { fg = p.accent1 })

  hl("Identifier", { fg = p.fg })
  hl("Function", { fg = p.accent3 })

  hl("Statement", { fg = p.accent4 })
  hl("Conditional", { fg = p.accent4 })
  hl("Repeat", { fg = p.accent4 })
  hl("Label", { fg = p.accent4 })
  hl("Operator", { fg = p.fg_dim })
  hl("Keyword", { fg = p.accent4 })
  hl("Exception", { fg = p.accent4 })

  hl("PreProc", { fg = p.accent4 })
  hl("Include", { fg = p.accent4 })
  hl("Define", { fg = p.accent4 })
  hl("Macro", { fg = p.accent4 })
  hl("PreCondit", { fg = p.accent4 })

  hl("Type", { fg = p.accent2 })
  hl("StorageClass", { fg = p.accent4 })
  hl("Structure", { fg = p.accent2 })
  hl("Typedef", { fg = p.accent2 })

  hl("Special", { fg = p.accent5 })
  hl("SpecialChar", { fg = p.accent5 })
  hl("Tag", { fg = p.accent3 })
  hl("Delimiter", { fg = p.fg_dim })
  hl("SpecialComment", { fg = p.fg_dim, italic = true })
  hl("Debug", { fg = p.accent5 })

  hl("Underlined", { fg = p.accent3, underline = true })
  hl("Error", { fg = p.error })
  hl("Todo", { fg = p.warning, bold = true })

  -- ==========================================================================
  -- Treesitter (~50 groups)
  -- ==========================================================================
  hl("@comment", { link = "Comment" })
  hl("@comment.documentation", { fg = p.fg_dim, italic = true })
  hl("@comment.error", { fg = p.error, italic = true })
  hl("@comment.warning", { fg = p.warning, italic = true })
  hl("@comment.todo", { fg = p.info, bold = true })
  hl("@comment.note", { fg = p.success, italic = true })

  hl("@constant", { link = "Constant" })
  hl("@constant.builtin", { fg = p.accent1 })
  hl("@constant.macro", { fg = p.accent1 })

  hl("@string", { link = "String" })
  hl("@string.escape", { fg = p.accent5 })
  hl("@string.special", { fg = p.accent5 })
  hl("@string.regex", { fg = p.accent5 })
  hl("@string.special.url", { fg = p.accent3, underline = true })
  hl("@string.special.path", { fg = p.accent1 })

  hl("@character", { link = "Character" })
  hl("@character.special", { fg = p.accent5 })
  hl("@number", { link = "Number" })
  hl("@number.float", { link = "Float" })
  hl("@boolean", { link = "Boolean" })
  hl("@float", { link = "Float" })

  hl("@function", { link = "Function" })
  hl("@function.builtin", { fg = p.accent3 })
  hl("@function.macro", { fg = p.accent3 })
  hl("@function.method", { fg = p.accent3 })
  hl("@function.call", { fg = p.accent3 })
  hl("@method", { fg = p.accent3 })
  hl("@method.call", { fg = p.accent3 })

  hl("@constructor", { fg = p.accent2 })
  hl("@parameter", { fg = p.fg })

  hl("@keyword", { link = "Keyword" })
  hl("@keyword.function", { fg = p.accent4 })
  hl("@keyword.operator", { fg = p.fg_dim })
  hl("@keyword.return", { fg = p.accent4 })
  hl("@keyword.import", { fg = p.accent4 })
  hl("@keyword.export", { fg = p.accent4 })
  hl("@keyword.coroutine", { fg = p.accent4 })
  hl("@keyword.conditional", { fg = p.accent4 })
  hl("@keyword.repeat", { fg = p.accent4 })
  hl("@keyword.exception", { fg = p.accent4 })

  hl("@conditional", { link = "Conditional" })
  hl("@repeat", { link = "Repeat" })
  hl("@label", { link = "Label" })
  hl("@operator", { link = "Operator" })
  hl("@exception", { link = "Exception" })

  hl("@variable", { fg = p.fg })
  hl("@variable.builtin", { fg = p.accent1 })
  hl("@variable.parameter", { fg = p.fg })
  hl("@variable.member", { fg = p.fg })

  hl("@type", { link = "Type" })
  hl("@type.builtin", { fg = p.accent2 })
  hl("@type.definition", { fg = p.accent2 })
  hl("@type.qualifier", { fg = p.accent4 })

  hl("@storageclass", { link = "StorageClass" })
  hl("@attribute", { fg = p.accent4 })
  hl("@attribute.builtin", { fg = p.accent4 })
  hl("@property", { fg = p.fg })
  hl("@field", { fg = p.fg })

  hl("@namespace", { fg = p.fg_dim })
  hl("@module", { fg = p.fg_dim })
  hl("@module.builtin", { fg = p.fg_dim })
  hl("@include", { link = "Include" })

  hl("@punctuation", { fg = p.fg_dim })
  hl("@punctuation.bracket", { fg = p.fg_dim })
  hl("@punctuation.delimiter", { fg = p.fg_dim })
  hl("@punctuation.special", { fg = p.accent5 })

  hl("@tag", { fg = p.accent3 })
  hl("@tag.attribute", { fg = p.fg })
  hl("@tag.delimiter", { fg = p.fg_dim })
  hl("@tag.builtin", { fg = p.accent3 })

  hl("@text", { fg = p.fg })
  hl("@text.strong", { bold = true })
  hl("@text.emphasis", { italic = true })
  hl("@text.underline", { underline = true })
  hl("@text.strike", { strikethrough = true })
  hl("@text.title", { fg = p.fg, bold = true })
  hl("@text.uri", { fg = p.accent3, underline = true })
  hl("@text.todo", { fg = p.warning, bold = true })
  hl("@text.note", { fg = p.info })
  hl("@text.warning", { fg = p.warning })
  hl("@text.danger", { fg = p.error })
  hl("@text.literal", { fg = p.accent1 })
  hl("@text.reference", { fg = p.accent3 })
  hl("@text.diff.add", { fg = p.success })
  hl("@text.diff.delete", { fg = p.error })

  -- New treesitter captures (nvim 0.9+)
  hl("@markup", { fg = p.fg })
  hl("@markup.heading", { fg = p.fg, bold = true })
  hl("@markup.heading.1", { fg = p.fg, bold = true })
  hl("@markup.heading.2", { fg = p.fg, bold = true })
  hl("@markup.heading.3", { fg = p.fg, bold = true })
  hl("@markup.heading.4", { fg = p.fg, bold = true })
  hl("@markup.heading.5", { fg = p.fg, bold = true })
  hl("@markup.heading.6", { fg = p.fg, bold = true })
  hl("@markup.strong", { bold = true })
  hl("@markup.italic", { italic = true })
  hl("@markup.strikethrough", { strikethrough = true })
  hl("@markup.underline", { underline = true })
  hl("@markup.link", { fg = p.accent3 })
  hl("@markup.link.url", { fg = p.accent3, underline = true })
  hl("@markup.link.label", { fg = p.accent3 })
  hl("@markup.raw", { fg = p.accent1 })
  hl("@markup.raw.block", { fg = p.accent1 })
  hl("@markup.list", { fg = p.accent3 })
  hl("@markup.list.checked", { fg = p.success })
  hl("@markup.list.unchecked", { fg = p.fg_dim })
  hl("@markup.quote", { fg = p.fg_dim, italic = true })
  hl("@markup.math", { fg = p.accent1 })
  hl("@markup.environment", { fg = p.accent4 })

  hl("@diff.plus", { fg = p.success })
  hl("@diff.minus", { fg = p.error })
  hl("@diff.delta", { fg = p.warning })

  -- ==========================================================================
  -- Treesitter Context (sticky headers)
  -- ==========================================================================
  hl("TreesitterContext", { bg = p.bg_dark })
  hl("TreesitterContextLineNumber", { fg = p.fg_muted, bg = p.bg_dark })
  hl("TreesitterContextSeparator", { fg = p.bg_highlight })
  hl("TreesitterContextBottom", { underline = true, sp = p.bg_highlight })

  -- ==========================================================================
  -- LSP Semantic Tokens (~15 groups)
  -- ==========================================================================
  hl("@lsp.type.class", { link = "@type" })
  hl("@lsp.type.decorator", { link = "@attribute" })
  hl("@lsp.type.enum", { link = "@type" })
  hl("@lsp.type.enumMember", { link = "@constant" })
  hl("@lsp.type.function", { link = "@function" })
  hl("@lsp.type.interface", { link = "@type" })
  hl("@lsp.type.macro", { link = "@constant.macro" })
  hl("@lsp.type.method", { link = "@method" })
  hl("@lsp.type.namespace", { link = "@namespace" })
  hl("@lsp.type.parameter", { link = "@parameter" })
  hl("@lsp.type.property", { link = "@property" })
  hl("@lsp.type.struct", { link = "@type" })
  hl("@lsp.type.type", { link = "@type" })
  hl("@lsp.type.typeParameter", { link = "@type" })
  hl("@lsp.type.variable", { link = "@variable" })
  hl("@lsp.type.comment", { link = "@comment" })
  hl("@lsp.type.string", { link = "@string" })
  hl("@lsp.type.keyword", { link = "@keyword" })
  hl("@lsp.type.number", { link = "@number" })
  hl("@lsp.type.regexp", { link = "@string.regex" })
  hl("@lsp.type.operator", { link = "@operator" })

  hl("@lsp.mod.deprecated", { strikethrough = true })
  hl("@lsp.mod.readonly", { italic = true })
  hl("@lsp.mod.defaultLibrary", { fg = p.accent3 })

  -- ==========================================================================
  -- Diagnostics (~20 groups)
  -- ==========================================================================
  hl("DiagnosticError", { fg = p.error })
  hl("DiagnosticWarn", { fg = p.warning })
  hl("DiagnosticInfo", { fg = p.info })
  hl("DiagnosticHint", { fg = p.fg_dim })
  hl("DiagnosticOk", { fg = p.success })

  hl("DiagnosticUnderlineError", { sp = p.error, undercurl = true })
  hl("DiagnosticUnderlineWarn", { sp = p.warning, undercurl = true })
  hl("DiagnosticUnderlineInfo", { sp = p.info, undercurl = true })
  hl("DiagnosticUnderlineHint", { sp = p.fg_dim, undercurl = true })
  hl("DiagnosticUnderlineOk", { sp = p.success, undercurl = true })

  hl("DiagnosticVirtualTextError", { fg = p.error, bg = p.bg_dark })
  hl("DiagnosticVirtualTextWarn", { fg = p.warning, bg = p.bg_dark })
  hl("DiagnosticVirtualTextInfo", { fg = p.info, bg = p.bg_dark })
  hl("DiagnosticVirtualTextHint", { fg = p.fg_dim, bg = p.bg_dark })
  hl("DiagnosticVirtualTextOk", { fg = p.success, bg = p.bg_dark })

  hl("DiagnosticSignError", { fg = p.error })
  hl("DiagnosticSignWarn", { fg = p.warning })
  hl("DiagnosticSignInfo", { fg = p.info })
  hl("DiagnosticSignHint", { fg = p.fg_dim })
  hl("DiagnosticSignOk", { fg = p.success })

  hl("DiagnosticFloatingError", { fg = p.error })
  hl("DiagnosticFloatingWarn", { fg = p.warning })
  hl("DiagnosticFloatingInfo", { fg = p.info })
  hl("DiagnosticFloatingHint", { fg = p.fg_dim })
  hl("DiagnosticFloatingOk", { fg = p.success })

  -- ==========================================================================
  -- Diff/Git (~15 groups)
  -- ==========================================================================
  hl("DiffAdd", { bg = p.diff_add_bg })
  hl("DiffChange", { bg = p.diff_change_bg })
  hl("DiffDelete", { bg = p.diff_delete_bg })
  hl("DiffText", { bg = p.diff_text_bg })

  hl("diffAdded", { fg = p.success })
  hl("diffRemoved", { fg = p.error })
  hl("diffChanged", { fg = p.warning })
  hl("diffFile", { fg = p.accent3 })
  hl("diffLine", { fg = p.fg_dim })
  hl("diffIndexLine", { fg = p.accent4 })

  -- Git Signs
  hl("GitSignsAdd", { fg = p.success })
  hl("GitSignsChange", { fg = p.warning })
  hl("GitSignsDelete", { fg = p.error })
  hl("GitSignsAddNr", { fg = p.success })
  hl("GitSignsChangeNr", { fg = p.warning })
  hl("GitSignsDeleteNr", { fg = p.error })
  hl("GitSignsAddLn", { bg = p.diff_add_bg })
  hl("GitSignsChangeLn", { bg = p.diff_change_bg })
  hl("GitSignsDeleteLn", { bg = p.diff_delete_bg })
  hl("GitSignsCurrentLineBlame", { fg = p.fg_muted, italic = true })
  hl("GitSignsAddInline", { bg = p.diff_add_bg })
  hl("GitSignsChangeInline", { bg = p.diff_change_bg })
  hl("GitSignsDeleteInline", { bg = p.diff_delete_bg })

  -- ==========================================================================
  -- Plugin: Bufferline (~50 groups)
  -- ==========================================================================
  local bl_bg = p.bg_dark
  local bl_bg_vis = p.bg_alt
  local bl_bg_sel = p.bg

  hl("BufferLineFill", { bg = bl_bg })
  hl("BufferLineBackground", { fg = p.fg_muted, bg = bl_bg })
  hl("BufferLineBuffer", { fg = p.fg_muted, bg = bl_bg })
  hl("BufferLineBufferVisible", { fg = p.fg_dim, bg = bl_bg_vis })
  hl("BufferLineBufferSelected", { fg = p.fg, bg = bl_bg_sel, bold = true })

  hl("BufferLineTab", { fg = p.fg_muted, bg = bl_bg })
  hl("BufferLineTabSelected", { fg = p.fg, bg = bl_bg_sel, bold = true })
  hl("BufferLineTabClose", { fg = p.fg_muted, bg = bl_bg })
  hl("BufferLineTabSeparator", { fg = bl_bg, bg = bl_bg })
  hl("BufferLineTabSeparatorSelected", { fg = bl_bg, bg = bl_bg_sel })

  hl("BufferLineCloseButton", { fg = p.fg_muted, bg = bl_bg })
  hl("BufferLineCloseButtonVisible", { fg = p.fg_dim, bg = bl_bg_vis })
  hl("BufferLineCloseButtonSelected", { fg = p.fg, bg = bl_bg_sel })

  hl("BufferLineSeparator", { fg = bl_bg, bg = bl_bg })
  hl("BufferLineSeparatorVisible", { fg = bl_bg, bg = bl_bg_vis })
  hl("BufferLineSeparatorSelected", { fg = bl_bg, bg = bl_bg_sel })

  hl("BufferLineIndicatorSelected", { fg = p.accent3, bg = bl_bg_sel })
  hl("BufferLineIndicatorVisible", { fg = p.fg_muted, bg = bl_bg_vis })

  hl("BufferLineModified", { fg = p.warning, bg = bl_bg })
  hl("BufferLineModifiedVisible", { fg = p.warning, bg = bl_bg_vis })
  hl("BufferLineModifiedSelected", { fg = p.warning, bg = bl_bg_sel })

  hl("BufferLineDuplicate", { fg = p.fg_muted, bg = bl_bg, italic = true })
  hl("BufferLineDuplicateVisible", { fg = p.fg_dim, bg = bl_bg_vis, italic = true })
  hl("BufferLineDuplicateSelected", { fg = p.fg_dim, bg = bl_bg_sel, italic = true })

  hl("BufferLineDiagnostic", { fg = p.fg_muted, bg = bl_bg })
  hl("BufferLineDiagnosticVisible", { fg = p.fg_dim, bg = bl_bg_vis })
  hl("BufferLineDiagnosticSelected", { fg = p.fg, bg = bl_bg_sel })

  hl("BufferLineError", { fg = p.error, bg = bl_bg })
  hl("BufferLineErrorVisible", { fg = p.error, bg = bl_bg_vis })
  hl("BufferLineErrorSelected", { fg = p.error, bg = bl_bg_sel })
  hl("BufferLineErrorDiagnostic", { fg = p.error, bg = bl_bg })
  hl("BufferLineErrorDiagnosticVisible", { fg = p.error, bg = bl_bg_vis })
  hl("BufferLineErrorDiagnosticSelected", { fg = p.error, bg = bl_bg_sel })

  hl("BufferLineWarning", { fg = p.warning, bg = bl_bg })
  hl("BufferLineWarningVisible", { fg = p.warning, bg = bl_bg_vis })
  hl("BufferLineWarningSelected", { fg = p.warning, bg = bl_bg_sel })
  hl("BufferLineWarningDiagnostic", { fg = p.warning, bg = bl_bg })
  hl("BufferLineWarningDiagnosticVisible", { fg = p.warning, bg = bl_bg_vis })
  hl("BufferLineWarningDiagnosticSelected", { fg = p.warning, bg = bl_bg_sel })

  hl("BufferLineInfo", { fg = p.info, bg = bl_bg })
  hl("BufferLineInfoVisible", { fg = p.info, bg = bl_bg_vis })
  hl("BufferLineInfoSelected", { fg = p.info, bg = bl_bg_sel })
  hl("BufferLineInfoDiagnostic", { fg = p.info, bg = bl_bg })
  hl("BufferLineInfoDiagnosticVisible", { fg = p.info, bg = bl_bg_vis })
  hl("BufferLineInfoDiagnosticSelected", { fg = p.info, bg = bl_bg_sel })

  hl("BufferLineHint", { fg = p.fg_dim, bg = bl_bg })
  hl("BufferLineHintVisible", { fg = p.fg_dim, bg = bl_bg_vis })
  hl("BufferLineHintSelected", { fg = p.fg_dim, bg = bl_bg_sel })
  hl("BufferLineHintDiagnostic", { fg = p.fg_dim, bg = bl_bg })
  hl("BufferLineHintDiagnosticVisible", { fg = p.fg_dim, bg = bl_bg_vis })
  hl("BufferLineHintDiagnosticSelected", { fg = p.fg_dim, bg = bl_bg_sel })

  hl("BufferLineNumbers", { fg = p.fg_muted, bg = bl_bg })
  hl("BufferLineNumbersVisible", { fg = p.fg_dim, bg = bl_bg_vis })
  hl("BufferLineNumbersSelected", { fg = p.fg, bg = bl_bg_sel })

  hl("BufferLineOffsetSeparator", { fg = p.border, bg = p.bg })
  hl("BufferLineTruncMarker", { fg = p.fg_muted, bg = bl_bg })

  hl("BufferLinePick", { fg = p.accent5, bg = bl_bg, bold = true })
  hl("BufferLinePickVisible", { fg = p.accent5, bg = bl_bg_vis, bold = true })
  hl("BufferLinePickSelected", { fg = p.accent5, bg = bl_bg_sel, bold = true })

  -- ==========================================================================
  -- Plugin: Lualine
  -- ==========================================================================
  hl("lualine_a_normal", { fg = p.bg, bg = p.accent3, bold = true })
  hl("lualine_b_normal", { fg = p.fg, bg = p.bg_alt })
  hl("lualine_c_normal", { fg = p.fg_dim, bg = p.bg_dark })

  hl("lualine_a_insert", { fg = p.bg, bg = p.success, bold = true })
  hl("lualine_b_insert", { fg = p.fg, bg = p.bg_alt })
  hl("lualine_c_insert", { fg = p.fg_dim, bg = p.bg_dark })

  hl("lualine_a_visual", { fg = p.bg, bg = p.accent5, bold = true })
  hl("lualine_b_visual", { fg = p.fg, bg = p.bg_alt })
  hl("lualine_c_visual", { fg = p.fg_dim, bg = p.bg_dark })

  hl("lualine_a_replace", { fg = p.bg, bg = p.error, bold = true })
  hl("lualine_b_replace", { fg = p.fg, bg = p.bg_alt })
  hl("lualine_c_replace", { fg = p.fg_dim, bg = p.bg_dark })

  hl("lualine_a_command", { fg = p.bg, bg = p.warning, bold = true })
  hl("lualine_b_command", { fg = p.fg, bg = p.bg_alt })
  hl("lualine_c_command", { fg = p.fg_dim, bg = p.bg_dark })

  hl("lualine_a_inactive", { fg = p.fg_muted, bg = p.bg_dark })
  hl("lualine_b_inactive", { fg = p.fg_muted, bg = p.bg_dark })
  hl("lualine_c_inactive", { fg = p.fg_muted, bg = p.bg_dark })

  -- ==========================================================================
  -- Plugin: Which-key
  -- ==========================================================================
  hl("WhichKey", { fg = p.accent3 })
  hl("WhichKeyGroup", { fg = p.accent4 })
  hl("WhichKeyDesc", { fg = p.fg })
  hl("WhichKeySeparator", { fg = p.fg_muted })
  hl("WhichKeyFloat", { bg = p.bg_alt })
  hl("WhichKeyBorder", { fg = p.border, bg = p.bg_alt })
  hl("WhichKeyValue", { fg = p.fg_dim })
  hl("WhichKeyNormal", { fg = p.fg, bg = p.bg_alt })

  -- ==========================================================================
  -- Plugin: blink.cmp (completion)
  -- ==========================================================================
  hl("BlinkCmpLabel", { fg = p.fg })
  hl("BlinkCmpLabelDeprecated", { fg = p.fg_muted, strikethrough = true })
  hl("BlinkCmpLabelMatch", { fg = p.accent1, bold = true })
  hl("BlinkCmpKind", { fg = p.fg_dim })
  hl("BlinkCmpSource", { fg = p.fg_muted })
  hl("BlinkCmpLabelDetail", { fg = p.fg_muted })
  hl("BlinkCmpLabelDescription", { fg = p.fg_muted })

  hl("BlinkCmpKindText", { fg = p.fg })
  hl("BlinkCmpKindMethod", { fg = p.accent3 })
  hl("BlinkCmpKindFunction", { fg = p.accent3 })
  hl("BlinkCmpKindConstructor", { fg = p.accent2 })
  hl("BlinkCmpKindField", { fg = p.fg })
  hl("BlinkCmpKindVariable", { fg = p.fg })
  hl("BlinkCmpKindClass", { fg = p.accent2 })
  hl("BlinkCmpKindInterface", { fg = p.accent2 })
  hl("BlinkCmpKindModule", { fg = p.fg_dim })
  hl("BlinkCmpKindProperty", { fg = p.fg })
  hl("BlinkCmpKindUnit", { fg = p.accent1 })
  hl("BlinkCmpKindValue", { fg = p.accent1 })
  hl("BlinkCmpKindEnum", { fg = p.accent2 })
  hl("BlinkCmpKindKeyword", { fg = p.accent4 })
  hl("BlinkCmpKindSnippet", { fg = p.accent5 })
  hl("BlinkCmpKindColor", { fg = p.accent5 })
  hl("BlinkCmpKindFile", { fg = p.fg })
  hl("BlinkCmpKindReference", { fg = p.accent5 })
  hl("BlinkCmpKindFolder", { fg = p.accent3 })
  hl("BlinkCmpKindEnumMember", { fg = p.accent1 })
  hl("BlinkCmpKindConstant", { fg = p.accent1 })
  hl("BlinkCmpKindStruct", { fg = p.accent2 })
  hl("BlinkCmpKindEvent", { fg = p.accent5 })
  hl("BlinkCmpKindOperator", { fg = p.fg_dim })
  hl("BlinkCmpKindTypeParameter", { fg = p.accent2 })

  -- ==========================================================================
  -- Plugin: Todo Comments
  -- ==========================================================================
  hl("TodoBgTODO", { fg = p.bg, bg = p.info, bold = true })
  hl("TodoBgFIX", { fg = p.bg, bg = p.error, bold = true })
  hl("TodoBgHACK", { fg = p.bg, bg = p.warning, bold = true })
  hl("TodoBgWARN", { fg = p.bg, bg = p.warning, bold = true })
  hl("TodoBgNOTE", { fg = p.bg, bg = p.success, bold = true })
  hl("TodoBgPERF", { fg = p.bg, bg = p.accent5, bold = true })
  hl("TodoBgTEST", { fg = p.bg, bg = p.accent3, bold = true })

  hl("TodoFgTODO", { fg = p.info })
  hl("TodoFgFIX", { fg = p.error })
  hl("TodoFgHACK", { fg = p.warning })
  hl("TodoFgWARN", { fg = p.warning })
  hl("TodoFgNOTE", { fg = p.success })
  hl("TodoFgPERF", { fg = p.accent5 })
  hl("TodoFgTEST", { fg = p.accent3 })

  hl("TodoSignTODO", { fg = p.info })
  hl("TodoSignFIX", { fg = p.error })
  hl("TodoSignHACK", { fg = p.warning })
  hl("TodoSignWARN", { fg = p.warning })
  hl("TodoSignNOTE", { fg = p.success })
  hl("TodoSignPERF", { fg = p.accent5 })
  hl("TodoSignTEST", { fg = p.accent3 })

  -- ==========================================================================
  -- Plugin: Lazy.nvim
  -- ==========================================================================
  hl("LazyH1", { fg = p.bg, bg = p.accent3, bold = true })
  hl("LazyH2", { fg = p.fg, bold = true })
  hl("LazyButton", { fg = p.fg, bg = p.bg_alt })
  hl("LazyButtonActive", { fg = p.bg, bg = p.accent3 })
  hl("LazySpecial", { fg = p.accent3 })
  hl("LazyProgressDone", { fg = p.success })
  hl("LazyProgressTodo", { fg = p.fg_muted })
  hl("LazyCommit", { fg = p.fg_dim })
  hl("LazyReasonCmd", { fg = p.accent4 })
  hl("LazyReasonEvent", { fg = p.warning })
  hl("LazyReasonFt", { fg = p.accent2 })
  hl("LazyReasonImport", { fg = p.accent3 })
  hl("LazyReasonKeys", { fg = p.accent5 })
  hl("LazyReasonPlugin", { fg = p.accent1 })
  hl("LazyReasonSource", { fg = p.fg_dim })
  hl("LazyReasonStart", { fg = p.success })

  -- ==========================================================================
  -- Plugin: Mason
  -- ==========================================================================
  hl("MasonHeader", { fg = p.bg, bg = p.accent3, bold = true })
  hl("MasonHighlight", { fg = p.accent3 })
  hl("MasonHighlightBlock", { fg = p.bg, bg = p.accent3 })
  hl("MasonHighlightBlockBold", { fg = p.bg, bg = p.accent3, bold = true })
  hl("MasonMuted", { fg = p.fg_muted })
  hl("MasonMutedBlock", { fg = p.fg_muted, bg = p.bg_alt })
  hl("MasonHeaderSecondary", { fg = p.bg, bg = p.accent2, bold = true })
  hl("MasonHighlightSecondary", { fg = p.accent2 })
  hl("MasonHighlightBlockSecondary", { fg = p.bg, bg = p.accent2 })

  -- ==========================================================================
  -- Plugin: Noice
  -- ==========================================================================
  hl("NoiceCmdline", { fg = p.fg, bg = p.bg_alt })
  hl("NoiceCmdlineIcon", { fg = p.accent3 })
  hl("NoiceCmdlineIconSearch", { fg = p.warning })
  hl("NoiceCmdlinePopup", { fg = p.fg, bg = p.bg_alt })
  hl("NoiceCmdlinePopupBorder", { fg = p.border, bg = p.bg_alt })
  hl("NoiceCmdlinePopupTitle", { fg = p.fg, bg = p.bg_alt, bold = true })
  hl("NoiceConfirm", { fg = p.fg, bg = p.bg_alt })
  hl("NoiceConfirmBorder", { fg = p.border, bg = p.bg_alt })
  hl("NoiceMini", { fg = p.fg_dim, bg = p.bg_dark })
  hl("NoicePopup", { fg = p.fg, bg = p.bg_alt })
  hl("NoicePopupBorder", { fg = p.border, bg = p.bg_alt })
  hl("NoiceVirtualText", { fg = p.fg_dim })

  -- ==========================================================================
  -- Plugin: Flash
  -- ==========================================================================
  hl("FlashLabel", { fg = p.bg, bg = p.accent5, bold = true })
  hl("FlashMatch", { fg = p.fg, bg = p.match })
  hl("FlashCurrent", { fg = p.fg, bg = p.bg_highlight })
  hl("FlashBackdrop", { fg = p.fg_muted })
  hl("FlashPrompt", { fg = p.fg, bg = p.bg_alt })
  hl("FlashPromptIcon", { fg = p.accent3 })

  -- ==========================================================================
  -- Plugin: Trouble
  -- ==========================================================================
  hl("TroubleNormal", { fg = p.fg, bg = p.bg })
  hl("TroubleText", { fg = p.fg })
  hl("TroubleCount", { fg = p.accent5 })
  hl("TroubleSource", { fg = p.fg_dim })
  hl("TroubleFile", { fg = p.accent3 })
  hl("TroubleLocation", { fg = p.fg_dim })
  hl("TroubleCode", { fg = p.fg_dim })
  hl("TroublePos", { fg = p.fg_muted })
  hl("TroubleFoldIcon", { fg = p.accent3 })
  hl("TroubleIndent", { fg = p.fg_muted })
  hl("TroubleIndentFoldClosed", { fg = p.fg_muted })
  hl("TroubleIndentFoldOpen", { fg = p.fg_muted })
  hl("TroubleIndentLast", { fg = p.fg_muted })
  hl("TroubleIndentMiddle", { fg = p.fg_muted })
  hl("TroubleIndentTop", { fg = p.fg_muted })
  hl("TroubleIndentWs", { fg = p.fg_muted })

  -- ==========================================================================
  -- Plugin: DAP (Debug Adapter Protocol)
  -- ==========================================================================
  hl("DapBreakpoint", { fg = p.error })
  hl("DapLogPoint", { fg = p.info })
  hl("DapStopped", { fg = p.warning })
  hl("DapStoppedLine", { bg = p.bg_highlight })
  hl("DapBreakpointCondition", { fg = p.warning })
  hl("DapBreakpointRejected", { fg = p.fg_muted })

  hl("DapUIScope", { fg = p.accent3 })
  hl("DapUIType", { fg = p.accent2 })
  hl("DapUIModifiedValue", { fg = p.warning, bold = true })
  hl("DapUIDecoration", { fg = p.accent3 })
  hl("DapUIThread", { fg = p.success })
  hl("DapUIStoppedThread", { fg = p.accent3 })
  hl("DapUISource", { fg = p.accent5 })
  hl("DapUILineNumber", { fg = p.fg_dim })
  hl("DapUIFloatBorder", { fg = p.border })
  hl("DapUIWatchesEmpty", { fg = p.fg_muted })
  hl("DapUIWatchesValue", { fg = p.success })
  hl("DapUIWatchesError", { fg = p.error })
  hl("DapUIBreakpointsPath", { fg = p.accent3 })
  hl("DapUIBreakpointsInfo", { fg = p.success })
  hl("DapUIBreakpointsCurrentLine", { fg = p.fg, bold = true })
  hl("DapUIBreakpointsLine", { link = "DapUILineNumber" })
  hl("DapUIBreakpointsDisabledLine", { fg = p.fg_muted })
  hl("DapUICurrentFrameName", { link = "DapUIBreakpointsCurrentLine" })
  hl("DapUIStepOver", { fg = p.accent3 })
  hl("DapUIStepInto", { fg = p.accent3 })
  hl("DapUIStepBack", { fg = p.accent3 })
  hl("DapUIStepOut", { fg = p.accent3 })
  hl("DapUIStop", { fg = p.error })
  hl("DapUIPlayPause", { fg = p.success })
  hl("DapUIRestart", { fg = p.success })
  hl("DapUIUnavailable", { fg = p.fg_muted })
  hl("DapUIWinSelect", { fg = p.accent3, bold = true })

  -- ==========================================================================
  -- Plugin: Markdown
  -- ==========================================================================
  hl("markdownH1", { fg = p.fg, bold = true })
  hl("markdownH2", { fg = p.fg, bold = true })
  hl("markdownH3", { fg = p.fg, bold = true })
  hl("markdownH4", { fg = p.fg, bold = true })
  hl("markdownH5", { fg = p.fg, bold = true })
  hl("markdownH6", { fg = p.fg, bold = true })
  hl("markdownHeadingDelimiter", { fg = p.fg_dim })
  hl("markdownCode", { fg = p.accent1, bg = p.bg_dark })
  hl("markdownCodeBlock", { fg = p.accent1 })
  hl("markdownCodeDelimiter", { fg = p.fg_muted })
  hl("markdownBlockquote", { fg = p.fg_dim, italic = true })
  hl("markdownListMarker", { fg = p.accent3 })
  hl("markdownOrderedListMarker", { fg = p.accent3 })
  hl("markdownRule", { fg = p.fg_muted })
  hl("markdownLinkText", { fg = p.accent3 })
  hl("markdownUrl", { fg = p.fg_dim, underline = true })
  hl("markdownBold", { bold = true })
  hl("markdownItalic", { italic = true })
  hl("markdownId", { fg = p.accent4 })
  hl("markdownIdDeclaration", { fg = p.accent4 })
  hl("markdownIdDelimiter", { fg = p.fg_dim })

  -- ==========================================================================
  -- Plugin: Render-markdown
  -- ==========================================================================
  hl("RenderMarkdownH1", { fg = p.fg, bold = true })
  hl("RenderMarkdownH2", { fg = p.fg, bold = true })
  hl("RenderMarkdownH3", { fg = p.fg, bold = true })
  hl("RenderMarkdownH4", { fg = p.fg, bold = true })
  hl("RenderMarkdownH5", { fg = p.fg, bold = true })
  hl("RenderMarkdownH6", { fg = p.fg, bold = true })
  hl("RenderMarkdownH1Bg", { bg = p.bg_highlight })
  hl("RenderMarkdownH2Bg", { bg = p.bg_highlight })
  hl("RenderMarkdownH3Bg", { bg = p.bg_highlight })
  hl("RenderMarkdownH4Bg", { bg = p.bg_highlight })
  hl("RenderMarkdownH5Bg", { bg = p.bg_highlight })
  hl("RenderMarkdownH6Bg", { bg = p.bg_highlight })
  hl("RenderMarkdownCode", { bg = p.bg_dark })
  hl("RenderMarkdownCodeInline", { fg = p.accent1, bg = p.bg_dark })
  hl("RenderMarkdownBullet", { fg = p.accent3 })
  hl("RenderMarkdownQuote", { fg = p.fg_dim, italic = true })
  hl("RenderMarkdownDash", { fg = p.fg_muted })
  hl("RenderMarkdownLink", { fg = p.accent3 })
  hl("RenderMarkdownMath", { fg = p.accent1 })
  hl("RenderMarkdownChecked", { fg = p.success })
  hl("RenderMarkdownUnchecked", { fg = p.fg_muted })
  hl("RenderMarkdownTableHead", { fg = p.fg, bold = true })
  hl("RenderMarkdownTableRow", { fg = p.fg })
  hl("RenderMarkdownTableFill", { fg = p.fg_muted })

  -- ==========================================================================
  -- Plugin: snacks.nvim (picker, explorer, indent, words, zen, dashboard)
  -- ==========================================================================
  -- Picker and explorer
  hl("SnacksPicker", { fg = p.fg, bg = p.bg })
  hl("SnacksPickerBorder", { fg = p.border, bg = p.bg })
  hl("SnacksPickerTitle", { fg = p.fg, bg = p.bg, bold = true })
  hl("SnacksPickerInput", { fg = p.fg, bg = p.bg_alt })
  hl("SnacksPickerInputBorder", { fg = p.border, bg = p.bg_alt })
  hl("SnacksPickerPrompt", { fg = p.accent3 })
  hl("SnacksPickerListCursorLine", { bg = p.bg_highlight })
  hl("SnacksPickerMatch", { fg = p.accent1, bold = true })
  hl("SnacksPickerSelected", { fg = p.accent5 })
  hl("SnacksPickerDir", { fg = p.fg_dim })
  hl("SnacksPickerDirectory", { fg = p.accent3 })
  hl("SnacksPickerPathHidden", { fg = p.fg_muted })
  hl("SnacksPickerPathIgnored", { fg = p.fg_muted, italic = true })
  hl("SnacksPickerTree", { fg = p.fg_muted })
  hl("SnacksPickerGitStatusAdded", { fg = p.success })
  hl("SnacksPickerGitStatusModified", { fg = p.warning })
  hl("SnacksPickerGitStatusDeleted", { fg = p.error })
  hl("SnacksPickerGitStatusUntracked", { fg = p.accent5 })
  hl("SnacksPickerGitStatusStaged", { fg = p.success })
  hl("SnacksPickerGitStatusUnmerged", { fg = p.error })
  -- Indent guides
  hl("SnacksIndent", { fg = p.bg_highlight })
  hl("SnacksIndentScope", { fg = p.accent3 })
  -- Word highlighting (LSP document highlights)
  hl("SnacksWordsReference", { bg = p.bg_highlight })
  hl("SnacksWordsReferenceRead", { bg = p.bg_highlight })
  hl("SnacksWordsReferenceWrite", { bg = p.bg_highlight, underline = true })
  -- Dashboard
  hl("SnacksDashboardHeader", { fg = p.accent3 })
  hl("SnacksDashboardFooter", { fg = p.fg_muted })
  hl("SnacksDashboardDesc", { fg = p.fg })
  hl("SnacksDashboardIcon", { fg = p.accent3 })
  hl("SnacksDashboardKey", { fg = p.accent5, bold = true })
  hl("SnacksDashboardFile", { fg = p.fg })
  hl("SnacksDashboardDir", { fg = p.fg_muted })
  hl("SnacksDashboardSpecial", { fg = p.accent1 })
  -- Zen mode
  hl("SnacksZen", { bg = p.bg })
  -- Dim mode
  hl("SnacksDim", { fg = p.fg_muted })

  -- ==========================================================================
  -- Plugin: nvim-dap-virtual-text
  -- ==========================================================================
  hl("NvimDapVirtualText", { fg = p.fg_dim, italic = true })
  hl("NvimDapVirtualTextChanged", { fg = p.warning, italic = true })
  hl("NvimDapVirtualTextError", { fg = p.error, italic = true })
  hl("NvimDapVirtualTextInfo", { fg = p.info, italic = true })

  -- ==========================================================================
  -- Plugin: gitsigns (additional groups)
  -- ==========================================================================
  hl("GitSignsAddPreview", { fg = p.success })
  hl("GitSignsDeletePreview", { fg = p.error })
  hl("GitSignsTopdelete", { fg = p.error })
  hl("GitSignsUntracked", { fg = p.fg_muted })
  hl("GitSignsChangedelete", { fg = p.warning })

  -- ==========================================================================
  -- Plugin: nvim-surround
  -- ==========================================================================
  hl("NvimSurroundHighlight", { fg = p.bg, bg = p.accent5 })

  -- ==========================================================================
  -- Plugin: grug-far.nvim
  -- ==========================================================================
  hl("GrugFarHelpHeader", { fg = p.fg, bold = true })
  hl("GrugFarInputLabel", { fg = p.accent3, bold = true })
  hl("GrugFarInputPlaceholder", { fg = p.fg_muted })
  hl("GrugFarResultsHeader", { fg = p.fg_dim })
  hl("GrugFarResultsStats", { fg = p.fg_dim })
  hl("GrugFarResultsMatch", { fg = p.bg, bg = p.error })
  hl("GrugFarResultsMatchAdded", { fg = p.bg, bg = p.success })
  hl("GrugFarResultsMatchRemoved", { fg = p.bg, bg = p.error })
  hl("GrugFarResultsPath", { fg = p.accent3, underline = true })
  hl("GrugFarResultsLineNr", { fg = p.fg_muted })
  hl("GrugFarResultsActionMessage", { fg = p.accent1 })

  -- ==========================================================================
  -- Plugin: neotest
  -- ==========================================================================
  hl("NeotestPassed", { fg = p.success })
  hl("NeotestFailed", { fg = p.error })
  hl("NeotestRunning", { fg = p.warning })
  hl("NeotestSkipped", { fg = p.fg_muted })
  hl("NeotestNamespace", { fg = p.accent2 })
  hl("NeotestFile", { fg = p.accent3 })
  hl("NeotestDir", { fg = p.accent3 })
  hl("NeotestIndent", { fg = p.fg_muted })
  hl("NeotestExpandMarker", { fg = p.fg_muted })
  hl("NeotestAdapterName", { fg = p.accent5, bold = true })
  hl("NeotestWinSelect", { fg = p.accent3, bold = true })
  hl("NeotestMarked", { fg = p.accent5, bold = true })
  hl("NeotestTarget", { fg = p.error })
  hl("NeotestTest", { fg = p.fg })
  hl("NeotestUnknown", { fg = p.fg_muted })
  hl("NeotestWatching", { fg = p.warning })
  hl("NeotestFocused", { bold = true, underline = true })

  -- ==========================================================================
  -- Misc / Built-in
  -- ==========================================================================
  hl("healthSuccess", { fg = p.success })
  hl("healthWarning", { fg = p.warning })
  hl("healthError", { fg = p.error })

  hl("qfFileName", { fg = p.accent3 })
  hl("qfLineNr", { fg = p.fg_dim })

  hl("helpCommand", { fg = p.accent1, bg = p.bg_dark })
  hl("helpExample", { fg = p.fg_dim })
  hl("helpHeader", { fg = p.fg, bold = true })
  hl("helpSectionDelim", { fg = p.fg_muted })

  hl("WildMenu", { fg = p.bg, bg = p.accent3 })
  hl("WinBar", { fg = p.fg, bg = p.bg })
  hl("WinBarNC", { fg = p.fg_dim, bg = p.bg })

  hl("debugPC", { bg = p.bg_highlight })
  hl("debugBreakpoint", { fg = p.error })

  hl("TermCursor", { fg = p.bg, bg = p.fg })
  hl("TermCursorNC", { fg = p.bg, bg = p.fg_dim })

  hl("SpellBad", { sp = p.error, undercurl = true })
  hl("SpellCap", { sp = p.warning, undercurl = true })
  hl("SpellLocal", { sp = p.info, undercurl = true })
  hl("SpellRare", { sp = p.accent5, undercurl = true })

  -- Neovim 0.10+ WinBar
  hl("WinBarModified", { fg = p.warning })
  hl("WinBarFileName", { fg = p.fg })
  hl("WinBarPath", { fg = p.fg_dim })
  hl("WinBarFileIcon", { fg = p.accent3 })
end
