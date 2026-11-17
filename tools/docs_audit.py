#!/usr/bin/env python3
"""docs_audit: the markdown suite is load-bearing — README.md, guide.md,
TODO.md must each exist with non-trivial content and carry the sections the
game advertises. Fails loudly; prints PASS otherwise."""

import os
import sys

REQUIRED = {
    "README.md": ["Architecture", "Modules"],
    "guide.md": ["## Controls", "## Quick reference"],
    "TODO.md": ["# Current project todo:"],
    "PITCH.md": ["## Development", "## Future Development"],
    "overnight_sprint.txt": ["## 2026-11-17"],
}

failures = []
for path, anchors in REQUIRED.items():
    if not os.path.exists(path):
        failures.append(f"missing: {path}")
        continue
    text = open(path, encoding="utf-8").read()
    if len(text) < 400:
        failures.append(f"{path}: only {len(text)} bytes — looks gutted")
        continue
    for anchor in anchors:
        if anchor not in text:
            failures.append(f"{path}: missing anchor {anchor!r}")

if failures:
    print("docs_audit FAILED:")
    for failure in failures:
        print(" ", failure)
    sys.exit(1)
print("docs_audit: PASS")
