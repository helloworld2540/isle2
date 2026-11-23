#!/usr/bin/env python3
"""docs_audit: the markdown and shipping suite is load-bearing — every
document a publisher or player will find in the repo must exist with
non-trivial content and carry the sections it advertises. Fails loudly;
prints PASS otherwise."""

import os
import re
import subprocess
import sys

REQUIRED = {
    "README.md": ["Architecture", "Modules"],
    # The gameplay guide was restructured (Dive → Sort → Sell rewrite): the
    # old "## Quick reference" section is now the "## Frequently Asked
    # Questions" section. The anchor list follows the new document structure.
    "guide.md": ["## Controls", "## Frequently Asked Questions", "## The Four Tides", "## Technical Settings"],
    "TODO.md": ["# Current project todo:"],
    "overnight_sprint.txt": ["## 2026-11-19"],
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

# Version strings must agree: the main-menu stamp, the About page and the
# README shipping line all name the same version. A loop that bumps one and
# not the others prints a lie on the title screen.
version_hits = []
for path, pattern in (
    ("scenes/main_menu.tscn", r'text = "(v[0-9]+\.[0-9]+(?:\.[0-9]+)?)"'),
    ("scripts/ui/about.gd", r'Version ([0-9]+\.[0-9]+(?:\.[0-9]+)?)'),
    ("README.md", r'[Ss]hipping version: ([0-9]+\.[0-9]+(?:\.[0-9]+)?)'),
    ("guide.md", r'\*\*([0-9]+\.[0-9]+\.[0-9]+)\*\*'),
):
    m = re.search(pattern, open(path, encoding="utf-8").read())
    if m is None:
        failures.append(f"version stamp not found in {path}")
        continue
    v = m.group(1).lstrip("v")
    version_hits.append((path, v))
distinct = {v for _, v in version_hits}
if len(distinct) > 1:
    detail = ", ".join(f"{p}={v}" for p, v in version_hits)
    failures.append(f"version mismatch across files: {detail}")

if failures:
    print("docs_audit FAILED:")
    for failure in failures:
        print(" ", failure)
    sys.exit(1)
print("docs_audit: PASS")
