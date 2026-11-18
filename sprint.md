
## 2026-11-18 — The courier's gratitude (the post is all read)
- `scripts/wm_courier.gd`: once THE LAST LETTER is read (checked off the live
  GameState at runtime) the Eel Run flyby comes sooner — first pass 4–9 s and
  a 16–34 s re-arm, versus the base 8–20 / 30–65. `force_gratitude` is a
  debug hook for the harness. No card, no prompt: the sea just keeps the
  keeper company.
- `scenes/world.tscn`: Oda's `pale_courier` beat (dropped in the rollback) is
  restored, and Oda + Tom notice THE REGULAR; Oda notices THE LAST LETTER.
  The courier arc's closing badges now have islander voices.
- `tools/courier_flight_test.gd` asserts the grateful intervals; green.

## 2026-11-18 — CardQueue: one voice at a time, island-wide
- New `scripts/ui/card_queue.gd` (`CardQueue`, a static RefCounted): every
  popup asks the same lane for the screen and either activates at once or
  waits until the card ahead closes. Modals (welcome guide, conversations)
  jump ahead of ambient cards (hints, achievement/tide banners, run recaps);
  cards owned outside the queue (pause menu, minigame briefing, confirm
  panel) hold the lane through the `ui_modal_card` group.
- Wired: `tutorial.gd` (pauses the tree only once it is on screen),
  `npc_dialogue.gd` (ducks music/joins the group on activation, not on
  creation), `tutorial_hint.gd`, `achievement_banner.gd` (parks its entry in
  `_pending` and hands it back on tree exit), and `run_recap.gd` (presents and
  releases on activation / fade-out). `wm_npc.gd` ignores keys for a
  conversation that is still queued.
- Fixed two real bugs the harness found: `_prune()` tested `is Node` before
  `is_instance_valid` (throws on a freed instance), and `_drain()` assigned a
  possibly-freed Variant to a typed `Node`. Validity is now checked first and
  the drain value is untyped.
- `tools/card_queue_test.gd`: 17 checks over inline probe cards — immediate
  activation, FIFO waiting, modal priority, withdraw, foreign-modal blocking,
  duplicate-request no-op, waiter cancellation. 0 failures; wired into
  `all_audits.sh`, catalogued in `tools/README.md`.
- Docs: README (Card lane), guide.md (Screen layout & toasts).

## 2026-11-18 — BGM cache evicts on switch (mobile memory)
- `AudioManager.play_bgm` now keeps only the incoming track cached and evicts
  the previous one when the bed changes — otherwise every scene's loop pins
  its MP3 in RAM for the whole session (~45 MB across menu/world/upcycle/shop/
  reef), which mobile budgets cannot absorb. SFX streams are small and stay
  cached. `stop_bgm` clears the path too.

## 2026-11-18 — The world-courier flyby: back on the water
- The `WorldCourier` node is back in `scenes/world.tscn` (position 300, 1050,
  `res://scenes/wm_courier.tscn`), so the Silverfin crosses the strait on Eel
  Run days — a slow, deliberate flyby that fades in, sweeps, and re-arms on a
  30–65 s timer. It frees itself on every other tide and under reduced motion,
  and it never spawns a card or a chime; the registry earns its own voice.
- `scripts/wm_courier.gd` gained a `force_tide_key` export so the harness can
  stand the scene on any tide without touching the calendar, and it now looks
  up `GameSettings`/`AudioManager` at runtime through `/root` instead of by
  bare autoload name — the tool harnesses compile without those identifiers.
- `tools/courier_flight_test.gd` walks the whole flyby: wrong tide frees it,
  Eel Run survives and starts hidden, a pass fades in and sweeps, the timer
  re-arms on the long interval, and reduced motion skips it. 0 failures.
- `tools/all_audits.sh` regains the harness; `tools/README.md` catalogues it.

## 2026-11-18 — Reef Registry button: its own count, like the ledger
- The stats page's Reef Registry button now advertises its own completion —
  "Reef Registry (n/5)" — and turns gold at 5/5, the same way the Tide Ledger
  button does. No need to open the page to know where the reef stands.
