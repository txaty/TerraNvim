-- Theme registry, application and persistence.
--
-- Registry keys are the names users pick (picker, :ThemeSwitch, saved state).
-- For most entries the key is also the :colorscheme name; entries whose
-- colorscheme is shared between variants (everforest, gruvbox-material,
-- onedark, vscode) set `colorscheme` + `background` explicitly.
--
-- Entry fields:
--   variant      "dark" | "light"
--   description  shown in the picker
--   plugin       lazy.nvim plugin name to load first (nil for txaty)
--   colorscheme  :colorscheme name (default: the key)
--   background   'background' to set first (default: variant)
--   global       vim.g variables to set first
--   module/setup call require(module).setup(spec opts + setup) first, for
--                themes that pick their variant through setup()
--   custom       "dark" | "light": the built-in txaty theme
local M = {}

local persist = require "core.persist"

M.registry = {
  -- tokyonight
  ["tokyonight-storm"] = { variant = "dark", plugin = "tokyonight.nvim", description = "Tokyo Night, storm" },
  ["tokyonight-night"] = { variant = "dark", plugin = "tokyonight.nvim", description = "Tokyo Night, night" },
  ["tokyonight-moon"] = { variant = "dark", plugin = "tokyonight.nvim", description = "Tokyo Night, moon" },
  ["tokyonight-day"] = { variant = "light", plugin = "tokyonight.nvim", description = "Tokyo Night, day" },
  -- catppuccin
  ["catppuccin-mocha"] = { variant = "dark", plugin = "catppuccin", description = "Catppuccin, mocha" },
  ["catppuccin-macchiato"] = { variant = "dark", plugin = "catppuccin", description = "Catppuccin, macchiato" },
  ["catppuccin-frappe"] = { variant = "dark", plugin = "catppuccin", description = "Catppuccin, frappé" },
  ["catppuccin-latte"] = { variant = "light", plugin = "catppuccin", description = "Catppuccin, latte" },
  -- kanagawa
  ["kanagawa-wave"] = { variant = "dark", plugin = "kanagawa.nvim", description = "Kanagawa, wave" },
  ["kanagawa-dragon"] = { variant = "dark", plugin = "kanagawa.nvim", description = "Kanagawa, dragon" },
  ["kanagawa-lotus"] = { variant = "light", plugin = "kanagawa.nvim", description = "Kanagawa, lotus" },
  -- everforest
  everforest = { variant = "dark", plugin = "everforest", description = "Everforest, comfortable greens" },
  ["everforest-light"] = {
    variant = "light",
    plugin = "everforest",
    colorscheme = "everforest",
    description = "Everforest, light",
  },
  -- nightfox
  nightfox = { variant = "dark", plugin = "nightfox.nvim", description = "Nightfox" },
  carbonfox = { variant = "dark", plugin = "nightfox.nvim", description = "Carbonfox, IBM Carbon inspired" },
  duskfox = { variant = "dark", plugin = "nightfox.nvim", description = "Duskfox" },
  nordfox = { variant = "dark", plugin = "nightfox.nvim", description = "Nordfox, Nord palette" },
  terafox = { variant = "dark", plugin = "nightfox.nvim", description = "Terafox" },
  dayfox = { variant = "light", plugin = "nightfox.nvim", description = "Dayfox" },
  dawnfox = { variant = "light", plugin = "nightfox.nvim", description = "Dawnfox, Rosé Pine dawn inspired" },
  -- rose-pine
  ["rose-pine-main"] = { variant = "dark", plugin = "rose-pine", description = "Rosé Pine" },
  ["rose-pine-moon"] = { variant = "dark", plugin = "rose-pine", description = "Rosé Pine, moon" },
  ["rose-pine-dawn"] = { variant = "light", plugin = "rose-pine", description = "Rosé Pine, dawn" },
  -- gruvbox-material
  ["gruvbox-material"] = {
    variant = "dark",
    plugin = "gruvbox-material",
    description = "Gruvbox, softer material palette",
  },
  ["gruvbox-material-light"] = {
    variant = "light",
    plugin = "gruvbox-material",
    colorscheme = "gruvbox-material",
    description = "Gruvbox Material, light",
  },
  -- onedark
  onedark = {
    variant = "dark",
    plugin = "onedark.nvim",
    module = "onedark",
    setup = { style = "dark" },
    description = "Atom One Dark",
  },
  onelight = {
    variant = "light",
    plugin = "onedark.nvim",
    module = "onedark",
    setup = { style = "light" },
    colorscheme = "onedark",
    description = "Atom One Light",
  },
  -- cyberdream
  cyberdream = { variant = "dark", plugin = "cyberdream.nvim", description = "Cyberdream, high-contrast futuristic" },
  ["cyberdream-light"] = { variant = "light", plugin = "cyberdream.nvim", description = "Cyberdream, light" },
  -- solarized-osaka
  ["solarized-osaka"] = { variant = "dark", plugin = "solarized-osaka.nvim", description = "Solarized Osaka" },
  ["solarized-osaka-light"] = {
    variant = "light",
    plugin = "solarized-osaka.nvim",
    description = "Solarized Osaka, light",
  },
  -- vscode
  vscode = {
    variant = "dark",
    plugin = "vscode.nvim",
    module = "vscode",
    setup = { style = "dark" },
    description = "VS Code Dark Modern",
  },
  ["vscode-light"] = {
    variant = "light",
    plugin = "vscode.nvim",
    module = "vscode",
    setup = { style = "light" },
    colorscheme = "vscode",
    description = "VS Code Light Modern",
  },
  -- modus (WCAG AAA contrast)
  modus_vivendi = { variant = "dark", plugin = "modus-themes.nvim", description = "Modus Vivendi, WCAG AAA" },
  modus_operandi = { variant = "light", plugin = "modus-themes.nvim", description = "Modus Operandi, WCAG AAA" },
  -- built-in
  txaty = { variant = "dark", custom = "dark", description = "txaty: low-saturation ergonomic dark" },
  ["txaty-light"] = { variant = "light", custom = "light", description = "txaty: low-saturation ergonomic light" },
}

