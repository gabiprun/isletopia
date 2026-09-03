#!/bin/bash
# Fail if Finder/browser "(2)" duplicate files have crept into the tree.
#
# Re-exporting the web build by downloading a zip that macOS renames to
# "index (2).zip" and unpacking it into docs/ leaves a parallel set of
# "index 2.html" / "index 2.pck" / "index 2.wasm" files. They are untracked, so
# GH Pages never serves them — but a careless `git add -A` would ship a second,
# broken build alongside the real one. The same pattern once produced a
# " 2.gd" script duplicate, which breaks Godot's class-name cache outright.
#
# Run standalone:  bash tools/check_no_dupes.sh
# Also runs as the first gate inside tools/verify_web_build.sh.
set -euo pipefail

cd "$(dirname "$0")/.."

HITS=$(find . \( -iname "* 2.*" -o -name "* 2" \) -not -path "./.git/*" | sort)

if [ -n "$HITS" ]; then
  echo "FAIL: duplicate \"(2)\" files found — delete them before building/committing:"
  echo "$HITS" | sed 's/^/  /'
  echo
  echo "These come from unpacking a browser-renamed \"... (2).zip\" into place."
  echo "Export straight into docs/ instead of unzipping a downloaded copy."
  exit 1
fi

echo "OK: no duplicate \"(2)\" files in the tree."