- The overlay's legend line reads "every species you have bumped into — n/5 —
  tap to read what you know", refreshed on open.
- `scripts/stats_menu.gd`: `_refresh_registry_button` + `_refresh_registry_legend`,
  wired once in `_connect_signals` and called from `_update_stats_display` and
  `_open_registry`. The scene keeps its `RegistryLegend` label
  (`unique_id=300000022`).

## 2026-11-18 — 1.3.0 sealed across all three platforms
- Version bumped everywhere in lockstep: Android preset (versionName=1.3.0 /
  versionCode=4), main-menu stamp ("v1.3.0"), About page ("Version 1.3.0"),
  README, RELEASE_NOTES, RELEASE_CHECKLIST, guide.md version history.
- `tools/export_gate.sh --re-export` green: Linux, Web and Android all
  rebuilt at HEAD. Signed APK badging verified (versionName=1.3.0,
  versionCode=4, minSdk=24, targetSdk=36, label `Trash Island`). Fresh-clone
  proof re-run clean at HEAD (cold import → Linux export → headless boot with
  an empty log).
- Ships on top of 1.2.0: the Silverfin, THE PALE COURIER (the 45th badge),
  weighted reef spawns (the shark a spice, the courier rare), The Filled
  Almanac, the quiet harbor, the courier's chime, the Courier's Wake and
  The Last Page cards, the front door remembering, the first keeper's margin
  notes, and THE WHOLE SEA closing the chorus across every islander.
- Concurrent loop kept working past the seal (the 1.3.0 tag is a HEAD seal,
  not a frozen tree) — HEAD at the time of sealing is c1167f0.

## 2026-11-18 — THE KEEPER'S STAR: the island's epilogue, earned
- A hidden **sixth starfish** lives at the far point east of the watcher
  (`scenes/wm_keeper_star.tscn` + `scripts/wm_keeper_star.gd`). It frees
  itself for any keeper who has not earned ISLAND STEWARD, it is not counted
  toward the STARLIGHT five-star set, and collecting it delivers the island's
  last card: a hooded-keeper dialogue from the island itself, a low bell,
  a floating "+50$" callout, a bright indigo spark burst and the 43rd badge,
  THE KEEPER'S STAR. Save flag `keeper_star_found` (schema-persisted, one
  per island, paid exactly once). THE KEEPER'S STAR achievement appended to
  the catalogue on the Hidden track (the capstone explicitly excludes it —
  no circular dependency).
- Deeds column gains "The keeper's star: found."
- Sprite painted in-repo (`sprites/keeper_star.png`, indigo body with one
  warm gold point). Distinct palette from the tidepool starfish.
- `tools/keeper_star_test.gd` asserts the scene loads, the catalogue entry
  is real and on the Hidden track, the capstone does not depend on the star,
  and the save schema carries the flag; wired into `tools/all_audits.sh`.
  Smoke 51/51. Full audit board green.
- Docs: guide.md (star section + 43rd badge version-history entry), README
  (43 achievements, build/verify notes, epilogue in the capstone bullet),
  PITCH.md (living arc carries the epilogue star).

## 2026-11-18 — THE FILLED ALMANAC: the book's own prize
- Once `tides_logged.size() >= 4` the stats page grows a gold-rimmed
  **The Almanac** button (`stats_menu.tscn`: `AlmanacButton`, unique_id=300000050,
  plus `AlmanacOverlay`, unique_id=300000051 — Day0..Day6 rows, Close, gold
  title). Hidden otherwise; ESC closes it like the other overlays.
- Opening it fills the next seven days of the sea's rotation
  (`TideReport.for_day(day_index + i)`): today in sea-foam white, the rest
  below — "Glass Calm · tomorrow — debris drifts loose", and so on. The
  dockhand's $15 tip is untouched — this is the almanac's prize, not a fee
  bypass.
- Under **Hide the tide** the card opens to one quiet line instead: the sea
  keeps its own counsel, even for its keeper — consistent with every other
  tide surface going silent.
