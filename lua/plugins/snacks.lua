-- Snacks.nvim: Unified UI/UX plugin collection from folke
-- Replaces: nvim-notify, indent-blankline, vim-illuminate, zen-mode, twilight, telescope (picker)

-- Session-persistent grep filters (shared between Snacks picker and Telescope)
local grep_filters = {
  include = nil, -- glob pattern: "*.py", "src/**/*.ts"
  exclude = nil, -- glob pattern: "node_modules", "*.test.js"
  type = nil, -- ripgrep type: "py", "js", "go", "rust", etc.
}

-- File type presets for quick selection
local file_types = {
  { label = "All files", type = nil },
  { label = "Python (.py)", type = "py" },
  { label = "JavaScript (.js)", type = "js" },
  { label = "TypeScript (.ts)", type = "ts" },
  { label = "Rust (.rs)", type = "rust" },
  { label = "Go (.go)", type = "go" },
  { label = "Lua (.lua)", type = "lua" },
  { label = "C/C++ (.c/.cpp/.h)", type = "cpp" },
  { label = "Markdown (.md)", type = "md" },
  { label = "JSON (.json)", type = "json" },
  { label = "YAML (.yaml/.yml)", type = "yaml" },
  { label = "HTML (.html)", type = "html" },
  { label = "CSS (.css)", type = "css" },
}

-- Build ripgrep args from filter state
local function build_snacks_grep_args()
  local args = { "--hidden" }
  if grep_filters.include then
    vim.list_extend(args, { "--glob", grep_filters.include })
  end
  if grep_filters.exclude then
    vim.list_extend(args, { "--glob", "!" .. grep_filters.exclude })
  end
  if grep_filters.type then
    vim.list_extend(args, { "--type", grep_filters.type })
  end
  return args
end

-- Reset all filters
local function reset_filters()
  grep_filters.include = nil
  grep_filters.exclude = nil
  grep_filters.type = nil
end

-- Get title showing active filters
local function get_grep_title()
  local parts = {}
  if grep_filters.include then
    table.insert(parts, "+" .. grep_filters.include)
  end
  if grep_filters.exclude then
    table.insert(parts, "-" .. grep_filters.exclude)
  end
  if grep_filters.type then
    table.insert(parts, "type:" .. grep_filters.type)
  end
  if #parts == 0 then
    return "Grep"
  end
  return "Grep [" .. table.concat(parts, " ") .. "]"
end

-- Launch Snacks grep with current filters
local function filtered_snacks_grep()
  Snacks.picker.grep {
    title = get_grep_title(),
    args = build_snacks_grep_args(),
  }
end

-- Prompt for include/exclude patterns then search
local function snacks_grep_with_prompts()
  vim.ui.input({ prompt = "Include (glob, e.g. *.lua, src/**/*): " }, function(inc)
    grep_filters.include = (inc and inc ~= "") and inc or nil
    vim.ui.input({ prompt = "Exclude (glob, e.g. node_modules, *.test.js): " }, function(exc)
      grep_filters.exclude = (exc and exc ~= "") and exc or nil
      filtered_snacks_grep()
    end)
  end)
end

