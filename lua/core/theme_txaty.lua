-- Custom "txaty" theme: Ergonomic, low-fatigue theme for sustained focus
-- Factory pattern with dark and light variants
--
-- Split into three files for maintainability:
--   theme_txaty_colors.lua     — palette definitions (edit colors here)
--   theme_txaty_highlights.lua — highlight group definitions (edit groups here)
--   theme_txaty.lua            — this file: entry point and public API

local M = {}

local palettes = require "core.theme_txaty_colors"
local generate_highlights = require "core.theme_txaty_highlights"

-- Re-export palettes for external access
M.palettes = palettes

-- Export default palette for backward compatibility
M.palette = palettes.dark

-- ============================================================================
-- Theme Application
-- ============================================================================

---Apply a txaty variant. colors/txaty*.lua call this from :colorscheme (which
---has already cleared highlights and fires ColorScheme itself); everything else
---(core.theme) calls it directly, so it clears and fires ColorScheme here.
---@param variant? "dark"|"light"
---@param from_colorscheme? boolean
function M.apply(variant, from_colorscheme)
  variant = variant or "dark"
  local p = palettes[variant]

  if not p then
    vim.notify("txaty: Unknown variant '" .. variant .. "', using dark", vim.log.levels.WARN)
    variant = "dark"
    p = palettes.dark
  end

  if not from_colorscheme then
    vim.cmd "highlight clear"
    if vim.fn.exists "syntax_on" == 1 then
      vim.cmd "syntax reset"
    end
  end

  vim.g.colors_name = variant == "light" and "txaty-light" or "txaty"
  vim.o.background = variant
  vim.o.termguicolors = true

  generate_highlights(p)

  if not from_colorscheme then
    vim.api.nvim_exec_autocmds("ColorScheme", { pattern = vim.g.colors_name, modeline = false })
  end
end

-- ============================================================================
-- Public API
-- ============================================================================

-- Get palette for a specific variant
function M.get_palette(variant)
  return palettes[variant or "dark"]
end

return M