- guide.md: Quick reference entry, almanac section paragraph (and removed a
  duplicated bullet I found there). Smoke 51/51, ALL-AUDITS PASS.
- Caveat: a concurrent loop committed the `.tscn` half first
  (ec72ce2); the committed state on HEAD carries AlmanacButton/AlmanacOverlay
  plus the Silverfin/PALE COURIER work, verified consistent by a fresh
  ALL-AUDITS PASS.

## 2026-11-18 — 1.2.0 sealed across all three platforms
- Version bumped everywhere in lockstep: Android preset (versionName=1.2.0 /
  versionCode=3), main-menu stamp ("v1.2.0"), About page ("Version 1.2.0"),
  README, RELEASE_NOTES, RELEASE_CHECKLIST, guide.md version history.
- `tools/export_gate.sh --re-export` green: Linux, Web and Android all
  rebuilt at HEAD. Signed APK badging verified (versionName=1.2.0,
  versionCode=3, targetSdk=36, label `Trash Island`). Fresh-clone proof
  re-run clean at HEAD (cold import → Linux export → headless boot with an
  empty log).

## 2026-11-18 — THE WHOLE SEA: the hidden 44th badge
- All eight bottles read — the seventh washes up after THE KEEPER'S STAR,
  and reading them all earns the hidden 44th badge. Legendary banner, Oda
  notices, capstone exclusion like the star, world HUD bottle line flips to
  "✦ The Whole Sea". The first keeper's margin notes also rotate across the
  two minigame briefings (two voices: BENCH and WATER), and the world dock
  goes quiet once the sea finishes talking.
- See the e22818a commit for the ledger/registry pins and the world HUD flip.

## 2026-11-18 — Far-point beats: all five islanders notice the watcher
- The guide names THE FAR POINT as noticed by every named islander, but three
  of the five `milestone_beats` dictionaries in `scenes/world.tscn` were
  missing the `far_point` entry — Mara, Tom and Kai never spoke of the
  watcher even though the rumour started with Mara and Kai already knew not
  to restock it. Nina and Oda had the line; the other three were silent.
- Added the beats, each in that NPC's own register:
  - **Mara** — "You caught the one I told you about. I raised you right,
    didn't I? Nobody has ever caught him before."
  - **Tom** — "Oda sees him. I keep to my fishing. But I saw the look on your
    face when you came back — you saw something too."
  - **Kai** — "I do not stock the far point — never a good day out there. But
    word travels, and the shelves have been lighter since you came back. You
    went there. You came back."
- New `tools/npc_beat_audit.py`: parses `world.tscn`'s NPC overrides and
  asserts every beat id is a real catalogue achievement, that all five NPCs
  carry a `far_point` beat, and that no (NPC, beat) pair is duplicated. Wired
  into `tools/all_audits.sh`. 0 failures.
- Smoke 50/50, full audit board green. Docs parity: the roster in guide.md
  already matched the code — the code was the one that lagged.

## 2026-11-02 — NPC ambient bubble jitter pass
- NPC idle bubble cadence now jitters ±0.5s over a 3.5-7s base to avoid predictable loops.
- Fade-in tightened to 0.14s for a snappier but gentle bubble entrance.
- Duplicate _ambient_next declaration cleaned up and import smoke passed clean.
- New `scripts/ui/notification_queue.gd` HUDNotificationQueue: queued toast controller with stacking Z-index, fade in/out, duration, automatic sequencing.
- BGM crossfade ramps tightened to 0.22s (0.09s reduced motion).
- Headless import and parse smoke passed.
- Added WorldNPC scene (wm_npc.tscn) + script (wm_npc.gd) with idle pulse, dialogue panel, first-visit trash reward, persistent visited state.
- Placed Mara and Tom NPCs on world.tscn.
- Fixed game_state.spend_trash warning-as-error (min inferred Variant).

