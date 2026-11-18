# Current project todo:

# done this pass
- **THE FILLED ALMANAC** — the almanac's own prize: once all four tides are
  logged the stats page offers The Almanac, a gold card laying out the next
  seven days of the rotation (today in sea-foam). Hide-the-tide opens it to
  one quiet line, like every other surface. guide.md covers it (Quick
  reference + almanac section; a duplicated bullet removed). Smoke 51/51,
  ALL-AUDITS PASS.
- **The front door remembers** — the main-menu Continue summary badges
  line gains ✳ The Pale Courier and ✦ The Whole Sea for keepers who earned
  them; the island's bookends now greet you at the boot screen.
- **The Courier's Lore** — guide.md gains the Silverfin's story under
  World map & dock ambience (the courier of the strait, the first
  keeper's margin note, Tom's word); quick-reference bottle count fixed
  to eight (it still said seven). RELEASE_CHECKLIST catalogue count 44→45.
- **The Courier's Wake** — earning THE PALE COURIER queues a one-time
  world-map card (same run-recap path as The Last Page; never clobbers
  a pending recap, never fires on silent restore).
- **THE PALE COURIER** — the 45th badge: spotted the Silverfin at least
  once. Tom milestone beat ("Nobody's ever kept up with it."). Docs to 45.
- **The Silverfin** — a fifth reef species (fish_silverfin.png, drawn
  in-repo after the image pipeline credential failed). Spawns at weight
  18; FishCatalog, Reef Registry overlay (new row, panel grown), stats
  journal and collections read n/5; REEF REGISTRY now demands all five.
- **1.2.0 sealed** — version bumped in the Android preset (versionName=1.2.0 /
  versionCode=3), main-menu stamp, About page, README, RELEASE_NOTES,
  RELEASE_CHECKLIST (verified values), guide.md version history. All three
  platforms rebuilt at HEAD via `tools/export_gate.sh --re-export`; fresh-clone
  proof re-run and clean; APK badging dumped: versionName=1.2.0 /
  versionCode=3 / minSdk=24 / targetSdk=36 / label Trash Island.
- **The first keeper's margin notes** — every minigame briefing card
  (Upcycle bench and Reef Rescue) now carries a quiet handwritten line
  from the first keeper, rotating by run/dive count via new
  `scripts/margin_notes.gd` (two voices: BENCH and WATER). New
  `MinigameIntro.set_flavor_line` + `Flavor` row in minigame_intro.tscn.
- **The quiet harbor** — once THE WHOLE SEA is earned, the world map's
  gull flock cries ~80% less often, the far-jetty calls stretch to
  1.6–1.8× their cadence and never draw an answer. The sea is finished
  talking; the dock keeps the silence.
- **The Last Page** — earning THE WHOLE SEA queues a one-time world-map
  card (via the run-recap system): "The keeper before you left the last
  page blank on purpose." Never clobbers a pending run recap, never fires
  on silent restore; the banner still celebrates either way.
- **THE WHOLE SEA** — the hidden 44th badge: all eight bottles read.
  Legendary banner, Oda milestone beat ("You listened to the very end."),
  excluded from the ISLAND STEWARD capstone alongside keeper_star (else the
  far-point bottle would deadlock the capstone), world HUD bottle line flips
  to "✦ The Whole Sea", stats deeds column records it. Docs to 44.
- **THE FAR POINT'S REPLY** — an eighth bottle, the epilogue's paper tail.
  Washes up at the island's tip only after THE KEEPER'S STAR is found; the
  Tide Ledger gains a row for it (panel grown to fit), the journal ledger
  reads bottles n/8, and the far point finally signs his own name. guide.md,
  README and PITCH updated.
- **Far-point beats** — all five named islanders now speak of THE FAR POINT.
  Mara, Tom and Kai were missing the `far_point` milestone beat in
  `scenes/world.tscn` while the guide promised it of every one of them; each
  got a line in their own register. New `tools/npc_beat_audit.py` (in the
  all-audits gate) asserts every beat id is a real achievement, that all five
  NPCs notice the watcher, and that no (NPC, beat) pair is duplicated.
- guide.md notes the new app icon.
- sprites/icon.png replaced: a real island-and-bottle crest replaces the
  Godot default engine logo the Android launcher was shipping.
