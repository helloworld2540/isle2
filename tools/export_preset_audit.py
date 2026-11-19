#!/usr/bin/env python3
"""Export-preset audit: every concrete res:// path the presets reference must
exist and be git-tracked, and the documented exclusions must be in place.

The failure mode this hunts: a preset pointing at a gitignored path (e.g.
res://export/web_shell.html). The developer's working directory has the
file, everything exports fine locally, and every fresh clone ships a broken
Web build with raw $GODOT_* placeholders. export/ is gitignored by design,
so anything it holds is invisible to a clone.

Checks:
  1. Every concrete (non-glob) res:// path referenced in export_presets.cfg
     exists on disk and is tracked by git.
  2. Every preset excludes res://tools/* and res://addons/* from the pack.
  3. The Web preset's custom_html_shell points at a tracked file and that
     file carries the Godot shell placeholders ($GODOT_URL / $GODOT_CONFIG).

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

# --- 1) concrete res:// references must exist and be tracked ----------------
concrete = set()
for m in re.finditer(r'"(res://[^"]+)"', text):
    path = m.group(1)
    if "*" in path:
        continue  # glob filters are patterns, not files
    concrete.add(path)
for path in sorted(concrete):
    rel = path[len("res://"):]
    if not os.path.exists(rel):
        fail("preset references missing file: %s" % path)
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
    for needle in ("res://tools/*", "res://addons/*"):
        if needle not in block:
            fail("preset %r does not exclude %s" % (name, needle))
        else:
            ok("preset %r excludes %s" % (name, needle))

# --- 3) Web custom shell must be tracked and be a real Godot shell -----------
m = re.search(r'html/custom_html_shell="(res://[^"]+)"', text)
if not m:
    print("[note] no html/custom_html_shell set — default shell will be used")
else:
    shell_path = m.group(1)
    rel = shell_path[len("res://"):]
    if rel not in tracked:
        fail("Web custom_html_shell %s is not git-tracked — fresh clones get a blank page" % shell_path)
    else:
        body = open(rel, encoding="utf-8").read()
        missing = [marker for marker in ("$GODOT_URL", "$GODOT_CONFIG") if marker not in body]
        if missing:
            fail("Web custom_html_shell %s lacks %s — not a Godot shell" % (shell_path, ", ".join(missing)))
        else:
            ok("Web custom_html_shell %s is tracked and carries the shell markers" % shell_path)

print("export_preset audit: %s" % ("PASS" if not failures else "%d failure(s)" % len(failures)))
sys.exit(0 if not failures else 1)
