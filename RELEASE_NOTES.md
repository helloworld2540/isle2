# Isle 2 — Trash Island, release notes

## Signed: Version 1.3.0 (Linux / Web / Android)

Everything below shipped and is packaged in 1.3.0.

## What's new since 1.2.0

- **The Silverfin** — a fifth reef species joins the water. Pale, quick,
  gone by dawn; it pays the biggest sighting in the Reef Registry. FishCatalog,
  the Registry overlay and the stats journal all read five species now;
  REEF REGISTRY is earned on five.
- **Weighted reef spawns** — fish spawns were uniform; now Goldie/Nemo are
  regulars, Crab common, the Grey Reef Shark rare (14), and the Silverfin a
  deliberate, rare sighting (10) — doubled to 20 on Eel Run, the courier's
  day on the water. Spawn selection is a weighted pick; TideReport drives the
  odds. `tools/spawn_weight_test.gd` covers every roll lands on a known
  species and the Eel Run double.
- **THE PALE COURIER** — the 45th badge: spot the Silverfin at least once.
  Tom the shorekeeper notices, in his own register; the world HUD celebrates it.
- **The Courier's Wake** — the first sighting queues a one-time world-map card
  (same run-recap path as The Last Page): the Silverfin earns ink, not just a
  badge.
- **Lore: the courier of the strait** — guide and World map & dock ambience
  carry the Silverfin's story (the courier's strait, the first keeper's
  margin note, Tom's word).
- **The Filled Almanac & the quiet harbor** — the keeper's book
  fills out in two directions: once all four tides are logged the stats page
  offers **The Almanac** (the next seven days of the rotation laid out, today
  in sea-foam), and once THE WHOLE SEA is earned the dock hushes — the gull
  flock cries ~80% less often and the far-jetty calls stretch and fall silent.
  Under **Hide the tide** every tide surface stays quiet; the almanac card
  opens to one line.
- **Every voice goes quiet at once** — earning THE WHOLE SEA now lands a
  wordless milestone beat in all five named islanders at once, not only Oda.
- **The Last Page & The Courier's Wake** — two one-time world-map cards
  (never clobbering a pending recap, never firing on silent restore): the
  keeper before you left the last page blank on purpose.
- **The front door remembers** — the main-menu Continue summary gains ✳ The
  Pale Courier and ✦ The Whole Sea for keepers who earned them; the island's
  bookends greet you at the boot screen.
- **The first keeper's margin notes** — every minigame briefing card now
  carries a quiet handwritten line from the first keeper, rotating by
  run/dive count (two voices: BENCH and WATER).
- **RELEASE_CHECKLIST** records the current catalogue count (45) and the
  verified APK values; **PITCH.md**, **README.md**, **guide.md** track the
  five species and 45 badges.
- **A permanent harness for the above**: `tools/keeper_star_test.gd`,
  `tools/npc_beat_audit.py`, both wired into `tools/all_audits.sh`.

## Prior releases

**Version 1.2.0** (signed, Linux / Web / Android)

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
- **A permanent harness for the above**: `tools/keeper_star_test.gd` and
  `tools/npc_beat_audit.py`, both wired into `tools/all_audits.sh`.

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
- **Six shoreline bottles** plus a seventh that only washes up when you've
  earned it. The Tide Ledger on the stats page keeps them re-readable.
- **The far point.** A rumour nobody repeats all the way through. It ends.
- **40 achievements**, a keeper's journal that records everything you did,
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
