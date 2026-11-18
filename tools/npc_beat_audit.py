#!/usr/bin/env python3
"""Audit the island's milestone beats against the achievement catalogue.

The guide promises that every named islander notices THE FAR POINT, and that
every beat an NPC speaks names a real achievement. A silent omission is the
failure this audit exists to catch — so it reads the packed scene's text
rather than instantiating it (instantiating pulls in wm_npc.gd, which depends
on autoloads that a bare process does not have).

Exit code is the number of failures (0 = clean), so the loop can gate on it.
"""
import re
import sys

WORLD = "scenes/world.tscn"
CATALOGUE = "scripts/achievement_catalog.gd"


def _achievement_ids(path: str) -> set:
    """Pull every "id": "..." out of the catalogue."""
    ids = set()
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            m = re.search(r'"id"\s*:\s*"([^"]+)"', line)
            if m:
                ids.add(m.group(1))
    return ids


def _beats_for_world(path: str) -> dict:
    """Return {npc_id: {beat_id: line}} for every WorldNPC in the scene."""
    text = open(path, encoding="utf-8").read()
    beats = {}
    # A WorldNPC instance is a [node name="WorldNPC_X" ...] block; its beats
    # live on the `milestone_beats = {...}` line that follows. The line is
    # long enough that Godot wraps it, so match across newlines.
    for block in re.finditer(
            r'\[node name="WorldNPC_([^"]+)"[^]]*\].*?'
            r'npc_id\s*=\s*"([^"]+)".*?'
            r'milestone_beats\s*=\s*\{(.*?)\}',
            text, re.S):
        npc_id = block.group(2)
        body = block.group(3)
        beats.setdefault(npc_id, {})
        for pair in re.finditer(r'"([^"]+)"\s*:\s*"((?:[^"\\]|\\.)*)"', body):
            beats[npc_id][pair.group(1)] = pair.group(2)
    return beats


def main() -> int:
    ids = _achievement_ids(CATALOGUE)
    beats = _beats_for_world(WORLD)
    fails = 0

    if not beats:
        print("[FAIL] no WorldNPC milestone_beats found in %s" % WORLD)
        return 1
    print("  ok  world.tscn declares NPC beats for %d NPCs" % len(beats))

    all_pairs = []
    for npc_id in sorted(beats):
        b = beats[npc_id]
        if not b:
            print("[FAIL] %s has milestone beats but none parsed" % npc_id)
            fails += 1
            continue
        print("  ok  %s has %d milestone beat(s)" % (npc_id, len(b)))
        for beat_id in sorted(b):
            if beat_id not in ids:
                print("[FAIL] %s beat '%s' is not a real achievement" % (npc_id, beat_id))
                fails += 1
            else:
                print("  ok  %s beat '%s' is a real achievement" % (npc_id, beat_id))
            all_pairs.append("%s/%s" % (npc_id, beat_id))

    # The guide names THE FAR POINT as noticed by all five islanders.
    for npc_id in sorted(beats):
        if "far_point" not in beats[npc_id]:
            print("[FAIL] %s does not notice THE FAR POINT" % npc_id)
            fails += 1
        else:
            print("  ok  %s notices THE FAR POINT" % npc_id)

    # A duplicated (NPC, beat) pair means two islanders share a line — usually
    # a copy-paste slip rather than an intended echo.
    seen = set()
    for pair in all_pairs:
        if pair in seen:
            print("[FAIL] duplicate beat %s" % pair)
            fails += 1
        seen.add(pair)

    print("npc_beat_audit: %d failure(s)" % fails)
    return fails


if __name__ == "__main__":
    sys.exit(main())