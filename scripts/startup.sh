#!/bin/sh
# Startup-time budget: median of N headless starts of THIS checkout.
#
#   scripts/startup.sh [runs] [warn_ms] [fail_ms]
set -u

runs=${1:-5}
warn_ms=${2:-30}
fail_ms=${3:-35}

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/nvim-startup.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$tmp/config" "$tmp/state"
ln -s "$repo" "$tmp/config/nvim"

# Hermetic: the default language packs (not this machine's choices) and smoke
# mode, so a missing plugin is never cloned and lazy-lock.json never rewritten.
export XDG_CONFIG_HOME="$tmp/config" XDG_STATE_HOME="$tmp/state" NVIM_LANGS=default
smoke='let g:nvim_smoke = 1'

# One warm-up run so the bytecode cache is populated for this checkout.
nvim --headless -i NONE --cmd "$smoke" +qa >/dev/null 2>&1

# Median of $runs headless starts; extra args are passed to nvim (a file).
measure() {
  i=0
  while [ "$i" -lt "$runs" ]; do
    nvim --headless -i NONE --cmd "$smoke" --startuptime "$tmp/st.log" "$@" +qa >/dev/null 2>&1
    awk '/NVIM STARTED/ {print $1}' "$tmp/st.log"
    rm -f "$tmp/st.log"
    i=$((i + 1))
  done | sort -n | awk '{ t[NR] = $1 } END { if (NR > 0) print t[int((NR + 1) / 2)] }'
}

# Shared CI runners are noisy: report there, but only fail locally.
[ -n "${CI:-}" ] && fail_ms=100000

median=$(measure)
file_median=$(measure "$repo/lua/core/settings.lua")
awk -v m="$median" -v f="$file_median" -v n="$runs" -v warn="$warn_ms" -v fail="$fail_ms" 'BEGIN {
  if (m == "") { print "FAIL: no successful runs"; exit 2 }
  printf "startup median: %.1f ms over %d runs (opening a Lua file: %.1f ms, informational)\n", m, n, f
  if (m + 0 > fail) { printf "FAIL: above %d ms\n", fail; exit 1 }
  if (m + 0 > warn) printf "warn: above %d ms\n", warn
}'
