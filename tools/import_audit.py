#!/usr/bin/env python3
"""Import audit: every Godot-imported asset on disk must have its .import
sidecar, and that sidecar must name this exact file.

Catches the classic release-time footgun of adding or restoring an asset
without reimporting: the scene loads blank in the exported build, not at
author time. The editor's "file changed on disk" warning is easy to miss
and fatal to a cut release.

Exits non-zero if any asset is missing a sidecar or any sidecar names a
different source. Run after adding or restoring binary assets.
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

IMPORTABLE = {
    ".png", ".jpg", ".jpeg", ".svg", ".webp",
    ".wav", ".ogg", ".mp3",
    ".ttf", ".otf",
}

fail = 0
checked = 0

for path in sorted(ROOT.rglob("*")):
    if not path.is_file():
        continue
    if ".godot" in path.parts or "export" in path.parts or ".git" in path.parts:
        continue
    if path.name.endswith(".import") or path.name.endswith(".import~"):
        continue
    if path.suffix.lower() not in IMPORTABLE:
        continue

    sidecar = path.with_suffix(path.suffix + ".import")
    checked += 1
    if not sidecar.exists():
        print("[FAIL] missing .import for %s" % path.relative_to(ROOT))
        fail += 1
        continue

    try:
        text = sidecar.read_text(errors="ignore")
    except OSError as e:
        print("[FAIL] unreadable .import for %s: %s" % (path.relative_to(ROOT), e))
        fail += 1
        continue

    # The sidecar references the source by its uid/path tail; require the
    # file's own basename to appear so a renamed asset can't pass.
    if path.name not in text:
        print("[FAIL] stale .import for %s (sidecar does not name the file)" % path.relative_to(ROOT))
        fail += 1

print("import_audit: %d assets checked, %d failure(s)" % (checked, fail))
sys.exit(1 if fail else 0)
