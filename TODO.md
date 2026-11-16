# Current project todo:

# done this pass
- Reef combo now persists: new save key `best_reef_combo` (longest single-dive
  pickup chain, schema-codec) tracks the peak chain at dive end and shows in
  the stats menu ("Best reef combo: N chain (×M multiplier)"). New achievement
  **RHYTHM OF THE REEF** (`reef_rhythm`, Reef Rescue, chain 9 pickups in one
  dive for a ×4 multiplier) added to the catalogue + predicate; capstone count
  auto-adjusts. Verified in-game (record_reef 11 → best sticks at 11, ×4 combo
  not lowered by a later 4-chain, predicate fires); smoke 44/44; player save
  restored (reef_garbage/reef_fish/dives/kg/combo all back to pre-test values).
- Island-circuit loop verified end to end on a fresh save: New Save → world →
  one visit to each station (`record_station_visit` ×3 in reef→upcycle→shop
  order) closes the circuit — `circuits_completed` 0→1, **+$15 circuit bonus**
  credited, visits cleared, 1 celebration queued, and the whole thing
  persisted to disk through the new schema-codec save path (file-level check:
  `circuits_completed: 1`, `money: 15` on disk). Player save restored.
- Two new one-shot NPC nudges complete the quest-loop tutorial arc:
  **Islanders about** (fires once per save on the first world visit after the
  tour while any resident is unmet — points at the trail walkers and their
  first-visit gifts) and **Someone needs a hand** (fires once when you first
  hold enough material for a turn-in — points at the quest tracker and the
  ★ glow; requires a prior visit, matching `active_tier`'s rules). Both wired
  through the 0.4 s NPC refresh cadence in `wm_npc.gd` and the one-shot
  deferred-queue pattern. Verified in-game end to end: meet card spawns with
  tour complete + unmet NPCs (`nudge_meet_shown` persists, quest nudge stays
  silent at 5 Polyethylene); with 8 Polyethylene and a "visited" Mara the
  quest nudge queues behind the meet card and fires on its dismissal
  ("Someone needs a hand", `nudge_quest_shown` persists). Player save
  restored; smoke test 44/44.
- Shop receipt/feedback stack extracted into a real component: sale receipts,
  undo exit-receipts, the REVERSED stamp and the punch/flash effects moved
  from the 600-line `shop_menu.gd` into `scenes/ui/receipt_stack.tscn` +
  `scripts/ui/receipt_stack.gd` (`ReceiptStack`, instantiated once in
  `_ready`); menu is down to 490 lines. Fixed a first-time parse error the
  extraction surfaced (`CanvasLayer` has no `get_viewport_rect()` — viewport
  size now comes from the window). Verified in-game end to end: sale →
  "SOLD Polyethylene x1 +2$" lands in the stack, undo → cash/materials rewind,
  "REVERSED" stamp + "UNDO Polyethylene x1 -2$" receipt spawn and reflow, and
  the first-sale nudge still fires. Smoke test: 44/44 green, save untouched.
- `game_state.gd` save codec refactored to a single schema table
  (`SAVE_SCHEMA`): every persisted `[key ↔ property ↔ default ↔ codec]` feeds
  `_write_save`, `restore()` and `reset()` — the three hand-mirrored blocks
  (which had drifted into ~330 lines with a real chance of key mismatch) are
  gone. Verified byte-identical round-trip of a real player save (md5 match
  after `restore()` + `flush_save()`), a full field-by-field dump after
  boot, and a `reset()` → `restore()` sweep; smoke test still 43/43.
- Fresh-save first-run regression audit (save set aside, game booted to a
  brand-new save, driven interactively end to end): main menu → New Save →
  welcome card ("Welcome to Isle 2") shows and arms the tour (`step 1`,
  "Take a stroll" hint), `tutorial_seen` persists; opening the bench with an
  empty Reef Debris pile ends the shift instantly with **runs staying 0**
  (empty-shift fix holds on a fresh save); no errors anywhere in the
  sequence. Player save restored untouched (`.player` copies both round-trip).
- New post-tour nudge: **Oops — bulk sale?** points at the Undo last sale
  button, fired once per save on the player's first bulk sale (Sell 5+ /
  Sell All, `bulk` flag from the ledger). Verified in-game end to end: a
  bulk sale with the save's `nudge_upgrade_shown = false` shows "Room for
  more?", dismissing it immediately raises the undo card via the new
  deferred-nudge queue, `nudge_undo_shown` persists, and recalling the
  nudge afterwards stays silent. Player save restored.
- Deferred-nudge queue: nudges raised while another card or a modal owns the
  screen used to silently drop despite their one-shot flag being safe; the
  first bulk sale proved it (the undo card could never appear once the
  first-sale card was up). The director now keeps a single-slot pending
  nudge that fires on the next card dismissal — a strictly better deferral
  for every nudge, no flag semantics changed.
