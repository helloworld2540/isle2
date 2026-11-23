#!/usr/bin/env bash
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
  tools/export_all.sh
fi

echo "EXPORT-GATE: PASS"
