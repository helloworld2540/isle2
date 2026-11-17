# Current project todo:

# done this pass
- Tide Ledger locked rows now show spoiler-free hints instead of blank
  question marks — each bottle earns its own mystery tease.
- guide.md gains a top-line Quick reference for new keepers (loop,
  tide, tip, ledger, the invitation to come back).
- RELEASE_CHECKLIST.md ticks the frame-soak evidence.
- Frame-soak sanity: world booted frozen and stepped 120 frames at
  once — no crash, no errors.
- Oda marks the centennial: exactly on day 100, tide-aware NPCs append
  "I put you in the book — there is room for very few names."
- The menu tide line tooltips the almanac rule — the four-day rotation
  and that every one comes round.
- guide.md notes the menu tide line, the almanac line's streak, the gold
  glow at 4/4, and the "almanac kept" daily report wording.
- The main menu's continue panel now shows today's tide and day count —
  a returning keeper sees the weather before they even press Continue.
- The stats-page almanac line now carries the streak too (e.g.,
  "Tide almanac 2/4  ·  streak 6 — ...").
- The Achievement Guide overlay gains a THE TIDE appendix — a quick
  reference for the four conditions, the almanac, and the dockhand tip — so
  players get the cheat sheet in-game without the guide.md.
- The Tide Ledger legend counts what remains ("every note the tide ever
  left you — n/7 — tap to read again"), refreshed on open. Mid-way fixups
  crashed on a parse error; the final state imports clean and passes 49/49.
- The Tide Report card says "almanac kept" once the book is filled — "almanac
  kept  ·  streak N" — a small milestone on the daily readout.
- Tide titles now title-case properly: "Glass Calm", "Eel Run",
  "Slack Water", "Night Drift" — shared TideReport.title_case() owns it
  (HUD line and the tomorrow readout both read it).
- Slot picker now carries a footer hint: islands save automatically,
  quitting never costs progress. Docs parity for the multi-slot UX.
- The pause menu's leave-confirm now names the island ("\"Island\" will be
  waiting.") — multi-island players never guess which keeper they are
  putting down.
- The pause menu tide line now tooltips the full report (summary +
  blurb) on hover — the weather-board is as rich as the HUD.
- The HUD tide line graduates a second time: with THE FOUR TIDES earned
  (almanac complete) it stands at "✦ The Almanac Is Kept" — beneath The
  Fifth Tide's final graduation.
- The stats page almanac banner glows gold when all four tides are
  logged — the journal acknowledges the completed book.
- guide.md far-point paragraph now tells the whole arc: rumour, sight,
  badge, the note, and the last card.
- Reading the watcher's note fires a one-shot "A page from the far point"
  card — the last reply of the far-point arc. Persisted like the other
  nudges (nudge_watcher_note_shown).
- Refactor: GameState.island_day() owns the max(1, tide_days_visited)
  floor for display — the HUD and the pause menu read one clamp instead of
  two copies.
- Oda notices THE YEAR KEEPER — a full year of tides. Her last word
  belongs to those who stayed the longest.
- THE YEAR KEEPER added (achievement #40): 365 days of tides kept. The
  whole arc has its horizon; docs to 40.
- The island remembers its most punctual keeper: tide_best_streak
  (schema-persisted) tracks the longest claim run ever; the stats page shows
  it beside the live streak.
- guide.md attention roster synced: far point and steady keeper entries
  everywhere they belong — the five-voice rumour is now documented.
- Kai butts against the far point too ("I do not stock the far point.
  Never a good day out there.") — five voices run the rumour now.
- Tom also knows about the far point — "Oda sees him. I keep to my
  fishing." — the island's knowledge about the watcher is now spread out
  properly.
- Tide Ledger button now counts from the LEDGER_IDS list itself — fixed
  a stale hardcoded /6 after the seventh note was added (verified live:
  0/7).
- THE WATCHER'S NOTE added: bottle_watcher washes up on the east path
  once THE FAR POINT is seen. Seventh ledger row; THE SILENT CHORUS still
  needs six (the seventh is a blessing). Live-verified: spawn, pickup, found.
- The watcher's lantern breathes: a slow warm swell (1.8 s in, 1.8 s out,
  sine ease) so he can be read from across the water. Reduced motion holds
  him perfectly still.
- THE FIRST TIDE added (achievement #39): the very first daily claim.
  A starter the whole tide arc starts from. Docs to 39.
- Once THE FIFTH TIDE is granted, the HUD tide line graduates to
  "✦ The Fifth Tide" — the island stops scheduling weather for the keeper.
- Deeds column closes the arc twice: "The far point: seen." and, if
  granted, "The fifth tide: seen."
- THE FIFTH TIDE shipped: with every badge earned (ISLAND STEWARD), one
  last legendary card lands on the next world load — a low bell, +$250 and
  the island's last secret. Fifth_tide_granted (schema-persisted), paid once
  per island. Verified live: reload granted the gift and the HUD showers 250$.
- The far point breathes: a tight ring of drifting motes (WatcherMist,
  reused sparkle system, smaller rect, fewer/slower motes) hangs around the
  watcher as sea haze catching his lantern.
- Nina gossips about the far point: once THE FAR POINT is earned, word
  travels at the counter — nobody speaks of it, and everyone counts it as
  true anyway.
- Deeds column records the sighting: "The far point: seen." in full-completion saves.
- Oda notices THE FAR POINT ("Some of us watch the water. Some of us are
  watched by it.") — she explains what the watcher is without naming him.
- THE FAR POINT shipped: a mysterious hooded watcher at the island's
  far-east peninsula. First contact plays a low harbor bell and grants the
  38th achievement (THE FAR POINT) — Mira's rumour answered. Sprite painted
  in-repo (sprites/watcher.png, mist + lantern + void face).
- Mara plants the seed of something unseen: "They say someone watches
  from the far point. Nobody has caught them yet." — a hook for future
  story without committing to it.
- Fixed stale tutorial copy: the shore-bottles nudge said "read all
  three" — it now correctly points at six notes.
- The island greets returning keepers: if the save is 2+ days old, a
  one-shot "Welcome back, keeper" card lands on the first world load — the
  tide kept its four days without you. Persisted like the other nudges.
- The island pause menu now shows today's tide, the island day count,
  and the live streak — the pause card doubles as a weather board.
- Oda notices a week-long tide streak ("You are the reason my almanac has
  a spine.") — tide-aware NPCs now react to staying power, not just one-
  off purchases.
- The stats page Ledger button goes gold at 6/6 — the completed collection
  announces itself without opening the page.
- guide.md Corl legend notes the day-10/30/50 counter lines he never
  repeats.
- Corl marks the calendar: on days 10, 30 and 50 he says one thing to
  nobody in particular. The dockhand watches the keeper happen, one tide
  at a time.
- The tide HUD label does a small swell (1.25 -> 1.0 back-ease, 0.45 s)
  on the first world load of the day — the card lands in the HUD too.
  Skipped under Reduced motion.
- PITCH.md brought up to date: five NPCs, dep-ps multi-slot save path,
  the tide arc (daily tide, almanac, six bottles, 37 achievements, the
  whispers ledger), sprint log path.
- The game now pins its desktop window to 1152x648 at boot (GameSettings
  sizes the root window and clamps the minimum, Linux/Windows/macOS only —
  mobile owns the window). project.godot stays clean on disk: the running
  editor rewrites it on import.
- The shop note teaches the streak discount before it lands — "Regulars
  (3-day streak) pay \$15" / "You are a regular — \$15 today" at 3.
- Corl respects regulars: three days running and the dockhand's tip drops
  from 25$ to 15$. tide_streak gates tip_cost(); shop texts/disabled state
  read the shared accessor; harness still green.
- The TIDE REPORT card now shows the live streak ("streak N") once it
  reaches two — the daily habit reads back at the player every claim.
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
