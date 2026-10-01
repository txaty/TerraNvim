-- TOML (Cargo.toml, pyproject.toml, ...). taplo formats and validates.
return {
  title = "TOML",
  description = "taplo",
  filetypes = { "toml" },
  grep_type = "toml",
  parsers = { "toml" },
  servers = {
    taplo = { mason = "taplo" },
  },
}
