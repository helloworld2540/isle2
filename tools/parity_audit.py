#!/usr/bin/env python3
"""Doc-vs-code parity audit, tuned for reverts.

Hard scans of README.md / guide.md / PITCH.md / RELEASE_NOTES.md / TODO.md
against the shipped code and scenes. The failure mode this hunts: docs that
still describe a feature a revert removed (guide says X, code has nothing).
Reported findings are advisory — exit 0 by default; --strict exits 1 when
any overclaim is found, so it can be wired into a gate once docs are clean.

Marker styles:
  file:<path>              — file exists (may be an empty string check too)
  file:<path>=<substr>     — file exists AND contains substr
  scene:<path>             — .tscn exists AND contains substr
  absent-ok                 — marker may be absent; never an overclaim

A pair flags an OVERCLAIM when a doc mentions the feature but its marker is
missing. A pair flags UNDERCLAIM when marker exists but no doc mentions it.
"""
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
DOCS = ["README.md", "guide.md", "PITCH.md", "RELEASE_NOTES.md", "TODO.md", "sprint.md"]

PAIRS = [
    # (label, doc phrases, marker (kind, target[, substr]))
    ("world courier ambience", ["WorldCourier", "courier flies", "courier crosses the strait", "courier streak", "The courier flies"], ("scene", "scenes/world.tscn", "WorldCourier")),
    ("courier flyby harness", ["courier_flight_test"], ("file", "tools/courier_flight_test.gd", "")),
    ("weighted reef spawns", ["weighted spawn", "SPAWN_WEIGHTS", "Weighted reef spawns"], ("file", "scripts/rr_fish.gd", "SPAWN_WEIGHTS")),
    ("spawn odds harness", ["spawn_weight_test"], ("file", "tools/spawn_weight_test.gd", "")),
    ("registry n/5 button", ["Reef Registry (n/5)", "registry keeps count", "registry button"], ("file", "scripts/stats_menu.gd", "_refresh_registry_button")),
    ("whole-sea islander beats", ["every voice goes quiet", "the whole chorus", "THE WHOLE SEA"], ("scene", "scenes/world.tscn", "\"whole_sea\":")),
    ("pale-courier islander beats", ["courier is spoken of everywhere", "PALE COURIER"], ("scene", "scenes/world.tscn", "\"pale_courier\":")),
    ("eel run courier tide line", ["courier rides the current", "the courier rides the fast water", "Eel Run's HUD"], ("file", "scripts/tide_report.gd", "courier rides")),
    ("per-tide banner voice", ["tide has a voice", "tide_pitch", "The tide has a voice on the card"], ("file", "scripts/ui/achievement_banner.gd", "tide_pitch")),
    ("courier glint in reef", ["the courier glints", "sparks a small blue-white burst"], ("file", "scripts/reef_rescue.gd", "\"fish_silverfin\" and not GameSettings.reduce_motion")),
    ("courier passage counter", ["Courier's Passage", "courier_passes"], ("file", "scripts/game_state.gd", "courier_passes")),
    ("main-menu continue badges", ["front door remembers", "✳ The Pale Courier"], ("file", "scripts/main_menu.gd", "pale_courier")),
    ("slot-row signatures", ["Slot rows sign themselves", "✳ once the Silverfin"], ("file", "scripts/save_slot.gd", "\"courier\"")),
    ("schema relic audit", ["schema_audit"], ("file", "tools/schema_audit.py", "")),
    ("silverfin species", ["Silverfin"], ("file", "scripts/fish_catalog.gd", "\"fish_silverfin\"")),
]

def read(name):
    p = ROOT / name
    return p.read_text(errors="ignore") if p.exists() else ""

def marker_ok(kind, target, substr):
    p = ROOT / target
    if kind == "file":
        if not p.exists():
            return False
        return (substr == "") or (substr in p.read_text(errors="ignore"))
    if kind == "scene":
        if not p.exists():
            return False
        return substr in p.read_text(errors="ignore")
    return False

doc_texts = {d: read(d) for d in DOCS}
total_over = 0
total_under = 0

print("doc-vs-code parity audit\n")
for label, phrases, marker in PAIRS:
    kind, target, *rest = marker
    substr = rest[0] if rest else ""
    marker_present = marker_ok(kind, target, substr)
    mentions = {d: [p for p in phrases if p.lower() in doc_texts[d].lower()] for d in DOCS}
    mentions = {d: m for d, m in mentions.items() if m}
    if mentions and not marker_present:
        total_over += 1
        where = ", ".join(sorted(mentions))
        print("[OVERCLAIM] %s — documented in %s but marker missing (%s %s)" % (label, where, kind, target))
    elif marker_present and not mentions:
        total_under += 1
        print("  silent  %s — shipped, undocumented (informational only)" % label)
    else:
        state = "ok (docs+code)" if mentions else "absent everywhere (ok)"
        print("  ok  %s — %s" % (label, state))

world = read("scenes/world.tscn")
for beat in ["whole_sea", "pale_courier", "far_point", "island_steward"]:
    print("  beat %-16s x%d in world.tscn" % (beat, world.count('"%s"' % beat)))

print("\nparity_audit: %d overclaim(s), %d silent(s)" % (total_over, total_under))
if total_over and "--strict" in sys.argv:
    sys.exit(1)
sys.exit(0)
