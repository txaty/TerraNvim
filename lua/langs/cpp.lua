-- C/C++ including embedded targets: clangd, clang-format, CMake, codelldb
-- (local launch/attach and remote GDB servers such as OpenOCD, J-Link, QEMU).
return {
  title = "C/C++",
  description = "clangd, clang-format, neocmakelsp, codelldb (incl. remote GDB server)",
  filetypes = { "c", "cpp", "cuda", "cmake" },
  grep_type = "cpp",
  options = {
    query_driver = {
      default = "",
      desc = "clangd --query-driver globs for cross compilers, e.g. /opt/homebrew/bin/arm-none-eabi-*",
    },
  },
  parsers = { "c", "cpp", "cmake", "make" },
  servers = function(o)
    local cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--header-insertion=iwyu",
      "--completion-style=detailed",
      "--function-arg-placeholders",
      "--fallback-style=llvm",
    }
    -- clangd EXECUTES the compilers matched by --query-driver to learn their
    -- system headers, so it is opt-in and should list explicit toolchain paths.
    if o.query_driver ~= "" then
      cmd[#cmd + 1] = "--query-driver=" .. o.query_driver
    end
    return {
      clangd = { mason = "clangd", cmd = cmd },
      neocmake = { mason = "neocmakelsp" },
    }
  end,
  tools = { "clang-format", "codelldb" },
  formatters_by_ft = { c = { "clang-format" }, cpp = { "clang-format" }, cuda = { "clang-format" } },
  dap = function(dap)
    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = { command = "codelldb", args = { "--port", "${port}" } },
    }
    local function program()
      return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
    end
    dap.configurations.c = {
      { name = "Launch", type = "codelldb", request = "launch", program = program, cwd = "${workspaceFolder}" },
      {
        name = "Attach to process",
        type = "codelldb",
        request = "attach",
        pid = function()
          return require("dap.utils").pick_process()
        end,
      },
      {
        -- Embedded: connect to a running GDB server (OpenOCD :3333, J-Link
        -- :2331, QEMU -s :1234) with the firmware ELF for symbols.
        name = "Remote GDB server (OpenOCD / J-Link / QEMU)",
        type = "codelldb",
        request = "custom",
        targetCreateCommands = function()
          return { "target create " .. vim.fn.input("Firmware ELF: ", vim.fn.getcwd() .. "/", "file") }
        end,
        processCreateCommands = function()
          return { "gdb-remote " .. vim.fn.input("GDB server [host:]port: ", "localhost:3333") }
        end,
      },
    }
    dap.configurations.cpp = dap.configurations.c
  end,
  keys = {
    {
      "<leader>lh",
      "<cmd>LspClangdSwitchSourceHeader<cr>",
      desc = "C/C++: Switch source/header",
      ft = { "c", "cpp", "cuda" },
    },
  },
}
