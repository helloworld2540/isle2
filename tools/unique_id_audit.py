#!/usr/bin/env python3
"""unique_id audit: every `unique_id=N` in scenes/ may appear at most once
per file; the real hazard is a duplicated id inside one .tscn (silently
dropped nodes). Exits 1 with offenders listed; PASS otherwise."""

import glob
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

PATTERN = re.compile(r"unique_id=(\d+)")

failures = []
for path in sorted(glob.glob(str(ROOT / "scenes" / "**" / "*.tscn"), recursive=True)):
    text = open(path, encoding="utf-8").read()
    ids = PATTERN.findall(text)
    counts = Counter(int(i) for i in ids)
    for uid, count in counts.items():
        if count > 1:
            failures.append(f"{path}: unique_id={uid} appears {count}x")

if failures:
    print("unique_id audit FAILED:")
    for failure in failures:
        print(" ", failure)
    sys.exit(1)
print("unique_id audit: PASS")