-- Names saved by older versions of this config.
M.aliases = {
  catppuccin = "catppuccin-mocha",
  tokyonight = "tokyonight-storm",
  kanagawa = "kanagawa-dragon",
  ["rose-pine"] = "rose-pine-main",
  modus_vivendi_tinted = "modus_vivendi",
  modus_vivendi_deuteranopia = "modus_vivendi",
  modus_vivendi_tritanopia = "modus_vivendi",
  modus_operandi_tinted = "modus_operandi",
  modus_operandi_deuteranopia = "modus_operandi",
  modus_operandi_tritanopia = "modus_operandi",
}

---@param name? string
---@return string? registry key
function M.canonical(name)
  if name and M.registry[name] then
    return name
  end
  return name and M.aliases[name] or nil
end

---Every theme name: dark ones first, then light, each sorted.
---@return string[]
function M.names()
  local dark, light = {}, {}
  for name, info in pairs(M.registry) do
    table.insert(info.variant == "light" and light or dark, name)
  end
  table.sort(dark)
  table.sort(light)
  return vim.list_extend(dark, light)
end

---@param variant "dark"|"light"
---@return string[]
function M.names_by_variant(variant)
  return vim.tbl_filter(function(name)
    return M.registry[name].variant == variant
  end, M.names())
end

-- ============================================================================
-- Persistence: stdpath("data")/theme_config.json = { theme, last_dark, last_light }
-- ============================================================================
local config_path = vim.fn.stdpath "data" .. "/theme_config.json"

---@return {theme?: string, last_dark?: string, last_light?: string}
local function load_config()
  return persist.load_json(config_path, {})
end

---@return string?
function M.saved()
  return M.canonical(load_config().theme)
end

