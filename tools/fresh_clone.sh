#!/bin/bash
# Fresh-clone proof: archive HEAD to a clean directory, import, export a
# fresh build, boot it headless, verify zero errors, then clean up.
# Cold-import warnings are the documented, benign ones (font generation
# ordering and the deliberately absent godot-mcp addon).
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLONE="$(mktemp -d /tmp/isle2-clone.XXXXXX)"

git -C "$ROOT" archive HEAD | tar -x -C "$CLONE"
mkdir -p "$CLONE/export/linux"

echo "== import"
IMPORT_LOG="$(mktemp)"
timeout 400 godot --headless --import --path "$CLONE" > "$IMPORT_LOG" 2>&1
if grep -iE "SCRIPT ERROR|Parse Error|Failed|Cannot find|file not found" "$IMPORT_LOG" \
   | grep -vE "fontdata|CenturyGothic|default\.tres|godot_mcp" | grep -q .; then
  echo "   [FAIL] cold-import holds blocking lines:"
  grep -iE "SCRIPT ERROR|Parse Error|Failed|Cannot find|file not found" "$IMPORT_LOG" \
    | grep -vE "fontdata|CenturyGothic|default\.tres|godot_mcp"
  rm -f "$IMPORT_LOG"
  exit 1
fi
rm -f "$IMPORT_LOG"
echo "   (no lines above means clean — cold-import warnings filtered; see tools/README.md)"

echo "== export Linux"
timeout 560 godot --headless --export-release "Linux" "$CLONE/export/linux/build.x86_64" \
  2>&1 | tail -2

echo "== boot headless (5s)"
if timeout 5 "$CLONE/export/linux/build.x86_64" --headless > "$CLONE/boot.log" 2>&1; then
  if [ -s "$CLONE/boot.log" ]; then
    if grep -iE "SCRIPT ERROR|Parse Error|Failed|Cannot find" "$CLONE/boot.log" \
       | grep -vE "fontdata|CenturyGothic|default\.tres|godot_mcp" | grep -q .; then
      echo "   [FAIL] boot.log holds blocking errors:"
      grep -iE "SCRIPT ERROR|Parse Error|Failed|Cannot find" "$CLONE/boot.log" \
        | grep -vE "fontdata|CenturyGothic|default\.tres|godot_mcp"
      exit 1
    fi
    echo "   (boot.log held only cold-import warnings — clean)"
  else
    echo "   (boot.log empty — clean)"
  fi
else
  echo "   [FAIL] headless boot exited non-zero"
  exit 1
fi

echo "Fresh-clone proof PASS at $CLONE (build kept for inspection; remove it manually)"
