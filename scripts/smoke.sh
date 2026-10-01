#!/bin/sh
# Headless smoke test for this config.
#
#   scripts/smoke.sh [mode ...]     mode = default | all | none | pack[,pack...]
#
# Each mode starts a real Neovim with this repository as its config and
# NVIM_LANGS=<mode> (see lua/core/lang/state.lua), then scripts/smoke.lua runs
# the checks and exits non-zero on any failure.
#
# Isolation: the config dir is a temp symlink to this checkout (so worktrees
# test themselves, not ~/.config/nvim) and XDG_STATE_HOME is a temp dir (no
# sessions, views, undo or logs leak into the real state dir). XDG_DATA_HOME is
# kept so installed plugins, parsers and Mason tools are reused; smoke mode
# blocks every write to it (lazy installs, auto-install, JSON persistence).
set -u

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/nvim-smoke.XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT TERM
mkdir -p "$tmp/config" "$tmp/state"
ln -s "$repo" "$tmp/config/nvim"

[ $# -eq 0 ] && set -- default
status=0
for mode in "$@"; do
  printf '== smoke: %s ==\n' "$mode"
  XDG_CONFIG_HOME="$tmp/config" XDG_STATE_HOME="$tmp/state" NVIM_LANGS="$mode" \
    nvim --headless -i NONE -n --cmd "luafile $repo/scripts/smoke.lua" || status=1
done
exit $status