## 2026-11-01 12:28 — NPC quest & dialogue branches pass.
- WorldNPC now supports repeat-visit lines, quest-complete lines, and an optional turn-in quest (consume trash, reward trash).
- Mara: turn in 8 Polyethylene -> 3 Glass. Tom: turn in 6 Nylon -> 4 Polypropylene.
- Name labels reflect visited (✓) and quest-complete (★).
- Fixed NPC scene connection; headless import clean.

## 2026-11-01 12:30 — Main-menu continue summary thumbnail polish.
- Expanded Continue summary to include best fish, best streak, and lifetime earnings in a compact thumbnail-style layout.

## 2026-11-01 12:43 — NPC tier-2 quests + parser cleanup.
- Added tier-2 turn-in quests for Mara and Tom.
- Repaired wm_menu.gd broken progress-bar scaffolding; import clean.

## 2026-11-01 12:55 — NPC polish + Kai shop-themed quests.
- Added third NPC (Kai) near world center; two-tier Glass/Polyethylene quests.
- Tile-name cleanup trailing; headless import clean.

## 2026-11-01 13:46 — World cleanup + player polish.
- Removed stray empty TileMapLayer from world.tscn; grouped NPC instances under NPCs node.
- Portal pulse overshoot amplitude ticked for more juice.

## 2026-11-01 14:54 — NPC sprites + portal/HUD polish.
- WorldNPC now loads sprites/wm_npc/npc1–4 via npc_sprite_index and hides primitive Body.
- Portal pulse extra overshoot, idle label bob; guarded against transition reentry.
- WorldProgress HUD raised layer, stronger transparency and border.

## 2026-11-01 15:00 — Sprint continuation polish.
- NPC progress above-head labels hardened to reuse scene node and update live.
- Portal/pulse/juice and NPC sprite bob passes.
- WorldProgress HUD transparency/border and z layer pass.

## 2026-11-01 15:05 — Reef spawn polish + runtime check.
- Reef spawn fade-in (transparency + scale back-ease) already in place; verified headless runtime.
- Desktop NPC/sprite/progress systems stable.

## 2026-11-01 15:23 — Quest label z polish.
- Quest progress labels raised z order and are guaranteed visible over NPC sprites.

## 2026-11-01 15:25 — Sprint closure.
- TODO marked NPC repeat-visit flavour variants complete.

## 2026-11-01 15:28 — Pause menu responsive polish.
- Tightened pause width clamp and added viewport size tracking.
- Basic vertical anchor fallback for small viewports.

## 2026-11-01 15:55 — Audio + cleanup pass.
- Generated real WAV SFX/BGM placeholders in sound/sfx and sound/bgm; AudioManager already loads .wav.
- Fixed shop_menu double UI creation; WorldProgress duplicate layer removed.
- Hardened reef escape (ESC) to record reef result and debris.
- Polished world pause upgrade panel styling and content cost labels.

## 2026-11-01 16:18 — NPC presentation polish.
- Reduced NPC sprite scale from 0.62 to 0.46 and measured all four exported pngs so the billboards fit the tile-based world map.
- Repositioned NameLabel and QuestProgress labels dynamically above each sprite, preventing overlap with the sprite and keeping progress readable.
- Removed stale player/upcycle console debug spam.
- Updated TODO to mark NPC sprite pairing polish complete.

## 2026-11-01 16:28 — Portal autosave + pause anchoring
- Portal transitions now write the current player position into the existing save file before changing scenes, so Continue restores the last explored spot even when pause was not used.
- Pause menu max width/clamp recomputed from the actual viewport with a 720p-safe anchor fallback.

## 2026-11-01 16:35 — ReefEscape consistency pass.
- Unified Return-to-Map (button and ESC) through one `_leave_to_map()` flow to avoid duplicate score/debris recording.
- Added `running` guard so ESC or a second click cannot double-submit after exit starts.
- Deep Cache debris bonus applied once.

## 2026-11-01 17:41 — Sprint polish consolidation.
- Reef debris credit, ESC NPC dismissal, shop Reef Debris sink, speed-scaled upcycle stepping all landed and import-verified.

