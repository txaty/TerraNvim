local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

local spec = {
  { import = "plugins" },
  -- lazy.nvim's `import` is NOT recursive: it picks up `lua/plugins/*.lua` and
  -- `lua/plugins/*/init.lua` only. Without this second entry the whole
  -- `lua/plugins/languages/` tree (rustaceanvim, venv-selector, flutter-tools,
  -- nvim-ts-autotag, and every mason/treesitter/conform/lspconfig extension)
  -- is silently dropped — no error, just no language tooling. Any new
  -- subdirectory under lua/plugins/ needs its own import entry here.
  { import = "plugins.languages" },
}

-- Personal plugin specs (gitignored). Only imported when the directory has a
-- spec file: lazy reports an error for an import that yields no specs.
for name in vim.fs.dir(vim.fn.stdpath "config" .. "/lua/user/plugins") do
  if name:match "%.lua$" then
    spec[#spec + 1] = { import = "user.plugins" }
    break
  end
end

require("lazy").setup {
  spec = spec,
  defaults = { lazy = true },
  -- scripts/smoke.lua sets vim.g.nvim_smoke: tests must never clone plugins or
  -- rewrite lazy-lock.json, so missing plugins are reported instead of installed.
  install = { missing = not vim.g.nvim_smoke },
  checker = { enabled = false }, -- disable auto-check for better performance (use :Lazy check)
  performance = {
    rtp = {
      -- disable some rtp plugins for faster startup
      disabled_plugins = {
        "gzip",
        "matchit",
        -- "matchparen", -- keep for bracket matching
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "rplugin", -- remote plugins (not used)
        "spellfile", -- spell file download (rarely used)
      },
    },
  },
}
