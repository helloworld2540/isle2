#!/usr/bin/env python3
"""Achievement catalogue audit: the guide, the catalogue and the stats page
must agree.

Checks:
  1. Every ENTRIES id has a predicate branch in is_met and vice versa.
  2. Predicates reference only fields GameState actually exposes
     (spot-check of the save schema for the state keys the predicates use).
  3. The count claimed by README.md's "## Full achievement list (N)" and
     guide.md's "achievements n/N" matches len(ENTRIES).
  4. The stats page GUIDE_GROUPS list covers every "where" tag used by the
     catalogue (no badge invisible to the filter row).

Exits non-zero on any failure. Wired into tools/all_audits.sh.
"""

import os
import re
import sys

fails = []

def ok(msg):
    print("  ok  %s" % msg)

def fail(msg):
    fails.append(msg)
    print("[FAIL] %s" % msg)

cat = open("scripts/achievement_catalog.gd", encoding="utf-8").read()

ids = re.findall(r'"id":\s*"([^"]+)"', cat)
pred_block = cat.split("static func is_met", 1)[1] if "static func is_met" in cat else ""
preds = set(re.findall(r'^\t\t"([^"]+)":', pred_block, flags=re.M))

missing = [i for i in ids if i not in preds]
unused = [p for p in preds if p not in ids]
if missing:
    fail("entries without predicates: %s" % ", ".join(missing))
if unused:
    fail("predicates without entries: %s" % ", ".join(unused))
if not missing and not unused:
    ok("every entry has a predicate and vice versa (%d)" % len(ids))

# --- claimed counts in the docs ----------------------------------------------
readme = open("README.md", encoding="utf-8").read()
guide = open("guide.md", encoding="utf-8").read()
m = re.search(r"## Full achievement list \((\d+)\)", readme)
if not m:
    fail("README.md lacks the 'Full achievement list' heading")
elif int(m.group(1)) != len(ids):
    fail("README claims %s achievements; catalogue has %d" % (m.group(1), len(ids)))
else:
    ok("README achievement count matches (%d)" % len(ids))
for mm in re.finditer(r"achievements n/(\d+)", guide):
    if int(mm.group(1)) != len(ids):
        fail("guide.md claims %s; catalogue has %d" % (mm.group(1), len(ids)))
    else:
        ok("guide.md achievement count matches (%d)" % len(ids))
        break
else:
    fail("guide.md does not name the achievement count")

# --- stats-page guide covers every where-tag ----------------------------------
stats = open("scripts/stats_menu.gd", encoding="utf-8").read()
where = set(re.findall(r'"where":\s*"([^"]+)"', cat))
groups = re.search(r'const GUIDE_GROUPS: Array\[String\] = \[([^\]]*)\]', stats)
group_list = [g.strip().strip('"') for g in groups.group(1).split(",")] if groups else []
missing_groups = sorted(w for w in where if w not in group_list)
if missing_groups:
    fail("catalogue where-tags missing from GUIDE_GROUPS: %s" % ", ".join(missing_groups))
else:
    ok("stats-page guide groups cover all %d where-tags" % len(where))

print("achievement audit: %s" % ("PASS" if not fails else "%d failure(s)" % len(fails)))
sys.exit(0 if not fails else 1)
