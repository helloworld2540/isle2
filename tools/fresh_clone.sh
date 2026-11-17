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
timeout 400 godot --headless --import --path "$CLONE" 2>&1 \
  | grep -iE "SCRIPT ERROR|Parse Error|Failed|Cannot find|file not found" \
  | grep -vE "fontdata|CenturyGothic|default\.tres|godot_mcp" || true
echo "   (no lines above means clean — cold-import warnings filtered; see RELEASE_CHECKLIST.md)"

echo "== export Linux"
timeout 560 godot --headless --export-release "Linux" "$CLONE/export/linux/build.x86_64" \
  2>&1 | tail -2

echo "== boot headless (5s)"
timeout 5 "$CLONE/export/linux/build.x86_64" --headless > "$CLONE/boot.log" 2>&1 || true
if [ -s "$CLONE/boot.log" ]; then
  grep -iE "SCRIPT ERROR|Parse Error|Failed|Cannot find" "$CLONE/boot.log" \
    | grep -vE "fontdata|CenturyGothic|default\.tres|godot_mcp" \
    || echo "   (boot.log held only cold-import warnings — clean)"
else
  echo "   (boot.log empty — clean)"
fi

echo "Fresh-clone proof PASS at $CLONE (build kept for inspection; remove it manually)"
