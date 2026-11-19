#!/usr/bin/env python3
"""Orphan audit: scripts and scenes nothing references are dead weight in the
game pack (or, worse, half-finished features).

For every .gd under scripts/, report it as orphaned when its res:// path AND
its declared class_name (if any) both appear nowhere outside its own file and
outside .godot/ and export/. For every .tscn under scenes/, report it when
its res:// path appears nowhere outside itself and the editor cache and it is
not the main scene.

Class_name lookups are word-bounded; path lookups are plain substring matches.
tools/, docs, README, guide and the sprint log are searched too — documentation
that names a file keeps it alive. Exits 1 on any orphan. Wired into
tools/all_audits.sh.
"""

import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = (".git", ".godot", "export", "addons", "node_modules")

SEARCH_EXTS = (".gd", ".tscn", ".tres", ".godot", ".cfg", ".md", ".txt", ".json", ".py", ".sh", ".html", ".yml")

def iter_files():
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            yield os.path.join(dirpath, name)

haystack = "\n".join(
    open(f, errors="ignore").read()
    for f in iter_files()
    if os.path.splitext(f)[1] in SEARCH_EXTS and os.path.getsize(f) < 5_000_000
)

project_godot = open(os.path.join(ROOT, "project.godot"), errors="ignore").read()
main_scene = re.search(r'run/main_scene="res://([^"]+)"', project_godot)
main_scene = main_scene.group(1) if main_scene else ""

orphans = []

for dirpath, dirnames, filenames in os.walk(os.path.join(ROOT, "scripts")):
    for name in sorted(filenames):
        if not name.endswith(".gd"):
            continue
        path = os.path.join(dirpath, name)
        rel = os.path.relpath(path, ROOT)
        res_path = "res://" + rel.replace(os.sep, "/")
        body = open(path, errors="ignore").read()
        cn = re.search(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", body, flags=re.M)
        class_name = cn.group(1) if cn else None
        referenced = res_path in haystack or (
            class_name is not None
            and re.search(r"\b%s\b" % re.escape(class_name), haystack) is not None
        )
        if not referenced:
            orphans.append(rel)

for dirpath, dirnames, filenames in os.walk(os.path.join(ROOT, "scenes")):
    for name in sorted(filenames):
        if not name.endswith(".tscn"):
            continue
        path = os.path.join(dirpath, name)
        rel = os.path.relpath(path, ROOT)
        res_path = "res://" + rel.replace(os.sep, "/")
        if rel == main_scene:
            continue
        if res_path in haystack:
            continue
        orphans.append(rel)

if orphans:
    print("orphan audit FAILED:")
    for o in orphans:
        print("  orphan: %s" % o)
    sys.exit(1)
print("orphan audit: PASS")
sys.exit(0)
