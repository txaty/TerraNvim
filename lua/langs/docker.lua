-- Dockerfiles and Compose files.
return {
  title = "Docker",
  description = "dockerls, docker compose language service, hadolint",
  filetypes = { "dockerfile", "yaml.docker-compose" },
  grep_type = "docker",
  -- Neovim detects compose files as plain yaml; the compose server only
  -- attaches to this compound filetype (yamlls still attaches via "yaml").
  filetype_add = {
    filename = {
      ["compose.yaml"] = "yaml.docker-compose",
      ["compose.yml"] = "yaml.docker-compose",
      ["docker-compose.yaml"] = "yaml.docker-compose",
      ["docker-compose.yml"] = "yaml.docker-compose",
    },
  },
  parsers = { "dockerfile", "yaml" },
  servers = {
    dockerls = { mason = "dockerfile-language-server" },
    docker_compose_language_service = { mason = "docker-compose-language-service" },
  },
  tools = { "hadolint" },
  linters_by_ft = { dockerfile = { "hadolint" } },
}
