-- Lua (and Neovim config/plugin development).
return {
  title = "Lua",
  description = "lua_ls, stylua, luacheck (with .luacheckrc), lazydev for Neovim APIs",
  filetypes = { "lua" },
  grep_type = "lua",
  parsers = { "lua", "luadoc", "luap" },
  servers = {
    lua_ls = {
      mason = "lua-language-server",
      settings = {
        Lua = {
          workspace = { checkThirdParty = false },
          completion = { callSnippet = "Replace" },
          hint = { enable = true },
        },
      },
    },
  },
  tools = { "stylua", "luacheck" },
  formatters_by_ft = { lua = { "stylua" } },
  linters_by_ft = { lua = { "luacheck" } },
  linters = {
    -- luacheck without a project config reports every global as undefined.
    luacheck = {
      condition = function(ctx)
        return vim.fs.root(ctx.dirname, { ".luacheckrc" }) ~= nil
      end,
    },
  },
  cmp = {
    providers = {
      lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
    },
    per_filetype = { lua = { inherit_defaults = true, "lazydev" } },
  },
  plugins = {
    {
      "folke/lazydev.nvim",
      ft = "lua",
      opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } },
    },
  },
}
