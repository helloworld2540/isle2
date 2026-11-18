#!/usr/bin/env python3
"""Save-schema audit (scripts/game_state.gd SAVE_SCHEMA).

Catches the failure mode of large reverts/merges: a save key that no code
reads or writes anywhere except its schema entry — a silently rotting
fixture the player's file still carries.

Checks:
  1. No duplicate save keys.
  2. Every codec is one the loader understands.
  3. Every save key is referenced at least twice in the codebase — once in
     the schema line itself, plus at least one other read/write somewhere
     (var declaration, get_property, _persist, restore, …).
     WARNS (exit 1) on keys that appear exactly once (schema-only relics).
  4. Defaults match codec families: int→int-ish, bool→bool, string_array
     →list, dict→dict, float→int/float.

Usage: python3 tools/schema_audit.py [--strict]
Exits non-zero on failures (and on warnings with --strict).
"""
import re
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
GAME_STATE = ROOT / "scripts" / "game_state.gd"

CODECS = {"int", "float", "bool", "string", "string_array", "dict"}

fail = 0
warn = 0

def ok(msg: str) -> None:
    print("  ok  " + msg)

def fail_msg(msg: str) -> None:
    global fail
    print("[FAIL] " + msg)
    fail += 1

def warn_msg(msg: str) -> None:
    global warn
    print("[warn] " + msg)
    warn += 1

s = GAME_STATE.read_text()
m = re.search(r"const SAVE_SCHEMA: Array = \[(.*?)\]\n", s, re.S)
if not m:
    print("[FAIL] SAVE_SCHEMA not found in", GAME_STATE)
    sys.exit(1)

entries = re.findall(r"\[\s*\"([^\"]+)\",\s*\"([^\"]+)\",\s*([^,]+),\s*\"([^\"]+)\"\s*\]", m.group(1))
print("schema entries: %d" % len(entries))

# 1. duplicate save keys / property names
seen_keys, seen_props = {}, {}
for key, prop, default, codec in entries:
    if key in seen_keys:
        fail_msg("duplicate save key '%s'" % key)
    seen_keys[key] = prop
    seen_props.setdefault(prop, 0)
    seen_props[prop] += 1
    if prop in seen_props and seen_props[prop] > 1:
        fail_msg("property '%s' restored by more than one save key" % prop)
    ok("unique save key '%s'" % key) if False else None

# 2. codec ids
for key, prop, default, codec in entries:
    if codec not in CODECS:
        fail_msg("'%s' has unknown codec '%s'" % (key, codec))
    ok("codec '%s' valid" % codec) if False else None

# 3. a key referenced only by its schema line is a rotting relic
all_src = []
for path in ROOT.rglob("*"):
    if path.suffix in (".gd", ".tscn") and ".godot" not in path.parts and "export" not in path.parts:
        all_src.append((path, path.read_text(errors="ignore")))
for key, prop, default, codec in entries:
    hits = sum(text.count(key) for _, text in all_src)
    # the schema line itself counts 1; a var declaration + uses count more
    if hits <= 1:
        warn_msg("save key '%s' is referenced only in SAVE_SCHEMA — nothing reads or writes it" % key)
    else:
        ok("'%s' referenced %d times" % (key, hits))

# 3b. a key that appears ONLY inside game_state.gd is a relic of a
# reverted feature (e.g. courier_passes after a rollback) — the save keeps
# writing it but nothing reads it. Warning only, never a hard failure:
# external consumers may legitimately live in scenes/tools.
all_src_ext = [(p, t) for (p, t) in all_src if p.name != "game_state.gd"]
for key, prop, default, codec in entries:
    hits = sum(text.count(key) for _, text in all_src_ext)
    if hits == 0:
        warn_msg("save key '%s' has no references outside game_state.gd — relic of a reverted feature?" % key)
    else:
        ok("'%s' read externally %d time(s)" % (key, hits))

# 4. defaults match codec family
for key, prop, default, codec in entries:
    d = default.strip()
    good = True
    if codec == "int":
        good = re.fullmatch(r"-?\d+", d) is not None
    elif codec == "float":
        good = re.fullmatch(r"-?\d+(\.\d+)?", d) is not None
    elif codec == "bool":
        good = d in ("true", "false")
    elif codec == "string":
        good = d.startswith('"') and d.endswith('"')
    elif codec in ("string_array", "dict"):
        good = d.startswith("[") or d == "{}" or d.startswith("{")
    if not good:
        fail_msg("'%s' default %s doesn't match codec %s" % (key, default, codec))
    else:
        ok("'%s' default matches codec" % key)

print("schema_audit: %d failure(s), %d warning(s)" % (fail, warn))
if fail or (warn and "--strict" in sys.argv):
    sys.exit(1)
sys.exit(0)
