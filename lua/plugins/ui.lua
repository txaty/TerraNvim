-- UI components: statusline, bufferline, tab-scoped buffers, search lens.
-- The file explorer is snacks.explorer (lua/plugins/snacks.lua).
return {
  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
        disabled_filetypes = { statusline = { "dashboard", "alpha", "starter", "snacks_dashboard" } },
      },
      sections = {
        lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = {
          { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
          { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" } },
        },
        lualine_x = {
          {
            -- LSP client names - cached per statusline refresh to avoid duplicate API calls
            function()
              local clients = vim.lsp.get_clients { bufnr = 0 }
              if #clients == 0 then
                return ""
              end
              local names = {}
              for _, client in ipairs(clients) do
                names[#names + 1] = client.name
              end
              return " " .. table.concat(names, ", ")
            end,
            -- Condition uses the same logic inline to avoid separate API call
            -- The component returns empty string when no clients, which hides it
          },
        },
        lualine_y = { "filetype" },
        lualine_z = { { "location", separator = { right = "" }, left_padding = 2 } },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
    },
  },

  -- Bufferline (Tabs)
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    version = "*",
    opts = {
      options = {
        mode = "buffers",
        separator_style = "thin",
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        show_buffer_close_buttons = true,
        show_close_icon = true,
        max_name_length = 20,
        truncate_names = true,
        close_command = function(bufnr)
          Snacks.bufdelete { buf = bufnr }
        end,
        right_mouse_command = function(bufnr)
          Snacks.bufdelete { buf = bufnr }
        end,
        offsets = {
          {
            filetype = "snacks_layout_box", -- snacks.explorer sidebar
            text = "",
            highlight = "Directory",
            separator = true,
          },
        },
        -- Filter out directory buffers (e.g. "nvim/" when opening nvim in a directory)
        custom_filter = function(buf_number)
          local buf_name = vim.api.nvim_buf_get_name(buf_number)
          if buf_name ~= "" and vim.fn.isdirectory(buf_name) == 1 then
            return false
          end
          return true
        end,
        diagnostics_indicator = function(count, level)
          local icon = level:match "error" and " " or " "
          return icon .. count
        end,
        custom_areas = {
          right = function()
            -- Use native tabline click syntax: %@func@text%X
            _G.___bufferline_close_all = function()
              Snacks.bufdelete.all()
            end
            return {
              { text = "%@v:lua.___bufferline_close_all@ 󰅖 %X", link = "BufferLineTab" },
            }
          end,
        },
      },
    },
    keys = {
      {
        "<leader>bd",
        function()
          Snacks.bufdelete()
        end,
        desc = "Delete buffer",
      },
      {
        "<leader>bD",
        function()
          Snacks.bufdelete { wipe = true }
        end,
        desc = "Wipeout buffer",
      },
      {
        "<leader>bo",
        function()
          Snacks.bufdelete.other()
        end,
        desc = "Close other buffers",
      },
      {
        "<leader>bx",
        function()
          Snacks.bufdelete.all()
        end,
        desc = "Close all buffers",
      },
    },
  },

  -- Icons
  { "nvim-tree/nvim-web-devicons", lazy = true },
  { "MunifTanjim/nui.nvim", lazy = true },

  -- Word illumination: replaced by snacks.words (lua/plugins/snacks.lua)
  -- Indent guides: replaced by snacks.indent (lua/plugins/snacks.lua)

  -- Tab-scoped buffers: each tab only shows its own buffers in bufferline
  {
    "tiagovla/scope.nvim",
    event = "VeryLazy",
    config = function()
      require("scope").setup()
      -- Hook into persistence.nvim for session save/restore
      local group = vim.api.nvim_create_augroup("ScopeSession", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceSavePre",
        group = group,
        callback = function()
          pcall(vim.cmd, "ScopeSaveState")
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceLoadPost",
        group = group,
        callback = function()
          pcall(vim.cmd, "ScopeLoadState")
        end,
      })
    end,
  },

  -- Search result visualization: shows "N/M" match count and highlights current match
  {
    "kevinhwang91/nvim-hlslens",
    keys = {
      {
        "n",
        [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
        desc = "Next search result",
      },
      {
        "N",
        [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
        desc = "Previous search result",
      },
      { "*", [[*<Cmd>lua require('hlslens').start()<CR>]], desc = "Search word forward" },
      { "#", [[#<Cmd>lua require('hlslens').start()<CR>]], desc = "Search word backward" },
    },
    opts = {
      calm_down = true, -- Clear lens when cursor moves
      nearest_only = true, -- Only show lens for nearest match
    },
  },
}