## 2026-11-01 18:35 — Sprint polish continuation
- World map pause menu now plays BGM and cycles idle tracks (world/ambience/world/reef) every 18s (respects reduced motion).
- Deep Cache now scales per tier: reef debris bonus = 5 * tier; upcycle score can upgrade tier cost 15 * tier.

## 2026-11-01 18:38 — Inventory capacity sprint pass
- GameState now caps total inventory at 30 + 15 per level; add_trash_type returns accepted count.
- World map pause panel exposes "Inventory Cap" upgrade using the same trash currency.

## 2026-11-01 18:41 — Cap feedback pass
- Reef Escape now reports how much debris was lost to the inventory cap.
- Upcycle now notifies when a sorted item is dropped over the cap.

## 2026-11-01 18:48 — HUD polish pass
- `wm_progress.gd` now surfaces live inventory total/capacity and per-material counts in a compact label, plus the summary line.

## 2026-11-01 18:53 — NPC safety pass
- Quest turn-in buttons disable when the expected reward would exceed current inventory headroom.
- Turn-in now surfaces partial reward gains with an "inventory cap" message when applicable.

## 2026-11-01 18:55 — Inventory UI polish pass
- Pause-menu inventory cap button turns red when inventory is at/over capacity.

## 2026-11-01 18:57 — UI capacity indicator
- World menu now shows inventory full/heavy status with colorized warning.

## 2026-11-01 19:04 — Pickup sparkle pass
- Reef Rescue now spawns short-lived sparkles in item color on each pickup for extra game feel.

## 2026-11-01 19:12 — Audio polish pass
- `AudioManager.play_sfx` now accepts a pitch scale and applies subtle randomization for juicier feedback.
- Shop sells (1.03) and upgrade purchases (1.05) use the new parameter.

## 2026-11-01 19:15 — Main-menu ambient polish
- Added looping ambient dot motion layer behind the menu summary for softer, more alive visual feel (respects existing randomization).

## 2026-11-01 19:22 — Combo feedback polish
- Upcycle now pulses the UI on combo milestones to make high-streak play feel more satisfying.

## 2026-11-01 19:30 — Documentation pass
- Added concise README.MD with engine/runtime, run/test paths, smoke guidance, and asset notes.

## 2026-11-01 19:42 — Reef fish penalty + Deep Cache scaling pass
- Reef rescue now treats fish contact as a penalty: 3 bumps triggers a game-over summary screen crediting debris and returning to map.
- Deep Cache debris bonus scales with inventory-cap upgrade tier (+3 per level).

## 2026-11-01 19:45 — Upcycle combo audio/visual polish
- Sort SFX pitch now scales with current streak; wrong sort/burn use lower pitches.
- Correct sort spawns bin sparkle particles; combo milestone feedback retriggered.

## 2026-11-01 19:48 — Main-menu summary inventory totals
- Continue summary now lists per-material inventory totals.

## 2026-11-01 19:50 — Pause menu auto-refresh on toggle
- Opening the world pause menu now refreshes upgrade UI and status text.
- Fixed indentation parse error introduced in toggle.

## 2026-11-01 19:52 — Main-menu summary fix
- Corrected inventory totals formatting for parse error; added helper.

## 2026-11-01 20:11 — Reef game-over juice + shop tips
- Reef Rescue now shakes camera and spawns confetti on fish-bump game over.
- Shop menu surfaces full/heavy/normal inventory tips.
- Pause panel typography pass (status/summary labels) and tip on pause menu.

## 2026-11-01 20:17 — Main-menu entrance + pause toggle guard
- Added hero entrance animation (fade/scale) for main-menu buttons/summary.
- Added reentrancy guard + focus handling to world pause toggle.

## 2026-11-01 20:18 — Inventory full toast pass
- Reef game-over now surfaces "Inventory full — sell trash" toast when no debris can be credited.

## 2026-11-01 20:22 — Pause menu polish
- World pause menu upgraded with tighter typography + upgrade sparkle bursts, reentrancy guard, and focus handling.

## 2026-11-01 20:32 — Upcycle belt bob + portal cues pending
- Added animated trash-item bobbing on conveyor belt.

