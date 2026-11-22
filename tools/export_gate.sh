#!/bin/bash
# Export gate: runs every audit and, on a green board, (optionally) re-exports
# all three platforms to ./export/. With no arguments it only runs the audits.
# The Web build exports to index.html and its files are packaged as
# export/web.zip.
# Usage: tools/export_gate.sh [--re-export]
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

tools/all_audits.sh

if [ "${1:-}" = "--re-export" ]; then
  mkdir -p "$ROOT/export/linux" "$ROOT/export/web" "$ROOT/export/android"
  # Drop stale artifacts from an older cut (the Web preset used to emit
  # build.html); best-effort, and never touch dotfiles — a GUI archive viewer
  # can hold a deleted file open, which FUSE renames to .fuse_hidden*.
  find "$ROOT/export/web" -mindepth 1 -maxdepth 1 -name 'build.*' -exec rm -rf {} + 2>/dev/null || true
  godot --headless --export-release "Linux" "$ROOT/export/linux/build.x86_64"
  godot --headless --export-release "Web" "$ROOT/export/web/index.html"
  godot --headless --export-release "Android" "$ROOT/export/android/build.apk"
  rm -f "$ROOT/export/web.zip"
  (cd "$ROOT/export/web" && zip -q -r "$ROOT/export/web.zip" . -x '*/.*' '.*')
  echo "Built into export/linux, export/web/index.html, export/android"
  echo "Packaged the Web build into export/web.zip"
fi

echo "EXPORT-GATE: PASS"
