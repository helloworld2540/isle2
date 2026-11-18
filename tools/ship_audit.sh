#!/bin/bash
# ship_audit: one command to decide whether the tree is releasable.
#
# Runs every hygiene gate this project has, in the order that fails fastest:
#   1. all_audits.sh (13 harnesses + 3 python audits; self-skips against real slots)
#   2. scene_boot_audit.sh (every interactive scene boots with zero script errors)
#   3. font_size_audit.py (17 px mobile legibility floor)
#   4. import_audit.py (every importable asset's .import sidecar is fresh)
#   5. schema_audit.py (save schema: duplicates, codecs, defaults, relics — warn-only on relics)
#   6. parity_audit.py (docs describe only what ships; beat coverage per NPC)
#   7. git status --porcelain (clean tree = no uncommitted work in a release)
#
# Exits 0 only when everything is green. Designed for the pre-flight column
# of RELEASE_CHECKLIST.md, right before tools/export_gate.sh --re-export.
#
# Usage: tools/ship_audit.sh

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0

echo "== 1/7 all_audits"
if tools/all_audits.sh; then
	echo "   PASS (or SKIP — the player-slot guard declined to run against real data)"
else
	echo "   FAIL"
	fail=1
fi

echo "== 2/7 scene_boot_audit"
if tools/scene_boot_audit.sh; then
	echo "   PASS"
else
	echo "   FAIL"
	fail=1
fi

echo "== 3/7 font_size_audit"
if python3 tools/font_size_audit.py; then
	echo "   PASS"
else
	echo "   FAIL"
	fail=1
fi

echo "== 4/7 import_audit"
if python3 tools/import_audit.py; then
	echo "   PASS"
else
	echo "   FAIL"
	fail=1
fi

echo "== 5/7 schema_audit"
python3 tools/schema_audit.py | tee /tmp/isle2_schema_$$
# relics are informational; --strict is intentionally NOT used here
grep -q "failure(s)" /tmp/isle2_schema_$$ || fail=1
if grep -q "0 failure(s)" /tmp/isle2_schema_$$; then
	echo "   PASS"
else
	echo "   FAIL"
	fail=1
fi
rm -f /tmp/isle2_schema_$$

echo "== 6/7 parity_audit"
python3 tools/parity_audit.py --strict | tail -2
if [ "${PIPESTATUS[0]}" -eq 0 ]; then
	echo "   PASS"
else
	echo "   FAIL (0 overclaim(s) is required)"
	fail=1
fi

echo "== 7/7 git status --porcelain"
status=$(git status --porcelain)
if [ -z "$status" ]; then
	echo "   PASS (clean tree)"
else
	echo "   FAIL (uncommitted work — release from a clean HEAD only)"
	printf '%s\n' "$status" | sed 's/^/       /'
	fail=1
fi

echo
if [ "$fail" -ne 0 ]; then
	echo "ship_audit: NOT READY"
	exit 1
fi
echo "ship_audit: READY — run tools/export_gate.sh --re-export for a full re-cut"
