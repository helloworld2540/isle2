# Current project todo:

# done this pass
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
- Economy end-check: with every sink and badge live, re-run three fresh-save
  circuits through MCP and confirm (a) ~USD 32/loop still holds, (b) the
  Room-for-more nudge and the wind-down flow don't break the tour, and no log
  errors appear.

# medium priority
# (shimmer item promoted to high priority)

# low priority backlog
