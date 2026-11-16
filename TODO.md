# Current project todo:

# done this pass
- Deep Cache value fix: the score-priced upgrade's debris bonus was silently
  clamped away whenever the bag filled — which is *every* dive at the 10 kg
  starting bag — so Deep Cache did nothing until the bag grew. The reef payout
  now salvages whatever part of the cache bonus does not fit as money at the
  debris rate ($1/kg), and the summary card shows it ("… 5$ salvaged"). Verified
  in-game: Deep Cache off, 10 kg bag, 15 kg haul → 10 debris, $0; tier 1, 10 kg
  bag → 10 debris + $5 salvaged; tier 1, 20 kg bag, 24 kg haul → 20 debris + $8;
  a light 3 kg dive → 11 debris, $0, breakdown "(haul +3 kg · deep cache +8 kg)".
  Player save restored.
- Shop touch pass: every button in the redesigned shop is now ≥ 44 px tall
  (custom_minimum_size y=44 on the 15 Sell 1/5/All row buttons, the 5 Buy
  buttons and Return to World / Undo last sale). Verified in-game: all 22
  buttons report h=44, the two-column counter stays inside 1152×648 (scroll
  rect 1119 wide, content 559 tall, no scrolling needed, footer fully
  on-screen), and the rows still populate and sell.
- Balance pass 5 — trash-upgrade payback, measured not guessed. Trash costs are
  paid in **kg of held material**, and the bag is the hard cap on a loop's haul,
  so one loop banks ≈ bag capacity: the live dive payout accepts exactly the free
  capacity (10 kg at the starting bag, 20 kg at Bag Lv.1) for any haul ≥ capacity,
  and each debris sorts 1:1. Payback therefore lands at **~1 loop** for the whole
  first tier — Inv Cap Lv.1 (6 kg) ~0.6, Move Lv.1 (8) ~0.8 / Lv.2 (12) ~1.2,
  Range Lv.1 (12) ~1.2 — and later tiers cost *fewer* loops as the bag grows
  (+10 kg/level vs +3/+4/+6). It is deliberately cheap QoL, so **no prices
  changed**; the measured table is now in guide.md. Verified the tune nudge
  timing too: with the tour complete it stays silent at a 7 kg hold and appears
  (quoting "8 trash", flag persisted) the moment the hold reaches 8 kg, never
  mid-sale. Player save restored.
- Shop redesign: `shop.tscn` is now a two-column counter (Sell material rows on
  the left, Spend money + Activity on the right, footer with Return/Undo) inside
  rounded panels, and `shop_menu.gd` addresses every row/button by scene-unique
  name (`%Row_*`) instead of mirroring the layout tree. Verified in-game: rows
  populate, Sell 1 / All and the +25% bulk math are right (6 Glass → 38$), undo
  refunds money and returns the lot, purchases update, and the content fits
  1152×648 without clipping.
- Mobile touch pass 2: the in-run `ReturnToMapButton` in both minigames was
  40 px tall; it is now 48 px (verified both scenes report size.y = 48). The
  shared settings panel was rebuilt as four label+slider rows (Master / Music /
  Ambience / SFX) with a 40 px touch track each, sized so the opened panel fits
  a 1152×648 viewport (minimum height 622 < 648; the Reduce Motion checkbox sits
  fully on-screen at y 594–635 instead of clipping off the bottom). Values still
  sync and the Ambience handler still moves the bus (−6 dB at 50%, restored).
- First-upgrade nudge: the tour taught walk → dive → sort → sell, and "Room for
  more?" taught the bag, but nothing pointed at Move Faster / Collection Range /
  Deep Cache. `TutorialDirector` now has a fourth one-shot nudge, **Tune up the
  dock** (`nudge_tune_shown`), gated on a new `is_tour_complete()` so it never
  stacks on the intro. `wm_progress` fires it the first frame the hold can afford
  min(Move, Range) and the card quotes the live Move cost. Verified in-game on a
  tutorial-complete save with 27 kg: the card spawned with "8 trash" and the flag
  persisted (player save restored afterwards).
