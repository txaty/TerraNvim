-- Kotlin: JetBrains' official kotlin-lsp (fwcd/kotlin-language-server is
-- deprecated upstream). kotlin-lsp needs a JDK 17+ and a Gradle/Maven project.
return {
  title = "Kotlin",
  description = "kotlin-lsp (JetBrains), ktlint|ktfmt",
  filetypes = { "kotlin" },
  grep_type = "kotlin",
  options = {
    formatter = { default = "ktlint", choices = { "ktlint", "ktfmt" }, desc = "Formatter" },
  },
  parsers = { "kotlin" },
  servers = {
    kotlin_lsp = { mason = "kotlin-lsp" },
  },
  tools = function(o)
    return o.formatter == "ktfmt" and { "ktlint", "ktfmt" } or { "ktlint" }
  end,
  formatters_by_ft = function(o)
    return { kotlin = { o.formatter } }
  end,
  linters_by_ft = { kotlin = { "ktlint" } },
}
