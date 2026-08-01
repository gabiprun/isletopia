#!/bin/bash
# Verify the EXPORTED web build, not just the project.
#
# The editor's GDScript parser is more permissive than the exported build's.
# A script that loads fine in `godot --headless -- --smoke` (which runs against
# the project directory) can still fail to parse inside the .pck — and when
# main.gd fails to load, the page renders nothing but the clear colour.
#
# Always run this before deploying:  bash tools/verify_web_build.sh
set -euo pipefail

cd "$(dirname "$0")/.."
PCK="build/web/index.pck"
[ -f "$PCK" ] || { echo "No $PCK — run the Web export first."; exit 1; }

LOG=$(mktemp)
godot --headless --main-pack "$PCK" -- --smoke > "$LOG" 2>&1 || true

if grep -qE "Parse Error|Failed to load script|SCRIPT ERROR" "$LOG"; then
  echo "FAIL: the exported pack has script errors — do NOT deploy."
  grep -E "Parse Error|Failed to load script|SCRIPT ERROR" "$LOG" | head -5
  rm -f "$LOG"; exit 1
fi
if ! grep -q "^SMOKE OK" "$LOG"; then
  echo "FAIL: smoke suite did not pass inside the exported pack."
  grep -E "SMOKE" "$LOG" | tail -5
  rm -f "$LOG"; exit 1
fi

grep -E "^SMOKE" "$LOG"
rm -f "$LOG"
echo "OK: exported pack loads clean and passes the full suite. Safe to deploy."