- 1.1.0 rebuilt clean: hidden tide + keeper badges in the shipped build.
- guide.md hide-tide paragraph now names THE QUIET KEEPER and THE TIDE
  WALKER, the hidden horizon rewards.
- Settings toggle for Hide-the-tide now rings the harbor bell faintly
  ('reef_swell' through the ambience bus) on enabling, and a soft return
  on disabling — the toggle itself tells you what you chose.
- Achievement Guide gains a HIDDEN section listing THE QUIET KEEPER
  and THE TIDE WALKER — catalogue discretion for the hunter.
- Fresh clone at HEAD re-proven clean after the 1.1.0 seal.
- The About page says something to the hidden keeper: "The sea keeps
  its own counsel — And so do you." Distinct line from the steward one.
- 1.1.0 shipped: Android versionName 1.1.0 / versionCode 2, About page +
  menu stamp + RELEASE_NOTES headline all in lockstep. Platforms re-built at
  HEAD. Lode badge dump clean.
- Version 1.1.0: Android preset (versionName=1.1.0, versionCode=2), About
  page stamp, main menu stamp, RELEASE_NOTES, README, hidden-tide mode listed
  in the box contents.
- Platforms rebuilt after the quiet-keeper seal.
- guide.md version history gains the hidden-tide entry.
- Permanent harness: tools/hide_tide_test.gd asserts the flag flips,
  persists, and restores — queued into all_audits.sh.
- Fixed a real bug the probe caught: set_hide_tide() had the assignment
  inside a dead branch — hide_tide never actually changed in memory even
  though persistence succeeded. Flip/reset round-trip now works.
- When Hide the tide is on, Oda's tide-aware line goes with her instead
  of naming the day's weather: "(She does not say the tide. She does not
  say where the light comes from.)"
- The keeper's journal line on the stats page now reads 'tides · · tide
  hidden' when the Hard-tide mode is active — the folder of the book is
  re-spelled for the quiet wager.
