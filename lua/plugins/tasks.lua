-- overseer.nvim: task runner (VS Code tasks.json equivalent).
-- Built-in templates cover make, npm, cargo, go, just, tasks.json, ...
--
-- Written for overseer v2: OverseerInfo (now :checkhealth overseer),
-- OverseerBuild and the top-level `strategy`/`templates` options were removed,
-- and "restart last task" became a documented recipe instead of a command.
return {
  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerOpen",
      "OverseerClose",
      "OverseerToggle",
      "OverseerRun",
      "OverseerShell",
      "OverseerTaskAction",
      "OverseerRestartLast",
    },
    keys = {
      { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Tasks: Run" },
      { "<leader>os", "<cmd>OverseerShell<cr>", desc = "Tasks: Run shell command" },
      { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Tasks: Toggle panel" },
      { "<leader>ol", "<cmd>OverseerRestartLast<cr>", desc = "Tasks: Restart last" },
      { "<leader>oa", "<cmd>OverseerTaskAction<cr>", desc = "Tasks: Action" },
    },
    opts = {
      task_list = {
        direction = "bottom",
        min_height = 10,
        max_height = 25,
      },
    },
    config = function(_, opts)
      local overseer = require "overseer"
      overseer.setup(opts)

      -- From overseer's doc/recipes.md ("Restart last task").
      vim.api.nvim_create_user_command("OverseerRestartLast", function()
        local tasks = overseer.list_tasks {
          status = { overseer.STATUS.SUCCESS, overseer.STATUS.FAILURE, overseer.STATUS.CANCELED },
          sort = require("overseer.task_list").sort_finished_recently,
        }
        if vim.tbl_isempty(tasks) then
          vim.notify("No finished tasks to restart", vim.log.levels.WARN)
        else
          overseer.run_action(tasks[1], "restart")
        end
      end, { desc = "Restart the most recently finished task" })
    end,
  },
}
