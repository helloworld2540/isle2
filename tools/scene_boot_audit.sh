#!/bin/bash
# Scene boot audit: boots every interactive scene headless with an isolated
# profile and fails on any script error — parse errors, "Node not found",
# "Failed to load script", or runtime errors from _ready — while ignoring the
# usual benign exit-time noise (ObjectDB leaks, "resources still in use").
#
# This catches what tools/smoke_test.gd does not: smoke reports PASS on
# scene load without forcing scripts to parse.
#
# Usage: tools/scene_boot_audit.sh
# Exits non-zero if any scene errors. Requires godot on PATH.

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SCENES="res://scenes/world.tscn res://scenes/upcycle.tscn res://scenes/reef_rescue.tscn res://scenes/shop.tscn res://scenes/stats_menu.tscn res://scenes/main_menu.tscn res://scenes/tutorial.tscn"

fail=0
for scene in $SCENES; do
	VH="/tmp/isle2_boot_$$"
	rm -rf "$VH"
	mkdir -p "$VH"
	out=$(timeout 60 env XDG_DATA_HOME="$VH" godot --headless --quit-after 2 "$scene" 2>&1)
	rm -rf "$VH"

	# Benign exit-time notices — these do not fail the audit.
	flags=$(printf '%s\n' "$out" | grep -iE "SCRIPT ERROR|Parse Error|Node not found|Failed to load script|Failed to instantiate" | grep -v "resources still in use" | grep -v "ObjectDB instances were leaked")
	if [ -n "$flags" ]; then
		echo "[FAIL] $scene"
		printf '%s\n' "$flags" | sed 's/^/       /'
		fail=1
	else
		echo "  ok  $scene boots clean"
	fi
done

if [ "$fail" -ne 0 ]; then
	echo "scene_boot_audit: FAIL"
	exit 1
fi
echo "scene_boot_audit: PASS"
