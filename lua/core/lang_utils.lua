-- Language utilities for reducing boilerplate in language-specific plugin files
-- This module provides helpers for extending shared tooling plugins:
-- treesitter, mason, conform, and lspconfig

local M = {}

-- Extend treesitter parsers
-- @param parsers table: List of parser names to install
-- @return table: Plugin spec for nvim-treesitter
function M.extend_treesitter(parsers)
  return {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = opts.ensure_installed or {}
        vim.list_extend(opts.ensure_installed, parsers)
      end
    end,
  }
end

-- Extend mason tools
-- @param tools table: List of tool names to install via Mason
-- @return table: Plugin spec for mason.nvim
function M.extend_mason(tools)
  return {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, tools)
    end,
  }
end

-- Extend conform formatters
-- @param formatters_map table: Map of filetype to formatter list
-- @return table: Plugin spec for conform.nvim
function M.extend_conform(formatters_map)
  return {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for ft, formatters in pairs(formatters_map) do
        opts.formatters_by_ft[ft] = formatters
      end
    end,
  }
end

-- Extend mason-lspconfig ensure_installed
-- @param servers table: List of LSP server names for mason-lspconfig to install
-- @return table: Plugin spec for mason-lspconfig.nvim
function M.extend_mason_lspconfig(servers)
  return {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, servers)
    end,
  }
end

-- Configure LSP servers
-- @param servers_map table: Map of server name to server config
-- @return table: Plugin spec for nvim-lspconfig
function M.extend_lspconfig(servers_map)
  return {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      for server, config in pairs(servers_map) do
        opts.servers[server] = config
      end
    end,
  }
end

return M