## 2026-11-01 20:39 — Reef debris combo multiplier
- Reef Rescue now awards a combo multiplier based on consecutive garbage pickups (every 3 adds +1), displays as xN in pickup popups.

## 2026-11-01 20:41 — Reef debris combo multiplier
- Reef Rescue now tracks rapid debris pickups within 2s and multiplies debris credit (x2/x3) with scaled sparkles and SFX pitch.

## 2026-11-01 20:48 — Shop receipt toast
- Shop now spawns a floating "SOLD <material>" receipt on one-off sales.

## 2026-11-01 20:57 — Sprint cycle report (README + portal + upcycle banner)
- Rewrote README.MD to introduce Isle2: engine/runtime, loop, key areas, assets, autoloads.
- Portal hover: pad scales up on body enter and resets on exit; ping marker preserved.
- Upcycle: spawn streak banner "FIVE ON THE BELT!" with scale bounce when 5 items on belt.

## 2026-11-01 21:02 — Sprint cycle report
- Upcycle wrong-sort screen shake added (reduced-motion guarded).
- NPC quest turn-in SFX now scales pitch slightly by tier.
- World pause menu now fades in smoothly when reduced motion is off.

## 2026-11-02 16:30 — Upcycle/Reef priority pass
- Upcycle spam spawn interval starts 5s then gradually tightens to 1.5s.
- Removed wrong-sort and belt-burn score punishment; feedback remains.
- Reef Rescue now grants 1 kg per garbage and auto-takes game over closure when capacity is full.
- Updated guide/help text and docs to match.
## 2026-11-02 (inventory pass)
- Inventory base expanded to 60 kg; each upgrade level costs 6 + 3× current level and adds 20 kg capacity.
- HUD/progress labels updated to reflect new weights and labels.

## Summary snapshot
- Upcycle spawn gating and scoring polish implemented and validated.
- Reef rescue tied to weight/capacity with auto-exit.
- Inventory details/HUD refreshed while maintaining save compatibility.

## 2026-11-02 18:11 — Upcycle recycled counter + minigame intro expansion
- Upcycle UI now tracks Recycled total and per-material counts, plus live belt count.
- Upcycle and Reef intros now explain mechanics, scoring, and controls clearly.
- Reef intro clarifies garbage -> Debris -> Upcycle recycling path.
- Headless import/runtime smoke passed.

## 2026-11-02 18:12 — Minigame intro expansion & polish
- Enlarged minigame intro panel with larger title, line text, button, and spacing.
- Added NPC dialogue typewriter effect (reduced-motion aware).
- Headless import smoke successful.

## 2026-11-02 18:51 — Weighted inventory refactor stable
- spend_trash and add_trash_type now operate in weight units.
- Fixed strict Variant parse error in spend_trash.
- Headless import and startup smoke passed.

## 2026-11-02 18:53 — Documentation refresh
- Rewrote guide.md for weighted inventory, shop controls, and upgrade math.

## 2026-11-02 18:55 — NPC dialogue personality pass
- Mara now muses about glass economy and tidy shores.
- Documentation refresh ongoing.
- Runtime/import smoke clean.

## 2026-11-02 20:10 — BGM transition polish
- `AudioManager.play_bgm` now caches the selected track and fades between tracks (0.28s) while respecting reduced motion (0.12s).
- Avoids repeated restarts when re-entering scenes and stops smoothly when a track is unresolved.
- Headless import smoke passed (no parse errors).
## 2026-11-02 — Upcycle grabbed-trash display & deposit guidance
- Fix upcycle trash grabbing so the grabbed trash displays above the player, and over the matching deposit bin when a nearby bin exists.
- Arrow indicator now points toward the correct bin within a 3-tile radius.
- Headless import smoke passed (parse clean).

## 2026-11-02 20:12 — Upcycle held item polish pass
- Carried trash now z-orders above scene while held; arrow pulses for visibility.
- Bobbing retained while held and near-deposit; deposit hover lifts trash slightly.