-- Select file type from presets then search
local function snacks_grep_by_type()
  vim.ui.select(file_types, {
    prompt = "File type:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      grep_filters.type = choice.type
      filtered_snacks_grep()
    end
  end)
end

-- Grep for word under cursor
local function snacks_grep_word()
  Snacks.picker.grep_word {
    args = build_snacks_grep_args(),
  }
end

return {
  {
    "folke/snacks.nvim",
    version = "*",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      -- NEW FEATURES
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            {
              icon = " ",
              key = "f",
              desc = "Find File",
              action = function()
                Snacks.picker.files()
              end,
            },
            {
              icon = " ",
              key = "g",
              desc = "Find Text",
              action = function()
                Snacks.picker.grep()
              end,
            },
            {
              icon = " ",
              key = "r",
              desc = "Recent Files",
              action = function()
                Snacks.picker.recent()
              end,
            },
            {
              icon = " ",
              key = "s",
              desc = "Restore Session",
              action = function()
                require("persistence").load()
              end,
            },
            { icon = " ", key = "c", desc = "Config", action = ":e $MYVIMRC" },
            { icon = " ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = "󰿅 ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
      -- Snacks picker (replaces Telescope for better performance)
      picker = {
        enabled = true,
        layout = {
          preset = "telescope", -- Familiar Telescope-like layout
        },
        sources = {
          files = { hidden = true, follow = true },
          grep = { hidden = true },
        },
        win = {
          input = {
            keys = {
              ["<C-j>"] = { "list_down", mode = { "i", "n" } },
              ["<C-k>"] = { "list_up", mode = { "i", "n" } },
              ["<C-q>"] = { "qflist", mode = { "i", "n" } },
              ["<Esc>"] = { "close", mode = { "i", "n" } },
            },
          },
        },
      },
      scroll = {
        enabled = true,
        animate = {
          duration = { step = 15, total = 150 },
          easing = "linear",
        },
      },
      gitbrowse = { enabled = true },

      -- REPLACEMENTS (with performance tuning)
      -- notifier disabled: noice.nvim handles notifications more comprehensively
      -- Avoids potential double-processing of messages
      notifier = { enabled = false },
      indent = {
        enabled = true,
        animate = { enabled = false }, -- Disable animations for performance
        char = "│",
        filter = function(buf)
          -- Match indent-blankline exclusions
          local exclude_ft = {
            "help",
            "dashboard",
            "neo-tree",
            "NvimTree",
            "Trouble",
            "trouble",
            "lazy",
            "mason",
            "notify",
            "toggleterm",
            "snacks_dashboard",
          }
          return vim.g.snacks_indent ~= false
            and vim.b[buf].snacks_indent ~= false
            and vim.bo[buf].buftype == ""
            and not vim.tbl_contains(exclude_ft, vim.bo[buf].filetype)
        end,
      },
      words = {
        enabled = true,
        debounce = 200, -- Match vim-illuminate delay
        -- Uses native LSP document highlights (efficient for large files)
      },
      dim = { enabled = true },
      zen = {
        enabled = true,
        toggles = {
          dim = false,
          git_signs = false,
          diagnostics = false,
        },
        win = { width = 120 }, -- Match zen-mode.nvim setting
      },
      toggle = { enabled = true },

      -- Startup & performance features
      bufdelete = { enabled = true }, -- Buffer deletion with layout preservation
      quickfile = { enabled = true }, -- Instant file display before plugins load
      bigfile = {
        enabled = true,
        size = 1.5 * 1024 * 1024, -- 1.5MB - auto-disable LSP/Treesitter for large files
      },
      scope = { enabled = true }, -- Scope-aware navigation and text objects

      -- Development tools
      profiler = { enabled = true }, -- Lua profiler for debugging performance
      scratch = { enabled = true }, -- Quick scratch buffers for code experiments

      -- Adaptive image rendering (Snacks auto-detects Kitty/Ghostty/WezTerm)
      image = {
        enabled = true,
        convert = {
          magick = {
            -- HiDPI-aware: downscale only above 4K; add memory resource limits to
            -- prevent OOM when converting large images (imagemagick can use 8-10x file size).
            default = {
              "{src}[0]",
              "-scale",
              "3840x2160>",
              "-limit",
              "memory",
              "512MiB",
              "-limit",
              "map",
              "1GiB",
            },
            pdf = {
              "-density",
              192,
              "{src}[{page}]",
              "-background",
              "white",
              "-alpha",
              "remove",
              "-trim",
              "-limit",
              "memory",
              "512MiB",
              "-limit",
              "map",
              "1GiB",
            },
            vector = {
              "-density",
              192,
              "{src}[{page}]",
              "-limit",
              "memory",
              "512MiB",
              "-limit",
              "map",
              "1GiB",
            },
          },
        },
      },

      -- KEEP DISABLED (using other plugins)
      explorer = { enabled = false }, -- Keep nvim-tree
      terminal = { enabled = false }, -- Keep toggleterm
      lazygit = { enabled = false }, -- Keep lazygit.nvim
      input = { enabled = true },
      statuscolumn = { enabled = false },
    },
    keys = {
      -- Snacks Picker (replaces Telescope)
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find files",
      },
      {
        "<leader>fg",
        filtered_snacks_grep,
        desc = "Live grep",
      },
      {
        "<leader>fG",
        snacks_grep_with_prompts,
        desc = "Live grep (with filters)",
      },
      {
        "<leader>fT",
        snacks_grep_by_type,
        desc = "Live grep (by type)",
      },
      {
        "<leader>fR",
        reset_filters,
        desc = "Reset grep filters",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent files",
      },
      {
        "<leader>fh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help tags",
      },
      {
        "<leader>fw",
        snacks_grep_word,
        desc = "Grep word under cursor",
      },
      {
        "<leader>fc",
        function()
          Snacks.picker.commands()
        end,
        desc = "Commands",
      },
      {
        "<leader>fk",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>f/",
        function()
          Snacks.picker.lines()
        end,
        desc = "Search in buffer",
      },
      {
        "<leader>fs",
        function()
          Snacks.picker.lsp_symbols()
        end,
        desc = "LSP symbols",
      },
      {
        "<leader>fd",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics",
      },
      -- Marks
      {
        "<leader>fm",
        function()
          Snacks.picker.marks()
        end,
        desc = "Marks",
      },
      -- Dashboard (H = Home)
      {
        "<leader>H",
        function()
          Snacks.dashboard()
        end,
        desc = "Dashboard (Home)",
      },
      -- Git browse (o = open in browser)
      {
        "<leader>go",
        function()
          Snacks.gitbrowse()
        end,
        desc = "Git: Open in browser",
        mode = { "n", "v" },
      },
      -- Zen mode
      {
        "<leader>uz",
        function()
          Snacks.zen()
        end,
        desc = "UI: Toggle zen mode",
      },
      -- Words navigation (reference jumping)
      {
        "]]",
        function()
          Snacks.words.jump(vim.v.count1)
        end,
        desc = "Next reference",
      },
      {
        "[[",
        function()
          Snacks.words.jump(-vim.v.count1)
        end,
        desc = "Prev reference",
      },
      -- Notifications handled by noice.nvim (<leader>nh, <leader>nd)

      -- Scope navigation
      {
        "]i",
        function()
          Snacks.scope.jump { bottom = true }
        end,
        desc = "Next scope",
      },
      {
        "[i",
        function()
          Snacks.scope.jump { bottom = false }
        end,
        desc = "Prev scope",
      },

      -- Profiler
      {
        "<leader>up",
        function()
          Snacks.profiler.toggle()
        end,
        desc = "UI: Toggle profiler",
      },

      -- Scratch buffers
      {
        "<leader>.",
        function()
          Snacks.scratch()
        end,
        desc = "Scratch buffer",
      },
      {
        "<leader>fS",
        function()
          Snacks.scratch.select()
        end,
        desc = "Select scratch buffer",
      },
    },
    init = function()
      -- Global kill switch for all snacks animations if issues arise:
      --   vim.g.snacks_animate = false
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          -- Warn once per session if imagemagick is absent; without it
          -- snacks.image can only render PNG inline.
          if vim.fn.executable "magick" == 0 and vim.fn.executable "convert" == 0 then
            vim.notify(
              "snacks.image: imagemagick not found — only PNG files will render inline.",
              vim.log.levels.WARN
            )
          end

          -- Debug helpers (dd(...) inspects, bt() prints a backtrace). vim.print is
          -- left alone: overriding it rerouted `:=`/`:lua =` and plugin output
          -- into notifications and changed its return value.
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end

          -- Runtime toggles for core.settings switches. Session-scoped on
          -- purpose: the persistent default lives in lua/user/settings.lua.
          local settings = require "core.settings"
          Snacks.toggle
            .new({
              id = "format_on_save",
              name = "Format on save",
              get = function()
                return settings.get "format.on_save"
              end,
              set = function(state)
                settings.set("format.on_save", state)
              end,
            })
            :map "<leader>uf"
          Snacks.toggle
            .new({
              id = "format_on_save_buffer",
              name = "Format on save (buffer)",
              get = function()
                return vim.b.autoformat ~= false
              end,
              set = function(state)
                vim.b.autoformat = state
              end,
            })
            :map "<leader>uF"
          Snacks.toggle
            .new({
              id = "lint",
              name = "Lint",
              get = function()
                return settings.get "lint.enabled"
              end,
              set = function(state)
                settings.set("lint.enabled", state)
                if not state and package.loaded.lint then
                  -- Nothing re-runs the linters while disabled, so drop
                  -- their diagnostics instead of leaving stale ones.
                  local lint = require "lint"
                  for _, names in pairs(lint.linters_by_ft) do
                    for _, name in ipairs(type(names) == "table" and names or {}) do
                      vim.diagnostic.reset(lint.get_namespace(name))
                    end
                  end
                end
              end,
            })
            :map "<leader>ul"
          Snacks.toggle.inlay_hints():map "<leader>uh"
        end,
      })
    end,
  },
}
