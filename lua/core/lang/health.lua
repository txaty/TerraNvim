-- :checkhealth core.lang
local M = {}

function M.check()
  local health = vim.health
  local lang = require "core.lang"
  local install = require "core.lang.install"
  local lsp_status = require("core.lang.lsp").status()

  health.start "Language packs"
  for name, err in pairs(lang.load_errors()) do
    health.error(("pack %s failed to load: %s"):format(name, err))
  end
  local packs = {}
  for _, name in ipairs(lang.names()) do
    packs[name] = lang.get(name)
  end
  local schema = require "core.lang.schema"
  local problems = schema.validate(packs, schema.shared_repos())
  if #problems == 0 then
    health.ok(("%d packs, schema valid"):format(#lang.names()))
  end
  for _, problem in ipairs(problems) do
    health.error(problem)
  end
  if require("core.lang.state").overridden() then
    health.info("$NVIM_LANGS overrides the enabled set: " .. vim.env.NVIM_LANGS)
  end
  local disabled = vim.tbl_filter(function(name)
    return not lang.is_enabled(name)
  end, lang.names())
  health.info("Disabled: " .. (#disabled > 0 and table.concat(disabled, ", ") or "none"))

  health.start "Prerequisites"
  for _, bin in ipairs { "git", "rg", "fd", "tree-sitter", "cc" } do
    if vim.fn.executable(bin) == 1 then
      health.ok(bin .. " found")
    elseif bin == "tree-sitter" or bin == "cc" then
      health.warn(bin .. " not found: treesitter parsers cannot be built")
    else
      health.warn(bin .. " not found")
    end
  end
  health.info("Automatic installs: " .. (require("core.settings").get "install.auto" and "on" or "off"))
  local trust = require "core.trust"
  local root = trust.project_root(0)
  if trust.is_trusted(root) then
    health.info(("Project %s is trusted: tools that run project code are allowed"):format(root))
  else
    health.info(
      ("Project %s is not trusted: tools that run project code are skipped "):format(root)
        .. "(eslint, tailwindcss, Hardhat/solidity, prettier, luacheck, markdownlint-cli2, solhint, "
        .. "workspace TypeScript); "
        .. ":TrustProject allows them"
    )
  end

  for _, name in ipairs(lang.enabled()) do
    local pack = lang.get(name)
    health.start(("%s (%s)"):format(pack.title or name, name))

    for server, entry in pairs(lang.collect.servers { name }) do
      local state = lsp_status[server]
      local where = entry.spec.mason and ("mason: " .. entry.spec.mason) or "system"
      if entry.spec.managed_by then
        health.ok(("%s: managed by %s"):format(server, entry.spec.managed_by))
      elseif state == "enabled" then
        health.ok(("%s: enabled (%s)"):format(server, where))
      elseif state == "pending" then
        health.warn(("%s: waiting for %s to install"):format(server, entry.spec.mason))
      elseif state == "missing" then
        health.warn(("%s: not executable (%s)"):format(server, where))
      elseif state == "disabled" then
        health.info(server .. ": configured, lsp.auto_start is off (:lsp enable " .. server .. ")")
      else
        health.info(server .. ": not configured yet (nvim-lspconfig loads with the first file)")
      end
    end

    local missing_tools = install.missing_tools { name }
    if #missing_tools > 0 then
      health.warn("Mason packages not installed: " .. table.concat(missing_tools, ", "), ":LangInstall " .. name)
    else
      health.ok "Mason packages installed"
    end

    local missing_parsers = install.missing_parsers { name }
    if #missing_parsers > 0 then
      health.warn("Parsers not installed: " .. table.concat(missing_parsers, ", "), ":LangInstall " .. name)
    elseif pack.parsers then
      health.ok "Parsers installed"
    end
  end
end

return M
