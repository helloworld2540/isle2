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
    # The tools/ README is the gate-facing doc: it must carry the section
    # anchors the audit promises (title + gate commands) and stay substantive.
    "tools/README.md": ["# tools/ — build & release gates", "## Gate commands"],
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

# Version strings must agree, and the single source of truth is the VERSION
# constant in scripts/version.gd. The main-menu stamp, the About page, the
# README shipping line and the guide changelog all name that same version.
version_source = open("scripts/version.gd", encoding="utf-8").read()
version_m = re.search(r'const VERSION := "([0-9]+\.[0-9]+(?:\.[0-9]+)?)"', version_source)
version = version_m.group(1) if version_m else None
version_hits = []
if version is None:
    failures.append("version source scripts/version.gd lacks a VERSION constant")

m = re.search(r'text = "v([0-9]+\.[0-9]+(?:\.[0-9]+)?)"', open("scenes/main_menu.tscn", encoding="utf-8").read())
if m is None or m.group(1) != version:
    failures.append(f"scenes/main_menu.tscn: version stamp does not match scripts/version.gd ({version})")
else:
    version_hits.append(("scenes/main_menu.tscn", m.group(1)))

about_text = open("scripts/ui/about.gd", encoding="utf-8").read()
if version is None or "Version.VERSION" not in about_text:
    failures.append(f"scripts/ui/about.gd: About page does not read Version {version} from scripts/version.gd")

m = re.search(r'[Ss]hipping version: ([0-9]+\.[0-9]+(?:\.[0-9]+)?)', open("README.md", encoding="utf-8").read())
if m is None or m.group(1) != version:
    failures.append(f"README.md: shipping version does not match scripts/version.gd ({version})")
else:
    version_hits.append(("README.md", m.group(1)))

m = re.search(r'\*\*([0-9]+\.[0-9]+\.[0-9]+)\*\*', open("guide.md", encoding="utf-8").read())
if m is None or m.group(1) != version:
    failures.append(f"guide.md: changelog version does not match scripts/version.gd ({version})")
else:
    version_hits.append(("guide.md", m.group(1)))

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
