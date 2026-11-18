# Isle 2 — Trash Island, release notes

**Version 1.2.0** (signed, Linux / Web / Android)

## What's new since 1.1.0

- **THE KEEPER'S STAR** — the island's epilogue, and the 43rd badge. After
  ISLAND STEWARD is earned, a sixth starfish appears at the far point east of
  the watcher. Walking over it delivers the island's last card, rings a low
  harbor bell, pays +$50 and grants THE KEEPER'S STAR. It is deliberately
  *not* counted toward the STARLIGHT set — the epilogue is a separate,
  quieter beat for a keeper who proved they could keep everything else.
  One per island, exactly once.
- **The Far Point's Reply & THE WHOLE SEA** — an eighth and final bottle washes
  up once THE KEEPER'S STAR is found; the Tide Ledger grows a row, the
  journal reads bottles n/8. Reading all eight notes earns THE WHOLE SEA,
  the hidden 44th badge — the keeper who listened to the very end.
- **All five islanders now notice THE FAR POINT** — the guide promised every
  named islander would speak of the one on the far point once seen; Mara, Tom
  and Kai were silent. They each got a line in their own register.
- **A permanent harness for the above**: `tools/keeper_star_test.gd` (scene
  loads, catalogue entry is real and on the Hidden track, capstone does not
  depend on the star, schema round-trip) and `tools/npc_beat_audit.py` (every
  beat names a real achievement, all five notice the watcher, no duplicate
  pairs), both wired into `tools/all_audits.sh`.

## Prior releases

**Version 1.1.0** (signed, Linux / Web / Android)

## What it is

A cozy single-player trash-recycling adventure. You walk a tile world, befriend
five islanders, and play two short arcade minigames — **Upcycle**
(belt-sorter) and **Reef Rescue** (drone dive) — whose output feeds one shared
island economy of weighted materials, trash currency and upgrades. Multi-slot
saves, reduced motion, drag-to-scroll everywhere, fully touch-friendly.

## What's inside the box

- **Hidden-tide mode.** A full second playthrough style: every tide
  surface goes quiet ("The sea keeps its own counsel — and so do you.").
  The tide still runs, the almanac still fills, the keeper just reads the
  water instead of the HUD. THE QUIET KEEPER and THE TIDE WALKER (41-42)
  are only earnable here.

- **The daily tide.** A deterministic four-day rotation bends the reef, the
  belt, the golden rolls and the shop's bulk bonus. The keeper's HUD keeps it
  in view; the shop sells tomorrow's reading for a dockhand's fee.
- **The keeper's almanac.** Four tides logged across real calendar days.
  Earning it unlocks THE FOUR TIDES, a lore page and a secret
  (`THE KEEPER'S LETTER`).
- **Eight shoreline bottles** (seven washes up when you've earned it; the
  eighth washes up only for the keeper the island kept). The Tide Ledger on
  the stats page keeps them re-readable.
- **The far point.** A rumour nobody repeats all the way through. It ends.
- **44 achievements**, a keeper's journal that records everything you did,
  and a stats page that writes the ending.

## What the keeper should know before diving in

- Everything saves invisibly as you play. **Quitting never costs progress.**
- The island resets on demand (stats page) — named, with a warm Card, behind
  a confirm.
- Your first backup is automatic from the second save onwards; the stats page
  restores it on request, with a peek first.

## Building it

```sh
tools/all_audits.sh      # every check, green before export
tools/export_gate.sh --re-export   # audits, then rebuilds all three platforms
```

Harnesses and audits refuse to run against real player slots. See
`RELEASE_CHECKLIST.md` for what is and isn't verified (short version: exports
compile, harnesses are green, on-device and in-browser runtime smoke is
still pending).

## Credits

Built in Godot 4. Audio assets are placeholders (see `sound/`); art is
Krita-drawn and generated; the island itself is the actual product name.