---@param name string registry key
function M.save(name)
  local config = vim.deepcopy(load_config())
  if config.theme == name and config["last_" .. M.registry[name].variant] == name then
    return
  end
  config.theme = name
  config["last_" .. M.registry[name].variant] = name
  persist.save_json(config_path, config)
end

-- ============================================================================
-- Application
-- ============================================================================
local applying = false
local current ---@type string? registry key of the theme in effect

---True while M.apply() runs, so the ColorScheme autosave can ignore the
---intermediate events (and previews never get saved).
---@return boolean
function M.is_applying()
  return applying
end

---Registry key of the theme in effect. Tracked explicitly because several
---themes set g:colors_name to their base name (kanagawa, rose-pine, modus, ...),
---which loses the variant.
---@return string?
function M.current()
  return current or M.resolve(vim.g.colors_name, vim.o.background)
end

---Record a theme applied outside M.apply() (a hand-typed :colorscheme).
---@param name string registry key
function M.set_current(name)
  current = name
end

---Map a :colorscheme name back to a registry key.
---@param colors_name? string
---@param background? string
---@return string?
function M.resolve(colors_name, background)
  if not colors_name then
    return nil
  end
  for name, info in pairs(M.registry) do
    if (info.colorscheme or name) == colors_name and info.variant == background then
      return name
    end
  end
  return M.canonical(colors_name)
end

---Options from the lazy.nvim spec (lua/plugins/colorscheme.lua), so setup()
---calls made here extend them instead of replacing them.
---@param plugin string
---@return table
local function spec_opts(plugin)
  local ok, Config = pcall(require, "lazy.core.config")
  local spec = ok and Config.plugins[plugin]
  if not spec then
    return {}
  end
  -- lazy.core.plugin.values() is internal to lazy.nvim (also used by LazyVim);
  -- it resolves `opts` tables/functions exactly as lazy does for setup().
  local values_ok, values = pcall(function()
    return require("lazy.core.plugin").values(spec, "opts", false)
  end)
  return values_ok and values or {}
end

---Apply a theme by registry name (or a legacy alias).
---@param name string
---@param opts? {save?: boolean, notify?: boolean}
---@return boolean success
function M.apply(name, opts)
  opts = vim.tbl_extend("keep", opts or {}, { save = true, notify = true })
  local key = M.canonical(name)
  local info = key and M.registry[key]
  if not info then
    vim.notify("Theme '" .. tostring(name) .. "' is not in the registry", vim.log.levels.WARN)
    return false
  end

  applying = true
  local ok, err = pcall(function()
    if info.custom then
      require("core.theme_txaty").apply(info.custom)
      return
    end
    if info.plugin then
      require("lazy").load { plugins = { info.plugin } }
    end
    for var, value in pairs(info.global or {}) do
      vim.g[var] = value
    end
    vim.o.background = info.background or info.variant
    if info.module and info.setup then
      require(info.module).setup(vim.tbl_deep_extend("force", spec_opts(info.plugin), info.setup))
    end
    vim.cmd.colorscheme(info.colorscheme or key)
  end)
  applying = false

  if not ok then
    vim.notify(("Theme %s failed: %s"):format(key, err), vim.log.levels.WARN)
    return false
  end
  current = key
  if package.loaded.lualine then
    pcall(require("lualine").refresh)
  end
  if opts.save then
    M.save(key)
  end
  if opts.notify then
    vim.notify("Theme: " .. key, vim.log.levels.INFO)
  end
  return true
end

---Apply the saved theme, falling back to settings theme.dark.
---@return boolean
function M.restore()
  local saved = M.saved()
  if saved and M.apply(saved, { save = false, notify = false }) then
    return true
  end
  return M.apply(require("core.settings").get "theme.dark", { save = false, notify = false })
end

---Switch to the last-used theme of a variant (or the settings default).
---@param variant "dark"|"light"
---@return boolean
function M.switch_to(variant)
  local target = M.canonical(load_config()["last_" .. variant])
  if not target or M.registry[target].variant ~= variant then
    target = require("core.settings").get("theme." .. variant)
  end
  return M.apply(target)
end

return M
