-- Session persistence toggle (auto-restore on start, auto-save on exit).
--
-- Persisted so :SessionToggle survives restarts; core.settings
-- `session.persistence` is only the default for a fresh install. Read by the
-- lifecycle "session restore" step and the VimLeavePre auto-save autocmd.
return require("core.persist_flag").new {
  filename = "session_config.json",
  default = require("core.settings").get "session.persistence",
  label = "Session persistence",
  hint = "Auto-restore applies from the next start.",
  on_set = function(enabled)
    -- Saving on exit follows the toggle right away.
    if package.loaded.persistence then
      local persistence = require "persistence"
      if enabled then
        persistence.start()
      else
        persistence.stop()
      end
    end
  end,
}
