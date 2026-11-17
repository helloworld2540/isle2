#!/usr/bin/env python3
"""Touch-target audit for the mandated mobile floor.

Every interactive control in scenes/ that declares a minimum size must claim
at least 44 px on both axes. This audit flags *Button* nodes specifically
(the interactive class); labels, progress bars, dividers and other decoration
are exempt because they are not touch targets.
"""

import glob
import re
import sys

HEADER = re.compile(r"^\[node name=\"[^\"]+\" type=\"([^\"]+)\"", re.MULTILINE)
SIZE = re.compile(r"custom_minimum_size = Vector2\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*\)")


def block_ranges(text):
    matches = list(HEADER.finditer(text))
    for i, match in enumerate(matches):
        start = match.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        yield match.group(1), start, end


failures = []
for path in sorted(glob.glob("scenes/**/*.tscn", recursive=True)):
    text = open(path, encoding="utf-8").read()
    for node_type, start, end in block_ranges(text):
        if node_type != "Button":
            continue
        for match in SIZE.finditer(text[start:end]):
            width, height = float(match.group(1)), float(match.group(2))
            if (width and width < 44) or (height and height < 44):
                failures.append(f"{path}: {width:g}x{height:g}")

if failures:
    print("Touch-target audit FAILED:")
    for failure in failures:
        print(" ", failure)
    sys.exit(1)
print("Touch-target audit: PASS")