- BGM weight cut ~24 MB: menu (27→18), shop (14→7), reef (9→4), ambience
  (6→3), upcycle (4→2) re-encoded to 160 kbps CBR, durations identical, ID3
  tags preserved (Kevin MacLeod attribution intact), world.mp3 already 162
  kbps untouched. Web pck rebuilt: 80 MB → 55 MB. Originals live in git
  history; smoke test still green (43/43), save untouched.
- Export presets no longer ship dev artifacts: Web/Android/Linux all exclude
  `addons/`, `tools/`, `export/`, `opencode.json` and `scenes/world.tscn.bak`
  (the Godot MCP addon alone was 75 packed files). Web rebuilt clean — 354
  files packed (was 439), no dev paths in the pack; Linux rebuilt clean the
  same way. README exporting section updated.
- `gull.wav` size fix, done non-destructively: the externally-restored real
  recording (14.5 s 48 kHz 24-bit stereo, 4 MB) is preserved in git history
  and in `/tmp/opencode/gull-original-4MB.wav`; the committed working file is
  now the two strongest cries extracted as a 0.9 s mono 16-bit 48 kHz one-shot
  (4.70–5.60 s window, 8 ms in / 30 ms out fades, 86 KB — same order as the old
  synth). Verified in-game: imports as a mono `AudioStreamWAV`, 0.9 s, plays on
  the Ambience bus. The 4 MB original remains available in commit c8274e1 if
  its provenance ever checks out clean.
- Headless scene smoke test added (`tools/smoke_test.gd`): link-checks every
  `ext_resource` path in every scene (and in referenced `.tres` files) and
  instantiates each of the 43 scenes under a bare `--headless` SceneTree;
  exit code = failure count. Negative-control verified (a dangling script ref
  is caught as `[FAIL] missing`). All 43 scenes pass and the run leaves the
  player save untouched. Documented in README under "Verifying".
- Reef dive phantom runs: a dive that reached neither a pickup nor a fish
  bump was counted as a dive — `reef_dives += 1`, a "Dive № N" recap card,
  depth-best credit, up to 1 kg free debris. Now a no-interaction dive shows
  the summary panel with "No pickups this dive." but banks nothing: no
  counter, no depth best, no recap, no haul (modeled on the bench's
  empty-shift rule). Verified in-game: open → return immediately → dives
  stay 0, `last_run` empty, best depth untouched; a real 5 kg dive records
  (dives 1, debris +5, "Dive № 1 — Shallow Sweep" queued). Player save
  restored after testing.
- Empty-shift phantom run fixed: opening the bench with a dry Reef Debris
  pile auto-ended the "run" on the first frame and banked a 0-score shift
  (`upcycle_runs += 1`, a "Bench Run № N" recap card, achievement progress) —
  reproduced in-game via the MCP harness (fresh save, empty pile, entering
  `upcycle.tscn` recorded a run without a single item spawning). Now a shift
  that never fed the belt (`_items_fed == 0` and no score/sorts) shows the
  same "No Reef Debris banked" panel but banks nothing: no run counter, no
  streak, no recap card, no achievement credit. Verified both paths in-game
  (empty pile → runs stays 0 and `last_run` stays empty; armed debris →
  belt spawns and drains normally). Player save restored after testing.
- World-menu layout pass settled (the "parallel layout pass" the reduced-motion
  item was waiting on): the pause card is now a proper modal — CenterContainer
  + 880 px-min Card on a 24 px screen margin, its own StyleBox set
  (card/section/upgrade), a Header row (title + live upgrade status), an
  ACTIONS column (resume / save & quit) beside an infobox, and a **Settings
  view** that swaps out the upgrades + progress sections so the card never
  outgrows a 1152×648 screen (button reads "Back to upgrades" while open).
  Pause joins the `ui_modal_card` group (the same handshake minigame briefings,
  NPC dialogue, confirm panels and the welcome guide use), so the tutorial
  director defers step cards instead of stacking them on the pause overlay,
  and achievement toasts no longer fire underneath it either.
- Notification toasts moved into a bottom-centre lane: full-width band 24 px off
  the edge, 18 px type with a dark outline for legibility over bright water,
  and they lift clear (card height + 12 px) above any visible bottom-centre
  card — the tutorial step hint registers in `hud_bottom_card`, joining the
  shared 24 px margin layout convention (tutorial hint rebuilt on
  Margin/Column; welcome guide, minigame briefing, all modal cards centered
  on a full-rect CenterContainer).
