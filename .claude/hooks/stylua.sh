#!/bin/sh
# PostToolUse hook: format a Lua file right after an agent edits it, so diffs
# never contain formatting noise and `make lint` stays green.
file=$(jq -r '.tool_input.file_path // empty')
case "$file" in
  *.lua)
    [ -f "$file" ] && command -v stylua >/dev/null 2>&1 &&
      stylua --config-path "$CLAUDE_PROJECT_DIR/.stylua.toml" "$file"
    ;;
esac
exit 0
