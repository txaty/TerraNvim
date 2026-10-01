-- Swift / iOS / macOS. sourcekit-lsp comes with Xcode or the Swift toolchain
-- (not Mason). For .xcodeproj/.xcworkspace projects run xcode-build-server
-- once (`xcode-build-server config -scheme <S> -project <P>`) so sourcekit-lsp
-- sees the build settings; xcodebuild.nvim does this for you via :XcodebuildSetup.
return {
  title = "Swift",
  description = "sourcekit-lsp (Xcode), swiftformat|swift format, swiftlint, lldb-dap, xcodebuild.nvim",
  filetypes = { "swift", "objc", "objcpp" },
  grep_type = "swift",
  parsers = { "swift" },
  servers = function()
    local xcrun = vim.fn.executable "xcrun" == 1
    return {
      sourcekit = {
        mason = false,
        enabled = xcrun or vim.fn.executable "sourcekit-lsp" == 1,
        cmd = xcrun and { "xcrun", "sourcekit-lsp" } or { "sourcekit-lsp" },
        -- lspconfig's sourcekit also claims c/cpp, where it would fight clangd.
        filetypes = { "swift", "objc", "objcpp" },
      },
    }
  end,
  tools = { "swiftlint", "swiftformat", "xcode-build-server", "xcbeautify" },
  formatters_by_ft = {
    -- nicklockwood/SwiftFormat when the project configures it, otherwise
    -- Apple's swift-format bundled with Swift 6 (`swift format`).
    swift = function(buf)
      return vim.fs.root(buf, { ".swiftformat" }) and { "swiftformat" } or { "swift" }
    end,
  },
  linters_by_ft = { swift = { "swiftlint" } },
  dap = function(dap)
    dap.adapters["lldb-dap"] = vim.fn.executable "xcrun" == 1
        and { type = "executable", command = "xcrun", args = { "lldb-dap" }, name = "lldb-dap" }
      or { type = "executable", command = "lldb-dap", name = "lldb-dap" }
    dap.configurations.swift = {
      {
        name = "Launch (SwiftPM executable)",
        type = "lldb-dap",
        request = "launch",
        program = function()
          return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/.build/debug/", "file")
        end,
        cwd = "${workspaceFolder}",
      },
      {
        name = "Attach to process",
        type = "lldb-dap",
        request = "attach",
        pid = function()
          return require("dap.utils").pick_process()
        end,
      },
    }
  end,
  plugins = {
    {
      "wojciech-kulik/xcodebuild.nvim",
      cond = function()
        return vim.fn.has "mac" == 1
      end,
      ft = { "swift", "objc", "objcpp" },
      cmd = { "XcodebuildSetup", "XcodebuildPicker", "XcodebuildProjectManager" },
      dependencies = { "folke/snacks.nvim", "MunifTanjim/nui.nvim" },
      opts = {},
    },
  },
  keys = {
    { "<leader>X", group = "Xcode", icon = "" },
    { "<leader>XX", "<cmd>XcodebuildPicker<cr>", desc = "Xcode: Actions" },
    { "<leader>Xb", "<cmd>XcodebuildBuild<cr>", desc = "Xcode: Build" },
    { "<leader>Xr", "<cmd>XcodebuildBuildRun<cr>", desc = "Xcode: Build & run" },
    { "<leader>Xt", "<cmd>XcodebuildTest<cr>", desc = "Xcode: Test" },
    { "<leader>XT", "<cmd>XcodebuildTestExplorerToggle<cr>", desc = "Xcode: Test explorer" },
    { "<leader>Xd", "<cmd>XcodebuildSelectDevice<cr>", desc = "Xcode: Select device" },
    { "<leader>Xl", "<cmd>XcodebuildToggleLogs<cr>", desc = "Xcode: Toggle logs" },
    { "<leader>Xp", "<cmd>XcodebuildPreviewToggle<cr>", desc = "Xcode: Toggle preview" },
  },
}