- Minigame ambience beds: the bench and reef now have room tone under their BGM.
  `tools/make_ambience.py` synthesizes two seamless loops (whole-cycle tones /
  circular filters, so both wrap without a click): an 8 s workshop drone + fan
  whir for Upcycle and a 14 s muffled current for Reef Rescue, shipped as 16-bit
  PCM. `scenes/amb_bench_hum.tscn` (−26 dB) sits in `upcycle.tscn`;
  `scenes/amb_reef_swell.tscn` (−24 dB) sits in `reef_rescue.tscn`. Both use the
  new shared `scripts/ambience_loop.gd` (`AmbienceLoop`) — the surf bed was
  refactored onto it too, removing the duplicate fade/loop code. Verified in-game:
  all three play on the Ambience bus, loop the full buffer (8 s → 176400 frames,
  14 s → 308700, surf 12 s → 264600), and the surf position kept advancing while
  the tree was paused.
- Ambience bus + slider: ambient loops and wildlife no longer share the SFX bus.
  `AudioManager` now sets up a fourth **Ambience** bus (send → Master), persists
  `ambience_volume` (default 0.7), and `play_sfx(sound, pitch, bus)` takes an
  optional bus. The surf bed, harbor cries and flock gull cries route through
  Ambience; sort/sale/portal feedback stays on SFX. The shared settings panel
  (`scenes/ui/settings_panel.tscn`) gained an "Ambience Volume" slider between
  Music and SFX, so the world menu and stats page both show it. Verified in-game:
  bus created at index 3, 0.7 → −3.1 dB, surf/harbor on it, slider reads 70%, and
  `set_ambience_volume(0.3)` moved the bus to −10.5 dB (then restored without a
  save write).
- Continuous surf bed for the world map: `tools/make_surf.py` generates a
  seamless 12 s wash (circularly filtered noise + periodic swell, shipped as
  16-bit PCM `sound/sfx/surf.wav`). `scenes/wm_surf_bed.tscn` lives in
  `world.tscn` as a dedicated `AudioStreamPlayer` (never the round-robin SFX
  pool), fading in over 3 s to −22 dB and looping the full buffer, and running
  with `PROCESS_MODE_ALWAYS` (later moved to the Ambience bus, see above). Verified in-game: playing/looping
  (loop_end 264600 = 12 s × 22050), volume reached −22, and the playback
  position kept advancing while the pause menu had the tree paused.
- Harbor ambience: the world map now has a dock-side voice of its own —
  `scenes/wm_harbor_ambience.tscn` (audio-only Node in `world.tscn`) plays a
  sparse, lower-pitched gull cry every 40–75 s (35% of calls draw a closer
  answer ~1–2 s later). The four flock gulls fill the gaps under normal motion;
  under reduced motion the flock freezes and goes silent, so this node is what
  keeps the dock audible. Routed through the Ambience bus, so the volume
  setting applies. Verified in-game: node present and configured, a
  forced call played `gull.wav` through the pool, and it still plays with
  reduced motion on.
- Reduced-motion audit: the remaining entrance/idle tweens now come to rest when
  the setting is on — main-menu mote drift and button rise, minigame briefing
  pop, NPC dialogue intro, run-recap lift, circuit-ring pulse (steady 0.75 ring),
  and portal pad glow/bob (fixed 0.62 glow). Verified main menu with the setting
  on: buttons/panel load at full alpha and scale one, no runtime errors.
- Stats page gains an "Era:" line — a scrap-journal read of where the save is
  on the island (Fresh Shore → First-Coin → Bench → Diving → Circuit →
  Trading → Pact → Steward), picked by what the save has actually done. Pure
  flavour, no numbers to game. Verified three branches in-game.
- Mature-market route advisor: the "Next:" hint and the glowing pad now flip
  to a pricing-maxed playbook once Market Contact is fully maxed — dives and
  early cash-outs over sort trips (prices maxed — dive deeper / cash in soon),
  with debris advice intact underneath. Verified across the threshold states;
  immature saves keep the old guidance exactly.
