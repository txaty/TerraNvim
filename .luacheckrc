-- Luacheck configuration for Neovim configuration
-- Recognizes Neovim's global APIs and environment

-- Standard Lua (Neovim uses Lua 5.1 semantics)
std = "lua51"

-- Neovim globals (both readable and writable)
globals = {
  "vim",  -- Neovim API (can read and write: vim.g.var = value, etc.)
  "Snacks",  -- snacks.nvim global (set by plugin at runtime)
}

-- Code style
max_line_length = 120
indent_type = "space"
indent_size = 2

-- Ignore unused 'self' parameter in methods
unused_args = true
allow_defined_top = true

-- Paths to check
include_files = {
  "lua/**/*.lua",
  "scripts/**/*.lua",
  ".stylua.toml",
}

exclude_files = {
  "lua/plugins/init.lua",  -- Often has many requires
}
