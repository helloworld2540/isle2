#!/bin/bash
# Export gate: runs every audit and, on a green board, (optionally) re-exports
# all three platforms to ./export/. With no arguments it only runs the audits.
# Usage: tools/export_gate.sh [--re-export]
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

tools/all_audits.sh

if [ "${1:-}" = "--re-export" ]; then
  mkdir -p "$ROOT/export/linux" "$ROOT/export/web" "$ROOT/export/android"
  godot --headless --export-release "Linux" "$ROOT/export/linux/build.x86_64"
  godot --headless --export-release "Web" "$ROOT/export/web/build.html"
  godot --headless --export-release "Android" "$ROOT/export/android/build.apk"
  echo "Built into export/linux, export/web, export/android"
fi

echo "EXPORT-GATE: PASS"