- Audio identity pass: the upcycle shift now closes on its own signature —
  synthesized `shift_complete` SFX (A4→E5 bell motif, mono 22050 Hz, decaying
  third harmonic) instead of the generic achievement chime. Upcycle already
  had its own BGM stem (`sound/bgm/upcycle.mp3`); the motif gives the panel
  its voice. Verified it plays clean in-game.
- Best-run stake on the pre-round briefing: the shared `MinigameIntro` card
  gained an optional "Stats" row (gold, hidden until set) — the upcycle bench
  shows "Best score: N · Runs finished: M", reef rescue shows "Deepest: N m ·
  Dives finished: M", and a fresh save sees "First shift/first dive — nobody
  holds the record yet." Verified empty and populated states in-game.
- Bench ghost best: the score readout now shows "Score: N (best M)" mid-run,
  and the moment the run passes the saved best a one-shot gold "NEW BEST — N!"
  callout fires with the same punch the combo milestones use. Fires once per
  run, skipped entirely on a fresh save (no record yet). Verified: crossing
  beats, second call stays silent, label shows the suffix.
- Economy end-check: three consecutive scripted circuit loops on a fresh
  sandbox banked +34$ each (19$ materials + 15$ circuit; bulk ×1.25 applied on
  a 7-unit material at +25% as expected), circuits closed normally, no script
  or debug errors surfaced. $32–34/loop median holds; guide.md unchanged.
  Player save restored afterwards.
- Endgame radio: after the Tidekeeper's Pact is funded, world NPCs mix rare
  mint-green pact gossip into their ambient bubbles (35% swap;
  "Saw the pact keeper pass by — good folk." et al.). Verified in-game — the
  lines interleave with the idle hum.
