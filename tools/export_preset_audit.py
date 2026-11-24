#!/usr/bin/env python3
"""Export-preset audit: every concrete path the presets reference must
exist and be git-tracked, and the documented exclusions must be in place.

The failure mode this hunts: a preset pointing at a gitignored path. The
developer's working directory has the file, everything exports fine locally,
and every fresh clone ships a broken build. export/ is gitignored by design,
so anything it holds is invisible to a clone.

Checks:
  1. Every concrete (non-glob) path referenced in export_presets.cfg —
     res://x/y or a bare relative x/y (e.g. export/web/index.html) — exists
     on disk and is tracked by git.
  2. Every preset excludes res://tools/* and res://addons/* from the pack.
  3. Every [preset.N] block has a name.

The Web preset uses Godot's default HTML shell, so there is no custom shell
file to validate.

Exits non-zero on any failure. Wired into tools/all_audits.sh.
"""

import os
import re
import subprocess
import sys

PRESETS = "export_presets.cfg"
failures = []

def fail(msg):
    failures.append(msg)
    print("[FAIL] %s" % msg)

def ok(msg):
    print("  ok  %s" % msg)

try:
    text = open(PRESETS, encoding="utf-8").read()
except FileNotFoundError:
    print("[FAIL] export_presets.cfg missing")
    sys.exit(1)

out = subprocess.run(["git", "ls-files"], capture_output=True, text=True, check=True).stdout
tracked = {line.strip() for line in out.splitlines() if line.strip()}

# --- 1) concrete res:// and bare-relative preset paths must exist ----------
# Godot preset keys such as export_path hold plain relative paths with no
# res:// prefix (e.g. export/web/index.html); source paths use the res:// form.
concrete = set()
for m in re.finditer(r'"(res://[^"]*|export/[A-Za-z0-9_./-]*)"', text):
    path = m.group(1)
    if not path or "*" in path:
        continue  # globs are patterns, not files
    concrete.add(path)

for path in sorted(concrete):
    rel = path[len("res://"):] if path.startswith("res://") else path
    if not os.path.exists(rel):
        fail("preset references missing file: %s" % path)
        continue
    if rel.startswith("export/"):
        # Build outputs live in the gitignored export/ tree on purpose.
        ok("%s exists (build output)" % rel)
        continue
    if rel not in tracked:
        fail("preset references untracked file (gitignored? fresh clones break): %s" % path)
    else:
        ok("%s exists and is tracked" % rel)

# --- 2) tools/ and addons/ must be excluded from every pack -----------------
blocks = re.split(r"(?m)(?=^\[preset\.\d+])", text)
presets = [b for b in blocks if b.startswith("[preset.")]
if not presets:
    fail("no [preset.N] blocks found in export_presets.cfg")
for block in presets:
    name_m = re.search(r'^name="([^"]+)"', block, flags=re.M)
    name = name_m.group(1) if name_m else "<unnamed>"
    if not name_m:
        fail("preset block without a name: %r" % block.strip()[:40])
    for needle in ("res://tools/*", "res://addons/*"):
        if needle not in block:
            fail("preset %r does not exclude %s" % (name, needle))
        else:
            ok("preset %r excludes %s" % (name, needle))

print("export_preset audit: %s" % ("PASS" if not failures else "%d failure(s)" % len(failures)))
sys.exit(0 if not failures else 1)
