# Isle 2 — Trash Island, release notes

**Version 1.0.0** (signed, Linux / Web / Android)

## What it is

A cozy single-player trash-recycling adventure. You walk a tile world, befriend
five islanders, and play two short arcade minigames — **Upcycle**
(belt-sorter) and **Reef Rescue** (drone dive) — whose output feeds one shared
island economy of weighted materials, trash currency and upgrades. Multi-slot
saves, reduced motion, drag-to-scroll everywhere, fully touch-friendly.

## What's inside the box

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