- THE TIDE WALKER added (achievement #42): holding THE STEADY KEEPER
  and THE QUIET KEEPER at once. Legendary banner, Oda notices ("once for
  listening, once for not. Either way, you stayed."). Docs to 42.
- The quiet line gained weight: "≈ The sea keeps its own counsel — and
  so do you." across all surfaces.
- The shop tip button, receipt and note flip to the quiet flavour when
  Hide the tide is on ("Dockhand's quiet", "A secret, kept", no tomorrow
  leaks). Corl keeps his ledger either way.
- Platforms rebuilt after the Hidden-tide pass.
- The stats page gains The Quiet Era (and The Quiet Steward Era behind
  the catalogue capstone) — unlocks when THE QUIET KEEPER is earned.
- Oda notices THE QUIET KEEPER ("Three held without help. The sea makes
  keepers like you by way of the horizon.") — the far-water hidden
  milestone.
- THE QUIET KEEPER added (achievement #41): three tides claimed with
  Hide the tide on — a streak kept without help. tide_quiet_best_streak
  (schema-persisted) tracks it; legendary banner; docs to 41.
- **Hide the tide** shipped (settings toggle, hard mode): every tide
  surface swaps to "The sea keeps its own counsel" instead of the day's
  reading — HUD, pause menu, both minigame HUDs, main menu, shop barometer,
  tide report card (suppressed entirely). The almanac still counts; the
  tide still bends the world; the keeper just pays full attention.
- **Hide the tide** shipped (settings toggle, hard mode): every tide
  surface swaps to "The sea keeps its own counsel" instead of the day's
  reading — HUD, pause menu, both minigame HUDs, main menu, shop barometer,
  tide report card (suppressed entirely). The almanac still counts; the
  tide still bends the world; the keeper just pays full attention.
- Full fresh-clone proof re-run after the About/motto/epilogue run —
  cold checkout still imports, exports and boots with zero errors.
- The About page's close becomes the island's last word to you:
  "Keep the shore" — the motto as the leaving salute.
- Stats page deeds column now lists THE ALMANAC KEEPER as a named deed.
  THE FOUR TIDES finalised the book — the journal says so.
- The About page carries the watcher silhouette above the title — the
  island frames its own credits with the keeper at the threshold.
- Fresh clone replay after About/door/motto work: still PASS — the repo
  alone builds, exports, and boots without error.
- The About page whispers a sequel tease — "The far point is only the
  beginning." — the island points at the horizon without promising a port.
- The main menu carries a quiet motto — "Keep the shore" — above the
  version stamp; the island says what it is for before it says hello.
- docs_audit now refuses to pass while any build artifact is tracked in
  git (export/, .apk, .pck, .wasm, .x86_64, .sig, .idsig) — the repo only
  ever carries sources, never binaries. PASS.
- About page cites the license in one line — readers know what it is
  before they even leave the menu.
- The About page credits the tooling honestly: AI in the loop, defended
  by a green harness.
- README gains a Building & verifying section: Godot 4.7.2 stable and
  matching templates are the only dependencies.
- guide.md's version history now includes the 1.0.0 seal — fresh clone
  import, three platforms, the audit gate, the 44 px floor, the About door.
- About-from-the-door wired exactly once; all three platforms re-verified.
- Fix: About button was connected once per _refresh_summary (on every
  slot change), so the About panel re-presented N times. Now wired once
  in _wire_buttons; slot_ui_test no longer warns about duplicate connects.
- The TIDE REPORT card title is now sea-foam instead of catalogue blue —
  the day's water, not a metric.
- tools/fresh_clone.sh: one command to prove a cold checkout ships —
  archive -> import -> Linux export -> headless boot; benign warnings
  filtered against the checklist list. PASS at HEAD.
- README gains a License section pointing at LICENSE.
- Kai notices THE FOUR TIDES — "Booked every tide and never once argued
  with the water. Shelves never full enough for a keeper who reads the sea."
- LICENSE added — the box ships with its terms.
- Fresh-clone proof: git archive -> import (2 benign warnings: font
  ordering, missing addon) -> Linux export -> headless boot with zero
  errors. Repo alone is sufficient.
- Fresh-clone proof: git archive -> clean import (two benign warnings)
  -> Linux export -> headless boot (exit 124). The repo alone is sufficient
  to build and run the game.
- export_gate.sh --re-export after the About-from-the-door work: all
  three platforms rebuilt clean; the About page is in every artifact.
- The main menu gains 'About' (bottom-right) — the same credits card
  opens from the front door, not only the island's pause menu.
- export_gate.sh --re-export ran end-to-end fresh: all three platforms
  rebuilt into export/ (Linux boots with 0-byte log; Web holds; Android
  APK signed).
- Main menu carries a discreet version stamp (v1.0.0) bottom-left — the
  box names its own edition.
- docs_audit now guards RELEASE_NOTES.md and RELEASE_CHECKLIST.md too —
  every document a publisher would find is checked for existence, size and
  advertised anchors. Whole gate green.
- The About page whispers a private line to keepers who earned ISLAND
  STEWARD — the keeper who kept it all — the credits page now has an
  epilogue of its own.
- About scene verified by smoke (50/50) — the editor was unreachable at
  the moment of visual check, but the scene is instantiated by the harness.
- The island menu gains an About card: credits page — who built it,
  which engines, which art, and the version. Wraps the island's earned life
  into 600 words. Diogenes-style: one press, no cost.
- New isle-themed app icon; Web + Linux re-verified headless.
- Web rebuilt after the tools/ exclude; 0 harness references in the .pck.
- Export presets now exclude res://tools/ from release builds — debug
  harnesses no longer ship inside the APK/builds. Verified by unzip: 0 matches.
- tools/docs_audit.py: the markdown suite is load-bearing — existence, size,
  and key anchors in README/guide/TODO/PITCH/overnight_sprint. Wired into
  all_audits.sh. All green.
- Android APK re-exported at HEAD; verifier-clean.
- Live bench boot confirmed: the tide line renders beneath the intro overlay
  ("≈ Slack wat—"), no layout breakage.
- The bench HUD now shows today's tide inline too — all three stations
  speak the weather before you commit depth, belt or ledger.
- Reef HUD now shows today's tide inline ("≈ Slack water — the belt turns
  slow"). Verified live: the line renders under the dive stats.
- The Reset confirm names the island ("Reset <name>?") — destructive
  decisions never reach an anonymous shore.
- All three platforms re-verified against the current tree again: Linux
  x86_64 (0-byte boot log, exit 124 healthy), Web artifact set (html/wasm/
  pck), Android signed APK (verifier-clean). One wrinkle: the export target
  dir must exist or the Linux export fails — documented in the checklist.
- Live world boot confirmed after the tint pass: Slack Water blue confirmed,
  day 1 HUD renders, welcome card legible.
- tools/all_audits.sh: one-command pre-flight gate runs every harness and
  audit; refuses to run against player slots; exits 0 only when all green.
- tools/unique_id_audit.py: any `.tscn` with a reused `unique_id=` fails
  loudly — silent node drops never slip in again. PASS at HEAD.
- The menu's Tide almanac line now carries the streak too ("almanac
  kept  ·  best streak N") — the boot screen's own ledger line.
- The main-menu continue summary also shows the cross-island total —
  "All islands: N days one keeper" — only when it exceeds the current island.
- The stats page now counts the keeper across all their islands:
  "All islands, one keeper: N days" (only when it exceeds this island).
- Reset island confirm copy rewritten warmer — "a clean book"
  acknowledges what a fresh keeper inherits, not only what they lose.
- Live stats page render confirmed post-changes: journal reads "tides 4/4 ·
  Tide almanac paid", ledger button "Tide Ledger (0/7)", Restore backup enabled
  when a backup exists, achievements 2/40 complete.
- guide.md gained the sound of the four tides — the dock chorus is
  now part of the written island.
- Live-verified the gold trim: with the almanac granted, a fresh world
  boot renders SeaBoat at (1.0, 0.88, 0.55).
- Oda notices THE FOUR TIDES ("You have the four. Ancient news — and the
  only news I will ever need.") — the keeper completes the book at her elbow.
- Once the keeper's almanac is complete, the far sailboat gains a warm
  gold trim — the harbour's sailors know the keeper walks the shore.
- Mara marks THE YEAR KEEPER ("A whole year of mornings with the keeper.
  The island keeps you now.") — the caretaker witnesses the long haul too.
- The world wears the day's mood: a faint tide tint (Glass Calm warm
  sand, Eel Run sea-glass, Slack Water grey, Night Drift moon-blue) under
  the HUD. Verified live at 1152x648 on Slack Water.
- tools/touch_audit.py: Button-only touch-floor check across all scenes;
  PASS as of ea. Wired into the mobile mandate like the slot harness is for
  saves.
- guide.md ends with a Version history digest — a player-facing timeline
  of the arcs the island shipped.
- Touch-target audit: slot row rename/delete buttons 36 → 44 px, settings
  sliders 40 → 44 px. All interactive controls in the mobile path are
  now ≥44 px (labels and decorative dividers exempt).
- Android APK re-verified against the current tree (signed, verifier-clean).
- The menu summary line now includes the almanac ("Tide almanac n/4" or
  "almanac kept") — a finish-line the keeper sees on the boot screen.
- RELEASE_CHECKLIST.md gains the backup-chain harness evidence.
- tools/restore_test.gd — regression coverage for the backup story:
  fresh boot has none, rotation creates .bak on the second write,
  backup_summary reads the .bak (money 100), load_game stands the .bak in
  for a corrupt primary, restore_backup rolls the island back. 0 failures.
- SaveManager now reports when it had to stand a backup in for the
  primary (last_recovery). Stats page shows "Recovered from the <n> backup
  this session" when it does — silent recoveries never surprise.
- The Restore backup confirm now previews the backup before committing —
  money, score, circuits and the file's modification date — so rolling back
  never lands on an unknown island. SaveManager gained backup_summary()
  (read-only).
- Restore backup button on the stats page: rolls the island back to its
  previous save, behind the shared confirm card, shares _pending_action with
  reset, greyed when no backup exists. SaveManager gains restore_backup().
- guide.md notes the tease-rows in the ledger and registry.
- Reef Registry locked rows hint at the species — machine-agnostic and
  spoiler-free (golden/gold, the heavy gray, the orange, the crab).
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

- done this pass
- **THE KEEPER'S STAR** — the 43rd badge and the island's epilogue: a hidden
  sixth starfish at the far point east of the watcher, shown only after
  ISLAND STEWARD. Not counted toward STARLIGHT, paid exactly once (+$50),
  new `keeper_star_found` save flag, Hidden-track catalogue entry, wired
  into `tools/keeper_star_test.gd` + all_audits.sh. guide.md, README and
  PITCH.md updated to 43.
