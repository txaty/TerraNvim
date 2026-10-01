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

i=0
while [ "$i" -lt "$runs" ]; do
  nvim --headless -i NONE --cmd "$smoke" --startuptime "$tmp/st.log" +qa >/dev/null 2>&1
  awk '/NVIM STARTED/ {print $1}' "$tmp/st.log"
  rm -f "$tmp/st.log"
  i=$((i + 1))
done | sort -n | awk -v warn="$warn_ms" -v fail="$fail_ms" '
  { t[NR] = $1 }
  END {
    if (NR == 0) { print "FAIL: no successful runs"; exit 2 }
    m = t[int((NR + 1) / 2)]
    printf "startup median: %.1f ms over %d runs\n", m, NR
    if (m > fail) { printf "FAIL: above %d ms\n", fail; exit 1 }
    if (m > warn) printf "warn: above %d ms\n", warn
  }'
