-- Shell scripts (sh/bash). bashls runs shellcheck itself when it is installed.
return {
  title = "Bash",
  description = "bashls (+shellcheck), shfmt",
  filetypes = { "sh", "bash" },
  grep_type = "sh",
  parsers = { "bash" },
  servers = {
    bashls = { mason = "bash-language-server" },
  },
  tools = { "shellcheck", "shfmt" },
  formatters_by_ft = { sh = { "shfmt" }, bash = { "shfmt" } },
}