- Bottle lore epilogue cadence: funding the Tidekeeper's Pact AND reading all
  three base bottles makes a fourth, hidden bottle surface on the beach —
  "The Pact's Reply" from the tidekeeper. Reading it grants a new achievement
  (THE PACT'S REPLY) and the HUD flips to "✦ The Pact is Kept". Catalogue now
  22. Verified in-game: spawns only when the pact arc is complete, grants, flips HUD.
- Legendary celebration for endgame badges: the banner now has a third accent
  tier ("legendary") — thick-rimmed dark-gold panel, brighter legend gold
  title, +0.25 chime. BENCH MASTER, REEF VETERAN, LOOP MASTER and
  KEEPER OF THE TIDE route to it automatically. Verified in-game (panel
  visible, 4 px legendary border applied, title/slot correct).
- Endgame hook: after ISLAND STEWARD there is now a chase — three new
  long-game achievements (BENCH MASTER 25 runs, REEF VETERAN 25 dives,
  LOOP MASTER 25 circuits) and a final money sink, the **Tidekeeper's Pact**
  (2500$, one-time: permanent +10 kg bag) sold in the shop and granting the
  KEEPER OF THE TIDE achievement. Catalogue now 21. Verified: purchase spends
  the 2500$, capacity grew 70→80, button locks to "funded", achievement
  unlocked, player save restored after the test.
- Balance pass 4 (payback audit, nothing re-priced blindly): re-derived every
  money/plasticity sink from the measured ~$32/loop median — Bag L1 repays in
  ~3 loops (best first buy, hence the new nudge), Market Contact L1 ~8 loops
  (L2/L3 intentionally long-game), circuit $15 is the ~47% guaranteed
  stabiliser, Patron 1500$ is the ~47-loop finish line, Charter priced by
  feel. Numbers now live in guide.md next to the pacing notes. No constants
  changed; the existing curve is honest.
- Fresh-save end-to-end QA sweep passed: tutorial chain advances step 1→5 and
  lands on DONE with the bottle nudge armed afterwards; the upcycle wind-down
  on an empty save shows a gold "SHIFT COMPLETE — No Reef Debris banked"
  panel instead of a red loss; the shop fires "Room for more?" on the first
  sale and persists `nudge_upgrade_shown`. Player save restored afterwards.
- Upcycle HUD shows the banked Reef Debris pile ("Reef Debris banked: N",
  red at 0, amber at ≤5) so the shift wind-down and the four-to-five warning
  are legible before the belt stops feeding. Verified all three tint states.
- Tutorial growth: one-shot **Room for more?** card after the first sale —
  names both bag-expansion routes (shop cash at the cost shown on the button,
  island-map trash). New save flag `nudge_upgrade_shown`. Also fixed the stale
  shop capacity line, which claimed upgrades cost trash while the button sold
  them for money; it now shows both routes and the live price.
- Upcycle "shift wind-down": the bench used to end the run the moment the
  debris pile hit zero, stranding half-sorted items on the belt. Now at 5
  Reef Debris a one-shot "N Reef Debris left" callout fires; at zero the belt
  stops feeding but the shift only closes once the belt is clear and nothing is
  in hand — a gold "SHIFT COMPLETE" panel (with its own body for the
  nothing-to-sort case) instead of a red loss. Verified via MCP (1 debris:
  exhausted but waits for the belt, clears, panel reads SHIFT COMPLETE with
  correct body and the "Bench Run № 1 — Belt Sorted" recap card).
- Two long-game achievements backed by the new run counters: BENCH REGULAR
  (10 Upcycle runs) and REEF REGULAR (10 Reef dives), catalogue now 17; the
  stats page gained a "Field log: N dives · M bench runs" line. Verified both
  unlock via exec and that the stats scene loads clean.
- Upcycle hand-off parity: bench runs are now numbered story chapters on the
  world-map card ("Bench Run № 1 — Hot Streak"), named by the run's peak streak
  (≥15 Golden Gloves, ≥10 Hot Streak, ≥5 Steady Hands, ≥1 Belt Sorted, else Belt
  Survived) and lead with "★ New personal best" when earned. New save key
  `upcycle_runs`. Verified via exec (score 42 → "Bench Run № 1 — Hot Streak").
- Mobile UI sweep: `DragScrollContainer` (mouse drag-to-scroll, finger-speed,
  threshold-gated so buttons still click, reduce_motion-safe) wired into the shop
  and stats guide ScrollContainers; touch targets ≥ 44 px on main-menu/stats
  buttons; money note 14 → 15 px. Verified scroll via synthetic drag events.
- Export pipeline verified: headless Linux debug build compiles, packs, launches
  with zero script errors; Web preset also builds clean (Godot 4.7.2 templates
  installed). Android preset untested (needs SDK).
- Ambient world-life pass 1: four gulls patrol ellipses over open water east of
  the island — two-frame wing flap, banking into the bob, desynced phases,
  frozen still under reduced motion (scenes/wm_gull.tscn + scripts/wm_gull.gd).
- Ambient world-life pass 2: additive sea-sparkle drift over the western water
  (46 particles, fade ramp, killed under reduced motion) and a rare synthesized
  gull cry (25–60 s per gull, pitch-jittered, honors the SFX bus volume).
- Ambient world-life pass 3: a distant fishing sailboat drifting slowly across
  the eastern horizon (fade in/out wrap, swell bob + heel, frozen under reduced
  motion; PIL-drawn placeholder, scenes/wm_boat.tscn + scripts/wm_boat.gd).
- Reef fairness pass: off-screen edge markers for fish flare red and swell/throb
  as they close in (proximity + depth-scaled shimmer, faster sine at higher
  depth); garbage markers stay calm yellow. Verified at 650 m (marker ff6b59).
- Reef telegraph pass: red wake blooms in a fish's lane at the bottom edge ~1.15s
  before it enters view; swells and fades, skipped under reduced motion.
  Verified (wake at y=624 under lane x=296, fading).
- Reef one-bump warning: soft red vignette breathes at the edges when a single
  fish bump remains before the limit; static dim under reduced motion.
  Verified (visible at 1 bump left, alpha oscillating).
- Reef summary payoff: dives beating the deepest-ever depth lead the summary
  with "★ NEW BEST DEPTH" and chime the achievement SFX. Verified (best 100→250).
- Reef payout breakdown: the summary card now itemizes the haul, any Deep Cache
  bonus, and "bag full −N kg" when the cap truncates — verified at 10 kg cap
  (40 kg haul → 1 banked, line reads "bag full: −39 kg").
- Reef recap framing: the world-map hand-off card plays as a story chapter —
  a dive number and named dive ("Dive № 1 — Mid-Water Haul") plus a "★ New
  personal best" line when applicable; new save key `reef_dives`. Verified.
- Balance pass 3 (measured, not guessed): three consecutive fresh-save loops driven
  end-to-end via MCP; median yield ≈ $32/loop ($17 materials + $15 circuit),
  Market Contact reachable in ~2–3 loops; kept prices, documented in guide.md.
  Tested with real portal warps (fresh-save welcome → tour → circuit ×3), save
  restored to player data afterwards.
- Tutorial one-shot ambient nudges: "Bag almost full!" at 85% hold (once per save,
  skipped while another card is up) and "Bottles on the shore" after the tour
  finale; verified both in-game.
- Main-menu postcard: one-time golden shimmer sweep on the first menu visit after
  closing an island circuit (flag `postcard_shimmer_played`; reduced-motion flash).
  Verified mid-sweep on a fresh save; player save restored after testing.
- Reef Rescue juice pass: depth-milestone banners (100/250/400/700/900 m, tied to
  the DEEP DIVE / TO THE ABYSS ladder) and a combo counter under the depth HUD
  that punches gold at every x3 milestone. Verified via exec (6 garbage → COMBO ×3,
  milestone fired at 100 m).
- FIRST-LOOP ECONOMY FIX (big one): sort grants were item_size units of material
  (15–40), so one correct sort tried to refill the entire 10 kg bag every time and
  everything else was silently rejected as "over inventory cap". Rebalanced grants
  to ~1–2 units per sort (bag fills in ~4–6 sorts) and decoupled belt-item visual
  scale from economy size. Also fixed _play_combo_feedback assigning modulate to a
  CanvasLayer (runtime error on every combo milestone) — it now punches the score
  label instead. Full fresh-save loop driven through REAL portals on the MCP:
  menu → welcome → move → dive (52 kg) → sort → sell → circuit completed ($15)
  → finale; active game time ~65 s (a human loop fits in ~3–6 minutes).
- Balance trace of the fresh-save loop (reef fish curve measured via randfn sampling;
  debris conversion audited). Upcycle spawn 3.5s → 2.75s so the bench stays busy;
  documented pacing in guide.md; fixed stale README claims (belt speed, spawn rate,
  bag capacity 10+10/level, depth-scaled reef spawn).
- Shop receipt stack right-aligned (fixed-width right-aligned labels; no more
  off-screen clipping); bulk sales punch; receipts reflow on expiry.
- Undo animation: REVERSED stamp + exiting receipt + red flashes + button punch;
  all-or-nothing undo with denial feedback, tooltip capacity hint, sort_bad sfx.
  (Undo was previously partial-restore but full-price clawback — now fair.)
- World HUD bag line pulses amber when near full (85%+), stronger at full;
  reduce_motion freezes the breath, tint remains.
- Main-menu world preview postcard (THE ISLE) with ambient motes.
- Step-by-step first-playthrough tutorial: TutorialDirector autoload + non-modal
  tutorial_hint cards; welcome → walk → reef dive → upcycle sort → shop sale →
  finale, persisted as tutorial_step and verified end-to-end on a fresh save.
  Fixed deferred spawn (hint used to parent to a dying scene during transitions).

# high priority
- Deep Cache copy & discoverability: the upgrade now always pays out, but the
  world-menu button still reads "Deep Cache (30 score) — bonus debris" and
  nothing tells the player the bonus survives a full bag. Reword the button (and
  the tier-upgrade line) to state the guaranteed payout, then verify the whole
  path end-to-end: buy with 30 score, upgrade a tier with 15×tier score, dive,
  and read the salvage on the summary card.

# medium priority
# (shimmer item promoted to high priority)

# low priority backlog
