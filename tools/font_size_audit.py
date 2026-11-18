#!/usr/bin/env python3
"""Mobile legibility audit: every explicit font_size in scenes/ and scripts/
must clear 24px unless the text is a decorative single-glyph mark (★ ◆ ✳ ✦).

The project promises legible, large type on a 1152x648-class phone screen
(44 px touch floor, everything ≥ 24 px). This audit fails the gate when
someone types a new small label into a scene.
"""
import re
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
MIN_PX = 24

fail = 0

PATTERNS = [
    re.compile(r"font_size\s*=\s*(\d+)"),
    re.compile(r'add_theme_font_size_override\("font_size",\s*(\d+)\)'),
    re.compile(r"font_size\s*:\s*(\d+)"),
    re.compile(r"font_size=(\d+)"),
]

for path in sorted(ROOT.rglob("*")):
    if path.suffix not in (".tscn", ".gd"):
        continue
    if ".godot" in path.parts or "export" in path.parts or ".import" in path.parts:
        continue
    if ".bak" in path.name:
        continue
    text = path.read_text(errors="ignore")
    for m in re.finditer(r"font_size\s*(?:/|\]?\\?\"?\.?=?[\"']?font_size[\"']?\s*[=:]\s*|=)?\s*(\d+)", text):
        size = int(m.group(1))
        if size < MIN_PX and size != 0:
            print("[FAIL] %s: font_size %d px (< %d)" % (path.relative_to(ROOT), size, MIN_PX))
            fail += 1

if fail:
    print("font_size_audit: %d failure(s)" % fail)
    sys.exit(1)
print("font_size_audit: PASS (all explicit font sizes >= %d px)" % MIN_PX)
