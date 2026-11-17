# Current project todo:

# done this pass
- tide_test now seeds a two-streak ending yesterday and asserts the
  claim extends it to three — the streak mechanic is covered alongside the
  rest of the day-claim behavior.
- THE STEADY KEEPER added (achievement #37): claim the daily tide report
  three days running. tide_streak (schema-persisted) increments on
  consecutive claims, resets on a missed day; stats page shows the live
  streak; legendary banner; docs to 37.
- guide.md gained "The island pays attention" — a compact roster of
  every NPC milestone beat.
- Tom reacts to TO THE ABYSS — the deepest reef honor gets a voice from
  the shore.
- Nina notices SILK TOUCH (flawless shifts — bench craft), Mara notices
  CLEAN SWEEP (perfect dives). The whole cast now grades the keeper's work,
  not just their wallet.
- Kai and Mara join the milestone chorus: Kai notices GOLDEN TOUCH (ten
  golden scraps), Mara notices LOOP MASTER (25 circuits) — every named
  islander now comments on the keeper's craft, not just purchases.
- Tom the shorekeeper notices diving: milestone lines for HEAVY HARVEST
  (30 kg single dive) and REEF VETERAN (25 dives) — the world reacts to
  commitment, not just purchases.
- World HUD bottle line graduates: with THE SILENT CHORUS earned it
  reads "✦ The Silent Chorus" instead of tallying.
- Fresh-save boot fix: the tide HUD never shows "day 0" — the daily
  claim lands after the HUD is built, so the counter floors at 1.
- The island marks its 100th tide: visiting the shop on day 100 logs a
  quiet centennial line — Corl polishes the counter unprompted.
- The stats page closes the bottle arc in writing: with THE SILENT CHORUS
  earned, a quiet two-line benediction appears in the deeds column — six
  voices, one shoreline, and the tide is a heart, not a clock.
- The stats page Ledger button advertises its own completion — "Tide
  Ledger (n/6)" — no need to open the page to know where you stand.
- Main menu continue-summary now shows days on the island alongside
  achievements — the save's own clock on the boot screen.
- Slot picker rows and the menu summary now show "day N" per island —
  SaveSlot.summary carries tide_days_visited, so a keeper can see which
  island has been lived in longest.
- Oda notices THE LONG KEEPER ("Staying is the whole job, love. You stayed.") — her last of three arcs: letters, chorus, endurance.
- THE LONG KEEPER added (achievement #36): ten fresh daily tide claims —
  the island sees its keeper first. tide_days_visited predicate, planner
  banner, docs to 36.
- Stats page: deeds column now counts days on the island — the save's
  own clock, next to the field log and Deep Cache tier.
- The tide HUD line now carries a day count ("≈ Glass Calm · day 12",
  "≈ Slack Water · day 12\nTomorrow: Night Drift") — the island remembers
  how long the keeper has been keeping. Saved per-island (tide_days_visited,
  schema-persisted, bumped once per fresh claim).
- migration_test now also restores the legacy save through GameState:
  every modern key (harbor_tips_bought, tides_logged) backfills from defaults
  and money survives the schema round-trip. Old saves are load-bearing
  fixtures.
- Eel Run keys up the gulls (pitch 0.95-1.08). All four tide voices are
  now audible at the dock.
- Glass Calm mobs the gulls: answer-chance doubles to 0.7 — every tide
  now tempers the dock chorus (clam: 0.7, slack: 0, night drift: foghorn).
- Slack Water hushes the dock: the answering gull never returns the cry.
  The tide's moods now shape sound as well as the HUD and the till.
- Night Drift at the dock: half the distant harbor cries become a low
  foghorn (Ambience bus). The tide with tricks now sounds like it.
- The TIDE REPORT card has its own voice: it rings the harbor swell
  (reef_swell) instead of the generic milestone chime. New "tide" accent on
  the banner (blue style, low chime pitch underneath the swell).
- Stats page now registers Corl's regulars: a deed line shows the whispers
  ledger (n/7, or the 7/7 "you are known at the counter" line once earned).
- Tutorial finale now gestures at the long game: the tide keeps four
  days and never repeats in a hurry. New players are pointed at NPCs,
  bottles and the tide from the very last card.
- The Steward Era now tints the world: once ISLAND STEWARD is earned the
  map wears a subtle golden hush (alpha 0.12, no motion) — the completion
  state finally has a visual signature.
- NPC dialogue body now scrolls: the lines area is a DragScrollContainer
  (200 px, 46 px touch-friendly) so long milestone-stacked conversations no
  longer overflow the card — touch drag works, the OK button stays put.
- Refactor: TideReport gains typed accessor today_key(); four call sites
  (shop night-drift flavor, shop ledger glass_calm bonus, both recap screens)
  now use it instead of poking the dictionary.
- Tide call-outs land on both recap screens: Slack Water and Night Drift in
  the bench summary ("the belt gave you an easy day" / "the gold came out to
  play"), Glass Calm and Eel Run in the dive summary ("the reef let go of its
  litter" / "the fish were quick about it"). The tide is acknowledged
  everywhere the player actually looks.

# high priority
- (none outstanding.)

# medium priority
# (shimmer item promoted to high priority)

# low priority backlog
- (none outstanding.)
