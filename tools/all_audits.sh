#!/bin/bash
# All-audits gate: one command before cutting a build. Runs every harness and
# every audit in tools/ and exits non-zero if anything fails.
#
# Isolation: every harness gets its own throwaway XDG_DATA_HOME under
# $AUDIT_HOME (auto-removed on exit), so no test can see another test's
# slots, none can see a real player's save, and the gate never has to skip.
# Set ISLE2_AUDIT_REAL_SLOTS=1 to audit against the real default profile —
# only allowed when no player slots are present there.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FAIL=0
AUDIT_HOME=""
APP=0

if [ "${ISLE2_AUDIT_REAL_SLOTS:-0}" = "1" ]; then
	[ -n "${XDG_DATA_HOME:-}" ] && DATA="$XDG_DATA_HOME" || DATA="$HOME/.local/share"
	SLOTS="$DATA/godot/app_userdata/isle2/slots"
	if [ -e "$SLOTS" ]; then
		echo "SKIP: player slots present at $SLOTS — not running against real data"
		exit 0
	fi
	echo "ALL-AUDITS: auditing the real default profile (no slots present)"
	ISOLATE=0
	SHARED_HOME="$DATA"
else
	AUDIT_HOME="/tmp/isle2_audit_$$"
	rm -rf "$AUDIT_HOME"
	mkdir -p "$AUDIT_HOME"
	ISOLATE=1
	echo "ALL-AUDITS: isolated profiles under $AUDIT_HOME (auto-cleaned)"
fi

cleanup() { [ -n "$AUDIT_HOME" ] && rm -rf "$AUDIT_HOME"; }
trap cleanup EXIT HUP INT TERM

iso() { # run a harness with a fresh isolated profile
	local home_dir="$AUDIT_HOME/app${APP}"
	APP=$((APP + 1))
	if [ "$ISOLATE" = "1" ]; then
		rm -rf "$home_dir"; mkdir -p "$home_dir"
		env XDG_DATA_HOME="$home_dir" "$@"
	else
		XDG_DATA_HOME="${XDG_DATA_HOME:-}" "$@"
	fi
}

failed() { echo "[FAIL] $1"; FAIL=1; }

# Runtime harnesses need the project autoload Nodes at runtime.
for t in keeper_star_test card_queue_test layout_audit tutorial_tour_test courier_arc_test courier_flight_test courier_letter_test portal_reach_test; do
	echo "== $t"
	if ! iso timeout 240 godot --headless --path . -s "tools/$t.gd"; then
		failed "$t"
	fi
done

# Scene-boot audit always uses its own /tmp profile internally.
echo "== scene_boot_audit"
if ! bash tools/scene_boot_audit.sh; then
	failed scene_boot_audit
fi

# Static harnesses are load-only.
for t in smoke_test slot_test migration_test slot_ui_test tide_test restore_test hide_tide_test reef_registry_test margin_notes_test courier_letters_test; do
	echo "== $t"
	if ! iso timeout 240 godot --headless --script "tools/$t.gd"; then
		failed "$t"
	fi
done

for t in economy_audit parity_audit schema_audit font_size_audit import_audit npc_beat_audit touch_audit unique_id_audit drag_scroll_audit docs_audit export_preset_audit orphan_audit achievement_audit; do
	echo "== $t"
	python3 "tools/$t.py" || failed "$t"
done

if [ "$FAIL" -ne 0 ]; then
  echo "ALL-AUDITS: FAIL"
  exit 1
fi
echo "ALL-AUDITS: PASS"
