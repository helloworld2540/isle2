#!/usr/bin/env python3
"""Dangling-reference audit: every literal res:// path in authored sources must
point at something that exists on disk.

Why: orphan_audit catches files nothing references; this catches the opposite —
a scene, script or shader that references a file which was deleted or renamed.
Godot only errors when that code path is reached (a portal target, a rarely
opened menu, an ending cinematic), so a renamed asset can ship and silently
break one branch of the game.

Scanned sources: .tscn, .tres, .gd, .godot, .cfg, .godotshader, plus
project.godot and export_presets.cfg. Generated trees (.godot/, export/,
addons/) and .import sidecars are skipped — they are engine output, not
authored references.

Also checks the special case of opaque string constants: a res:// path that
ends in a known asset extension but has no file on disk is always a bug, even
inside a plain string.

Exits 1 on any dangling path. Wired into tools/all_audits.sh.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = (".git", ".godot", "export", "addons", "node_modules", "__pycache__")
SOURCE_EXTS = (".tscn", ".tres", ".gd", ".godot", ".cfg", ".gdshader", ".shader")

# res://path — stop at the first character that cannot be in a resource path.
# Godot paths may contain spaces and unicode, so only exclude quote/bracket
# delimiters and whitespace-that-precedes-punctuation heuristics.
PATH_RE = re.compile(r'res://([^\s"\'\)\],]+)')

# Paths that Godot builds at runtime from pieces; a literal prefix with a
# trailing slash is fine (directory check handles it). Anything matched with
# a variable interpolation was already excluded by PATH_RE.

def iter_sources():
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            if not name.endswith(SOURCE_EXTS):
                continue
            if name.endswith(".import"):
                continue
            yield os.path.join(dirpath, name)


def main() -> int:
    failures = []
    checked = 0
    for path in iter_sources():
        try:
            text = open(path, errors="ignore").read()
        except OSError as exc:
            failures.append((path, 0, "unreadable: %s" % exc))
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            for match in PATH_RE.finditer(line):
                rel = match.group(1).rstrip(".")
                # Ignore paths built by concatenation ("res://scenes/" + name).
                if rel.endswith("/") or rel == "":
                    continue
                # Ignore paths built at runtime: glob exclude patterns in
                # export presets, and printf/format templates ("npc%d.png").
                if any(ch in rel for ch in "*?%$[]{}"):
                    continue
                checked += 1
                target = os.path.join(ROOT, rel)
                if not os.path.exists(target):
                    failures.append((os.path.relpath(path, ROOT), lineno, "res://" + rel))

    for rel_path, lineno, target in failures:
        print("FAIL %s:%d references missing %s" % (rel_path, lineno, target))
    if failures:
        print("reference_audit: %d dangling reference(s) of %d checked" % (len(failures), checked))
        return 1
    print("reference_audit: PASS (%d res:// references resolve)" % checked)
    return 0


if __name__ == "__main__":
    sys.exit(main())