- Reef + Upcycle HUD labels grouped into `UI/HUDStats` VBoxes (20 px type,
  anchored at the 24 px safe margin); minigame briefing rebuilt as a centered
  620 px modal on the same margin grid, dim 0.6, matching the welcome guide.
- Reduced motion covers the world-menu open fade (was the one outstanding RM
  gap): under RM the card simply appears; off-RM the 0.16 s fade runs.
  Verified both paths in-game. Verified end to end: menu opens/pauses/joins
  the modal group, settings swaps both ways, all 16 touched scenes load +
  instantiate in-game, HUD paths resolve, briefing dismisses, toasts spawn
  bottom-lane and auto-expire. Player save untouched (restore pattern kept).
- Asset hygiene: `sound/sfx/gull.wav` was silently replaced with a 14.5 s
  24-bit stereo 4 MB real recording (60× oversized, undocumented, unknown
  provenance); restored the committed synthesized cry the docs describe and
  backed the recording up to /tmp/opencode/isle2-backup/gull-realrecording-4MB.wav.
- Upcycle bar tooltip: the world HUD's "Upcycle" bar now reads as progress
  toward the next Deep Cache purchase (it counts down to the score price).
- Reduced-motion coverage for the pop-in punch: the shop "SOLD ... (bulk)" receipt
  punched with a scale burst on every bulk sale (and every score popup using
  `FloatingText.punch_scale`). The scale burst is now skipped under **Reduce
  motion** (the card appears at its resting size, fade intact). Verified
  headlessly: RM on → `scale = (1, 1)`, RM off → `(1.35, 1.35)`. Save restored.
- Deep Cache tutorial coverage: added a one-shot **Deep Cache** nudge
  (`nudge_deep_cache_shown`, same persisted/defer-while-a-card-is-up design) that
  fires once the player can afford the 30-score unlock and points at the
  score-priced purchase at the island menu. Verified in-game: with the tour
  complete, DC unowned and score 35 the card spawns with title "Deep Cache",
  repeat calls are suppressed, and the flag persists; the world HUD fires it
  when `upcycle_score >= 30`. Save restored.
- `upcycle_score` semantics: it was a **lifetime bank** on the reef side
  (`upcycle_score += combo`) but `record_upcycle` **overwrote** it with the
  bench run's score, so diving for score was silently discarded and Deep Cache
  spending was meaningless (each bench run refilled the pool). Now bench runs
  also `+=` into the bank; `best_upcycle_score` still tracks the best single
  run for the recaps. Added `GameState.get_deep_cache_cost()` (30 first, then
  15×tier) and re-pointed both HUD "Upcycle" bars (world progress + world
  menu) at progress toward the *next* Deep Cache purchase instead of
  value-vs-best, which would peg. Verified in a headless run: 12 + 8 = 20,
  purchase blocked at 25, succeeds at 40 (40→10, cost→15), upgrades gate on
  the 15×tier price. Save restored.
- Achievement id collision fixed: `achievement_catalog.gd` declared **two**
  entries with `id: "tide_keeper"` — the Tidekeeper's Pact (Shop) and the
  "found every message" badge (Island) — and the `is_met` match had a dead
  duplicate case, so the bottle-collection badge could never be earned on its
  own (it just mirrored the Pact) and the stats page's count was off by one.
  Renamed the bottle badge to `tide_messages` (title unchanged) and gave it a
  live predicate; added it to the banner's legendary tier. Verified headlessly:
  the catalogue now has 22/22 unique ids, `tide_messages` is false at 2 bottles
  and true at 3, and `tide_keeper` still tracks the Pact.
- World-menu touch pass: the island-map **upgrade buttons** (Move / Range /
  Deep Cache / its tier-up / Inv Cap) plus the **Settings** toggle all rendered
  at 41 px, just under the 44 px touch guideline the shop and minigames follow.
  Raised all six to 44 px in `scenes/world.tscn`, and the **Reduce motion**
  checkbox in the shared settings panel (`scenes/ui/settings_panel.tscn`) to
  44 px too. Verified in-game: all six buttons report size.y = 44 and the menu
  infobox (692×419) still fits inside 1152×648. Player save restored.
- Deep Cache copy: the world-menu buttons now explain the guaranteed payout —
  unowned reads "bonus debris, never wasted", owned shows "OWNED · Tier N (+X kg)"
  and the upgrade shows the next tier's per-run kg ("Tier 2 — 15 score
  (+10 kg/run)"). Verified end-to-end in-game: buy with 30 score (60→30), the
  upgrade enables and reaches Tier 2 (30→15), and the panel stays inside
  1152×648. Player save restored.
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
- (none outstanding.)

# medium priority
# (shimmer item promoted to high priority)

# low priority backlog
- (none outstanding.)
