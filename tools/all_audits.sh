#!/bin/bash
# All-audits gate: one command before cutting a build. Runs every harness and
# every Python audit in tools/ and exits non-zero if anything fails.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ISA="user://slots"
[ -n "${XDG_DATA_HOME:-}" ] && DATA="$XDG_DATA_HOME" || DATA="$HOME/.local/share"
SLOTS="$DATA/godot/app_userdata/isle2/slots"

# Refuse to run against real player data.
if [ -e "$SLOTS" ]; then
  echo "SKIP: player slots present at $SLOTS — not running against real data"
  exit 0
fi

fail=0
# Keeper's Star runs with --path . and its own isolated user data dir: its
# runtime checks need the project autoloads, which only resolve that way.
# Both paths are cleaned up below regardless of the hull result.
VERIFY_HOME="/tmp/isle2_verify_$$"
rm -rf "$VERIFY_HOME"
mkdir -p "$VERIFY_HOME"
echo "== keeper_star_test"
if ! timeout 240 env XDG_DATA_HOME="$VERIFY_HOME" godot --headless --path . -s tools/keeper_star_test.gd; then
  echo "[FAIL] keeper_star_test"
  fail=1
fi
rm -rf "$VERIFY_HOME"

# CardQueue walks the island-wide card lane with inline probe cards — no
# autoload globals, but it still runs with --path . like every SceneTree test.
echo "== card_queue_test"
if ! timeout 240 godot --headless --path . -s tools/card_queue_test.gd; then
  echo "[FAIL] card_queue_test"
  fail=1
fi

# Layout audit instantiates every screen against a fresh profile and measures
# screen-space Controls; isolated so it never reads player saves.
VERIFY_HOME="/tmp/isle2_layout_$$"
rm -rf "$VERIFY_HOME"
mkdir -p "$VERIFY_HOME"
echo "== layout_audit"
if ! timeout 240 env XDG_DATA_HOME="$VERIFY_HOME" godot --headless --path . -s tools/layout_audit.gd; then
  echo "[FAIL] layout_audit"
  fail=1
fi
rm -rf "$VERIFY_HOME"

for t in smoke_test slot_test migration_test slot_ui_test tide_test restore_test hide_tide_test; do
  echo "== $t"
  if ! timeout 240 godot --headless --script tools/$t.gd; then
    echo "[FAIL] $t"
    fail=1
  fi
  rm -rf "$SLOTS"
done

echo "== npc_beat_audit"
python3 tools/npc_beat_audit.py || fail=1
echo "== touch_audit"
python3 tools/touch_audit.py || fail=1
echo "== unique_id_audit"
python3 tools/unique_id_audit.py || fail=1
echo "== docs_audit"
python3 tools/docs_audit.py || fail=1

if [ "$fail" -ne 0 ]; then
  echo "ALL-AUDITS: FAIL"
  exit 1
fi
echo "ALL-AUDITS: PASS"
