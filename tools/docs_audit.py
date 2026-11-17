#!/usr/bin/env python3
"""docs_audit: the markdown and shipping suite is load-bearing — every
document a publisher or player will find in the repo must exist with
non-trivial content and carry the sections it advertises. Fails loudly;
prints PASS otherwise."""

import os
import subprocess
import sys

REQUIRED = {
    "README.md": ["Architecture", "Modules"],
    "guide.md": ["## Controls", "## Quick reference"],
    "TODO.md": ["# Current project todo:"],
    "PITCH.md": ["## Development", "## Future Development"],
    "RELEASE_NOTES.md": ["## What it is", "## What's inside", "## Building it"],
    "RELEASE_CHECKLIST.md": ["## Verified", "## Pre-flight", "## Pending"],
    "overnight_sprint.txt": ["## 2026-11-17"],
}

failures = []

# No build artifacts may ever be tracked in git — the working dir may hold
# them, but a project someone is asked to clone must never serve them.
for path in subprocess.run(
    ["git", "ls-files"], text=True, capture_output=True, check=True
).stdout.splitlines():
    if path.startswith("export/") or path.lower().endswith((".apk", ".pck", ".wasm", ".x86_64", ".sig", ".idsig")):
        failures.append(f"tracked build artifact: {path}")

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
