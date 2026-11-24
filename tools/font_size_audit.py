#!/usr/bin/env python3
"""Mobile legibility audit: every explicit font_size in scenes/ and scripts/
must clear 24px unless the text is a decorative single-glyph mark (★ ◆ ✳ ✦).

The project promises legible, large type on a 1152x648-class phone screen
(everything >= 24 px clears the legibility floor here; the 44 px figure is the
touch-target floor, a different audit — tools/touch_audit.py).

This audit fails the gate when someone types a new small label into a scene.
"""
import re
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
MIN_PX = 24

fail = 0

# Every live pattern for an explicit font size, in source syntax:
#   font_size = N              .tscn node property ("font_size = 24")
#   font_size=N                same, no-space spelling (covered by \s*)
#   theme_override_font_sizes/font_size = N   .tscn theme override key
#   add_theme_font_size_override("font_size", N)   .gd runtime override
#   font_size: int = N         .gd typed default
#   [font_size=N]              BBCode label text
PATTERNS = [
    # font_size = N / font_size=N / theme_override_font_sizes/font_size = N
    re.compile(r"(?<![A-Za-z_])font_size\s*=\s*(\d+)"),
    # typed GDScript default: font_size: int = 18
    re.compile(r"(?<![A-Za-z_])font_size\s*:\s*int\s*=\s*(\d+)"),
    # runtime theme override: add_theme_font_size_override("font_size", 24)
    re.compile(r'add_theme_font_size_override\(\s*"font_size"\s*,\s*(\d+)\s*\)'),
    # BBCode label text: [font_size=24]
    re.compile(r"\[font_size=(\d+)\]"),
]

SOURCE_SUFFIXES = (".tscn", ".gd")

for path in sorted(ROOT.rglob("*")):
    if path.suffix not in SOURCE_SUFFIXES:
        continue
    if ".godot" in path.parts or "export" in path.parts or ".import" in path.parts:
        continue
    if path.name.endswith(".bak"):
        continue
    text = path.read_text(errors="ignore")
    sizes = set()
    for pattern in PATTERNS:
        for m in pattern.finditer(text):
            sizes.add(int(m.group(1)))
    for size in sorted(sizes):
        if size < MIN_PX and size != 0:
            print("[FAIL] %s: font_size %d px (< %d)" % (path.relative_to(ROOT), size, MIN_PX))
            fail += 1

if fail:
    print("font_size_audit: %d failure(s)" % fail)
    sys.exit(1)
print("font_size_audit: PASS (all explicit font sizes >= %d px)" % MIN_PX)
