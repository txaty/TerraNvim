-- Solidity: Nomic Foundation's language server (Hardhat & Foundry projects),
-- forge fmt in Foundry projects, solhint when the project configures it.
return {
  title = "Solidity",
  description = "nomicfoundation solidity-language-server, forge fmt, solhint",
  filetypes = { "solidity" },
  grep_type = "solidity",
  parsers = { "solidity" },
  servers = {
    solidity_ls_nomicfoundation = { mason = "nomicfoundation-solidity-language-server" },
  },
  tools = { "solhint" },
  formatters_by_ft = {
    -- Foundry projects use `forge fmt` (foundry.toml); elsewhere the language
    -- server formats (prettier-plugin-solidity) through the LSP fallback.
    solidity = function(buf)
      return vim.fs.root(buf, { "foundry.toml" }) and { "forge_fmt" } or {}
    end,
  },
  linters_by_ft = { solidity = { "solhint" } },
  linters = {
    -- Only where configured, and only in trusted projects: solhint loads
    -- plugins named in its config.
    solhint = {
      condition = function(ctx)
        return vim.fs.root(ctx.dirname, { ".solhint.json", ".solhintrc", ".solhintrc.json" }) ~= nil
          and require("core.trust").allows("solhint", ctx.buf)
      end,
    },
  },
}