## 2026-11-02 20:13 — Audio/UI micro-polish
- Reef pickup SFX pitch scales slightly with combo multiplier.
- Guide corrected to current weighted inventory capacity.

## 2026-11-02 20:15 — Reef pacing polish
- Reef spawn interval now gradually tightens from 0.8s down to a 0.32s floor as depth increases for rising pressure.
- Import/runtime smoke clean.

## 2026-11-02 — Quest reward sparks + NPC polish
- NPC first-visit turn-in now sparks CPUParticles on reward.
- NPC dialogue pacing polish pass landed and verified (import clean).
- NPC typewriter pacing tightened to 0.018s/char (capped 1.3s) for livelier but readable dialogue.
- Audio jitter already provided by play_sfx.
- Hunted entry removed from TODO; runtime smoke clean.
- PITCH.md created (tagline, core loop, pillars, target, status, human-needed assets).
- main_menu: StatsButton moved into SaveSummaryPanel as "More stats → " affordance that opens stats_menu; original sidebar StatsButton hidden.
- settings_ui: removed dangling _refresh_feedback call after reduced-motion toggle (now persists cleanly).
- Headless import/runtime smoke clean.
- Restored missing `_apply_npc_sprite()` function declaration to fix parse error and allow NPC sprite loading.

## 2026-11-02 — Audio routing + main menu path fix
- Added dedicated SFX audio bus routed through Master; play_sfx now uses SFX bus.
- Implemented get/set SFX volume on AudioManager and wired pause/settings sliders.
- Corrected main_menu onready path typography error; removed dangling stats button reference.
- Headless import smoke passed.
- 2026-11-02 21:06 — NPC quest-ready polish + world SFX slider + upcycle deposit guidance
  - NPC golden-ready state now shimmers QuestProgress label and emits a gentle CPUParticles layer above NPC.
  - World pause settings now include dedicated SFX volume slider wired through AudioManager and save.
  - Upcycle carried item now tracks nearest matching deposit bin + pulsing arrow indicator.
  - Headless import/runtime smoke passed.
## 2026-11-02 21:10 — BGM ducking during NPC dialogue
- Added AudioManager.duck_music() and restore_music() to fade the Music bus down while an NPC dialogue panel is open and back up on close.
- WorldNPC now ducks/un-ducks music automatically on show/close.
- Headless import/runtime smoke passed.
## 2026-11-17 — Sprint verification + collectathon passes (session log)
- ~40+ iterations across 2026-11-16/17 covering: starfish collectathon (five hidden, STARLIGHT achievement, +$25 Tide Pool), golden belt/debris/Goldie shiny scrap (12%), fish journal + REEF REGISTRY achievement, lifetime trackers (clean dives / flawless shifts / golden finds) and three achievements hung off them (CLEAN SWEEP / SILK TOUCH / GOLDEN TOUCH), best-haul / best-combo / heaviest-dive persistence (HEAVY HARVEST / RHYTHM OF THE REEF / HOT STREAK), ROUND THE ISLE (first circuit), legendary-tier banner expansion (HARBOR HERO / PATRON OF THE ISLE / ISLAND STEWARD now glow gold), harbor bell on circuit completion + legendary achievements, distant sailboat foghorn, harbor bell SFX, open.wav confirm SFX, starfish glint/shimmer, and the two one-shot starfish tutorial nudges ("A starfish!" on first; "One more…" on fourth).
- Save hardening: schema version gate (_check_version), second-generation backup rotation save.json → .bak → .bak2, New Save asks for confirmation before wiping, Journal deep-link from the world HUD to the stats page.
- Reset-island flow on the stats page (ConfirmPanel-guarded).
- Export matrix verified three times: Linux (boots clean headless), Web (pck contains all new assets), Android (debug APK builds and signs).
- Smoke-test hardened: scene-script load/compile check, CACHE_MODE_IGNORE everywhere, zero false PASSes.
- Player-save integrity guarded through every in-game test; all test residue corrected back.
- Full session log in overnight_sprint.txt — read there for the per-iteration detail.
