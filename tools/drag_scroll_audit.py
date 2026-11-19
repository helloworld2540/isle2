#!/usr/bin/env python3
"""DragScroll audit: every ScrollContainer in scenes/ must carry the project's
pinned drag-scroll script (scripts/ui/drag_scroll.gd).

Mobile mandate: finger-flick scrolling must work on every scrolling list in
the game, so the wrapper that adds mouse-drag scrolling on top of
ScrollContainer's native touch path is load-bearing. A new plain
ScrollContainer silently degrades the UX to two-finger scrolling on devices
that are picky about native touch handling.

Checks, for every ScrollContainer node in scenes/**/*.tscn:
  1. its section assigns a script via `script = ExtResource(...)` (or carries
     `script = ExtResource(...)` anywhere in the node block);
  2. that script resolves to res://scripts/ui/drag_scroll.gd.

Exits non-zero on any failure. Wiring: python3 tools/drag_scroll_audit.py
(in tools/all_audits.sh and tools/README.md).
"""

import sys
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCENES = ROOT / "scenes"
DRAG_PATH = "res://scripts/ui/drag_scroll.gd"

_failures = 0

def ok(msg):
    print("  ok  " + msg)

def fail(msg):
    global _failures
    _failures += 1
    print("[FAIL] " + msg)

for tscn in sorted(SCENES.rglob("*.tscn")):
    text = tscn.read_text(errors="ignore")
    # Map ext_resource ids to paths for this scene.
    id_to_path = {}
    for m in re.finditer(r'ext_resource[^]]*', text):
        line = m.group(0)
        pm = re.search(r'(?:^|\s)path="([^"]+)"', line)
        im = re.search(r'(?:^|\s)id="([^"]+)"', line)
        if pm and im:
            id_to_path[im.group(1)] = pm.group(1)
    for m in re.finditer(r'(?s)\[node name="([^"]+)"[^]]*type="ScrollContainer"[^]]*\](.*?)(?=\n\[|\Z)', text):
        name, body = m.groups()
        label = "%s: %s" % (tscn.relative_to(ROOT), name)
        script_m = re.search(r'script\s*=\s*ExtResource\("([^"]+)"\)', body)
        if script_m is None:
            fail("%s has no drag-scroll script" % label)
            continue
        script_path = id_to_path.get(script_m.group(1))
        if script_path != DRAG_PATH:
            fail("%s uses %s, expected %s" % (label, script_path, DRAG_PATH))
        else:
            ok("%s" % label)

print("drag_scroll audit: %s" % ("PASS" if _failures == 0 else "%d failure(s)" % _failures))
sys.exit(0 if _failures == 0 else 1)
