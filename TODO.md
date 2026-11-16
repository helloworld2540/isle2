# Current project todo:

# done this pass
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
- (next) Reef Rescue polish: fish warning shimmer on the edge markers of fish
  that are close to the drone (depth-scaled), making near-miss dodges feel fair.

# medium priority
# (shimmer item promoted to high priority)

# low priority backlog
