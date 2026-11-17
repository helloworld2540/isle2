# Isle 2

A Godot 4 2D project: a world-map hub with two minigames, an economy, shop, NPC quests, upgrades, and progression.

## Project Info
- Engine: Godot 4.x
- Type: 2D game project (single-player, local save)
- Entry scenes: `main_menu.tscn` → `world.tscn`
- Working directory: `/media/seethathuman/data/godotProjects/isle2`

## Architecture

### Autoloads (singletons)
| Name | Script | Role |
|---|---|---|
| `GameState` | `scripts/game_state.gd` | Shared cross-scene state (score, inventory, bests, upgrades) |
| `SaveManager` | `scripts/save_manager.gd` | JSON save/load, multi-slot storage at `user://slots/<slug>/` |
| `AudioManager` | `scripts/audio_manager.gd` | SFX/BGM playback, buses, volumes, reduced motion |
| `GameSettings` | `scripts/game_settings.gd` | Persisted per-player toggles (reduce motion) |
| `SceneTransition` | `scripts/scene_transition.gd` | Fade overlay scene changes |
| `TutorialDirector` | `scripts/tutorial_director.gd` | Step-by-step first-playthrough guide (walk → dive → sort → sell) |

### Modules
- **World map** (`scripts/wm_*`) — player movement (BFS pathfinding on TileMapLayer), portals, NPCs, menus, settings, progress bars, and ambient life (gull flock, sea sparkle, distant fishing sailboat that drifts past every few minutes, rare foghorn cries, harbor cries, a starfish collectathon, and an in-game journal of bottles and species).
- **Minigames**
  - Upcycle: `upcycle.tscn` (`scripts/upcycle.gd`) — belt sorting into material bins, over a low workshop-hum bed.
  - Reef Rescue: `reef_rescue.tscn` (`scripts/reef_rescue.gd`) + `rr_fish.tscn` (`scripts/rr_fish.gd`) — drone collection, combo, fish hazard, over a muffled underwater current.
- **Shop**: `shop.tscn` (`scripts/shop_menu.gd`) with pure pricing in `scripts/shop_ledger.gd`.
  Sale/undo receipts, the REVERSED stamp and the punch/flash effects live in
  `scenes/ui/receipt_stack.tscn` + `scripts/ui/receipt_stack.gd` (`ReceiptStack`),
  instantiated once in `_ready`.
- **Tutorial**: `scripts/tutorial_director.gd` (autoload) + `scenes/ui/tutorial_hint.tscn`
  non-modal step cards. Steps fire on world/reef/upcycle/shop scene entry and on
  gameplay events (`move`, `reef_entered`, `sorted`, `sold`); progress persists as
  save key `tutorial_step` (1..5, `999` = complete). Post-tour one-shot nudges
  (bag 85%, bottles on the shore, first sale, first bulk sale → undo, first
  affordable upgrade, first unmet islander, first deliverable quest, and the
  Deep Cache unlock once the player can afford the
  30-score price) each persist
  as a `nudge_*_shown` flag and wait their turn — a nudge raised while another
  card or a modal owns the screen is queued and fires when that card closes.
- **UI**: `scripts/ui/*`, `scenes/ui/*` — reused overlay primitives. `DragScrollContainer`
  (`scripts/ui/drag_scroll.gd`) adds finger-speed mouse drag-to-scroll on top of
  ScrollContainer's native touch scrolling (shop, stats guide list, slot
  picker). Touch targets
  ≥ 44 px — the in-run **Return to Map** buttons are 48 px, every shop button (the
  Sell 1 / 5 / All rows, the Buy buttons and Return / Undo) is ≥ 44 px tall, the
  world-menu upgrade buttons (Move / Range / Deep Cache / Inv Cap) plus the Settings
  toggle and Reduce-motion checkbox are all ≥ 44 px, and each volume slider sits in
  a label+slider row with a 40 px track — primary type ≥ 15 px.
- **Layout convention**: modal cards (welcome guide, minigame briefings, the
  pause/Island Menu) center on a full-rect `CenterContainer` inset by 24 px;
  non-modal bottom cards (tutorial step hints) sit inside a bottom `Margin`
  column. Both lanes register in `hud_bottom_card` / `ui_modal_card` groups,
  which the toast queue and tutorial director use to stack above / wait for
  them instead of overlapping. Toast notifications live in a bottom-centre
  lane, 24 px off the edge, lifted above any bottom card.
- **Audio**: `scripts/audio_manager.gd`.
- **Achievements**: `scripts/achievement_catalog.gd` — pure data + predicates (thresholds read straight off GameState fields); GameState owns the save, the pending-card queue and the `achievement_unlocked` signal. The stats page renders the compact roll and a grouped guide; the world banner celebrates unlocks.
- **Starfish**: five hidden collectibles scattered across the map's walkable cells; saved in `starfish_found`, feed the STARLIGHT achievement.
- **Daily tide**: `scripts/tide_report.gd` — a pure, deterministic four-day rotation
  keyed on the local unix day (`TideReport.day_index`). Each day bends one axis of
  the loop: **Glass Calm** (+0.16 garbage bias at the reef), **Eel Run** (fish
  drift 1.28×), **Slack Water** (belt 0.82×), **Night Drift** (golden rolls 2×).
  The banner announces the day's report once per island per day
  (`tide_report_day` save flag, claimed by `GameState.try_claim_tide_report`);
  the world HUD keeps a one-line `≈ …` reminder. Each claim also ticks that
  tide off the keeper's **almanac** (`tides_logged`): all four earn THE FOUR
  TIDES achievement, **THE ALMANAC PAGE** lore card (the lost last entry of the
  keeper who never left the island), a one-time +$30, and a checklist line on
  the stats page. Minigames read the typed
  accessors (`garbage_bias`, `fish_speed_multiplier`, `belt_speed_multiplier`,
  `golden_chance_multiplier`) rather than raw keys, so there is no per-scene RNG.
- **Bottles**: `scripts/bottle_catalog.gd` — canonical title/lines for every message in a bottle; the world pickup and the stats page's Tide Ledger both read it.
- **Fish journal**: `scripts/fish_catalog.gd` — canonical names/blurbs for the four reef species; the dive pops "New species!" on a first sighting and the stats page's Reef Registry re-shows every earned note.
- **Collectibles & streaks**: golden belt scrap (+2 score) and golden reef debris (+1 bonus) spawn at 12%; lifetime trackers (clean dives, flawless shifts, golden finds, best combo/haul) feed achievements — REEF REGISTRY, CLEAN SWEEP, SILK TOUCH, GOLDEN TOUCH, RHYTHM OF THE REEF, HEAVY HARVEST, HOT STREAK.
- **Run identity**: zero-miss bench shifts earn FLAWLESS SHIFT, zero-bump dives earn CLEAN DIVE — printed on the summary and world-map recap cards.

## State & Save
### Multi-slot islands
- Each save slot is a directory: `user://slots/<slug>/save.json` plus `.bak` and
  `.bak2` rotations. Backups are per-slot, so a torn write or a corrupt file in
  one island can never fall back into another island's story.
- `SaveManager.current_slot` is the slot the autoloads read and write right now;
  `ensure_bound()` is idempotent and runs from every public save method, so the
  binding is correct even when a scene touches saves before the menu exists.
  It binds the most recently played slot, migrates a legacy
  `user://save.json` (and its backups) into the default `island` slot on first
  boot, and otherwise binds the default id without writing a file.
- Slot identity is persisted in the save itself (`slot_name`, `slot_id`,
  `slot_created`, `slot_modified`). The **directory** is authoritative for
  `slot_id`: `GameState.restore()` forces it from `current_slot`, so a copied or
  hand-edited file cannot claim to be a different island.
- `list_slots()` scans the directory and returns newest-first header dicts
  (`id/name/created/modified` + the full save, so a row can show money/score in
  one line). `create_slot`, `rename_slot` (keeps the slug, changes only the
  label), `switch_slot`, and `delete_slot` (removes files + backups, then
  re-binds to a surviving slot) round out the API.
- Slug rules: `SaveSlot.slugify` lowercases and reduces a name to `[a-z0-9-]`;
  `unique_slug` appends `-2`, `-3`… on collision. Display names may be anything,
  including duplicates.
- UI: `scenes/ui/slot_picker.tscn` (`SlotPicker`) is a permanent, hidden
  `CanvasLayer` in the main menu. It opens from **Load Save** when more than one
  island exists, rebuilds one `scenes/ui/slot_row.tscn` per slot, and supports
  load / rename / delete (delete behind `ConfirmPanel`). The name field is the
  `scenes/ui/slot_name_field.tscn` scene. Picking a row closes the modal, then
  the menu switches slots, restores the island and enters the world. With a
  single island, **Load Save** loads it directly.

### Files & codec
- `SaveManager.has_save/new_save/save_game/load_game/list_slots/create_slot/rename_slot/switch_slot/delete_slot`.
- Legacy single-file saves remain readable: `user://save.json` is migrated once.
- `GameState` keeps `upcycle_score` as a **bank** (both reef dives and bench runs
  add to it; it is spent on the Deep Cache) and `best_upcycle_score` as the best
  single bench run; plus `reef_garbage`, `reef_fish`, `trash_inventory`,
  `trash_by_type{}`, `inventory_capacity_level`, `best_sort_streak`,
  `best_reef_depth`, `best_reef_fish`, `best_reef_combo`, `best_reef_haul`, `clean_dives`, `flawless_shifts`, `golden_finds`, `fish_met`, `bottles_read`, `lifetime_earnings`, `sort_streak`,
  `deep_cache`, `deep_cache_tier`.
- Run counters: `reef_dives` and `upcycle_runs` number the map recap chapters ("Dive № 4 — Deep Dive", "Bench Run № 2 — Hot Streak") and feed the BENCH REGULAR / REEF REGULAR achievements; the 25-run badges (BENCH MASTER, REEF VETERAN, LOOP MASTER), KEEPER OF THE TIDE, HARBOR HERO, PATRON OF THE ISLE and the ISLAND STEWARD capstone land on the banner's legendary gold tier.
- `restore()` rehydrates from save; `reset()` zeroes state. `persist()` merges into save data.
- The save codec is one table: `SAVE_SCHEMA` in `scripts/game_state.gd` maps every
  persisted `[key ↔ property ↔ default ↔ codec]`; `_write_save`, `restore()` and
  `reset()` all iterate it, so a new persisted field is one schema line — not
  three hand-mirrored blocks. Verified byte-identical round-trip (md5) against a
  real player save, plus a full `reset()` → `restore()` field sweep.
- Upgrades stored directly as save keys: `upgrade_move`, `upgrade_range`, audio/volume keys.

## Economy Formulas (weighted inventory)
- Inventory capacity is in **kg**: `10 + 10 × inventory_capacity_level`.
- Each item costs its material weight (e.g. Polyethylene 1, Propylene 2, Glass 3, Nylon 2, Reef Debris 1).
- `GameState.get_inventory_weight()` reports the kg used (`trash_by_type` × weights).
- Upgrades shop spend trash in trash-weight currency.

## Economy Formulas
- Trash types: Polyethylene, Polypropylene, Glass, Nylon, Reef Debris.
- Shop sell rates: Polyethylene 2, Polypropylene 3, Glass 5, Nylon 4, Reef Debris 1.
- Bulk bonus: stock ≥ 5 → ×1.25 earnings.
- Inventory capacity: `10 + 10 × inventory_capacity_level` kg (weighted by material).
- Purchase capacity cost: `6 + 3 × level` (paid from trash mix; deducted via `spend_trash`).
- Move/Range cost: `8 + 4 × move_level` / `12 + 6 × range_level` (also paid from the trash mix).
- Trash-upgrade payback: one loop banks ≈ bag capacity in kg, so the whole first trash tier
  (cap 6, move 8, range 12) lands at ≲1.2 loops; see guide.md for the measured table.
- Reef rescue debris reward: `max(1, round(garbage)) + (deep_cache ? 5×tier + 3×capacity_level : 0)`, capped by free capacity. The Deep Cache part is never wasted — whatever of it does not fit is salvaged as money at the debris rate ($1/kg) instead of being clamped away.
- Upcycle score is a lifetime bank: a dive adds its pickup combo multiplier and a
  bench run adds its score; it is spent on the Deep Cache (30 score, then
  15 × tier per upgrade). The world HUD bar shows progress toward the next Deep
  Cache purchase. `best_upcycle_score` tracks the best single bench run only.
- Deep Cache purchase: 30 score; upgrade: 15 × tier.
- Move speed mult: `1 + 0.08 × upgrade_move`; collection radius bonus: `12 × upgrade_range`.

## Upcycle Mechanics
- Grid: 5 columns (1..5) × 3 rows (0..2), cell size 160 px. Swipe threshold 30 px.
- Materials: Polyethylene, Glass, Polypropylene, Nylon (4 bins).
- Belt: items spawn every 2.75s at score 0 (ramps down ~0.03s/point to a 0.75s floor), max 10 on belt; banner at ≥5.
- Belt speed: `clamp(75 + score*0.3, 75, 180)`.
- Bin match by material; fire hazard on body enter.
- HUD shows the banked Reef Debris count (amber at five or fewer, red when the pile is dry) so the end of a run is legible before it arrives.
- Debris-backed shift: each spawned item spends one banked Reef Debris. At 5 or fewer a one-shot "N Reef Debris left" callout fires; at zero the belt stops feeding but the run only ends once the belt is clear and nothing is in hand, closing with a gold "SHIFT COMPLETE" panel instead of a loss screen. A visit with a dry pile that never feeds the belt records nothing — no run counter, streak, recap card or achievement credit.
- Streak tracked; on return, `record_sort_streak` and `record_upcycle(score)`.

## Reef Rescue Mechanics
- Spawn interval: `0.8s` at the surface, tightening `clamp(0.8 - depth/3000, 0.32, 0.8)`; fish vs garbage probability `randfn(depth/1000, 0.5) > 0.5` (measured: ~16% fish at 0 m, ~27% at 200 m, ~43% at 400 m, ~72% at 800 m).
- Background speed 75..120 based on drone Y; depth `+= bg_speed/10`.
- Drone inertia; wall bounce × -0.3; clamped 60 px inset.
- Collection radius 66.27 + 12×upgrade_range.
- Combos: 3 garbage in 2s → multiplier `1 + floor(combo/3)`; bonus = weight × (mult-1).
- Fish limit 3 ends run; spawns edge markers for off-screen items.
- A dive with no pickups and no fish bumps is not counted (no dive counter, depth best, recap card or haul).
- Game over: camera shake + confetti, summary panel.

## World Map
- Player: tap-to-move pathfinding (BFS) on walkable TileMap cells; highlighted path.
- Move speed affects world MOVE_TIME.
- Portals: Area2D; trigger on body enter; warn if empty inventory when targeting upcycle.
- NPCs: `WorldNPC` — dialogue, first-visit reward, 2-tier quests with material demands and trash rewards; progress labels, golden glow when ready. **Oda** the tide-watcher (`npc_oda`, west of Mara on the same walkable row) has no quests: she keeps the island's almanac, and because she is `tide_aware` she sprinkles the day's tide observation into every conversation — the whole island shares one opinion of the sea each day — and once THE KEEPER'S LETTER is read she never stops mentioning the first keeper. Tom and Nina do the same trick for TIDE KEEPER (the three shore notes): they notice you read their letters — and Mara and Kai do it for KEEPER OF THE TIDE (the Pact funded): the island noticed who paid. (Any `WorldNPC` can do the same via the reusable `milestone_achievement` / `milestone_line` exports.)

## Audio
- Buses: Master, Music, SFX, Ambience. Volumes persisted in save.
- SFX candidates with extensions .ogg/.wav/.mp3; pitch jitter 0.96–1.04.
- BGM loops per scene ("menu", "world", "upcycle", "shop", "reef").
- Signature stingers: `shift_complete` (A4 → E5 bell motif, 22050 Hz) closes the
  upcycle shift; `achievement` covers story/cards; `combo` punches at sort ×3.
- Harbor ambience (`scripts/wm_harbor_ambience.gd`, `scenes/wm_harbor_ambience.tscn`
  in `world.tscn`): a sparse, lower-pitched gull cry every 40–75 s with an
  occasional answer, layered over the animated flock. It is audio-only and so
  keeps the dock alive under reduced motion, where the flock goes still and silent.
- Surf bed (`scripts/wm_surf_bed.gd`, `scenes/wm_surf_bed.tscn` in `world.tscn`):
  a 12 s seamless wash generated by `tools/make_surf.py`, looping on its own
  dedicated player (never the round-robin SFX pool) at −22 dB on the **Ambience**
  bus. Fades in over 3 s on world entry and keeps playing through the pause menu
  (`PROCESS_MODE_ALWAYS`); it lives only in `world.tscn`, so minigames keep their
  own music beds. Harbor/flock gull cries also play on this bus.
- `Ambience` bus (send → Master) gives ambient loops and wildlife their own
  slider (`ambience_volume`, default 0.7) so trimming the wash never touches
  one-shot SFX feedback. `play_sfx(sound, pitch, bus)` takes an optional bus.
- Shared bed player (`scripts/ambience_loop.gd`, `class_name AmbienceLoop`):
  seamless-loop + fade-in-on-entry logic reused by every ambience scene. Add a
  new bed by instancing a scene with `stream_path`, `target_db` and
  `fade_in_seconds` set. Generators live in `tools/make_surf.py` and
  `tools/make_ambience.py`.
- Minigame beds (both on the Ambience bus): `scenes/amb_bench_hum.tscn` — an 8 s
  low workshop drone + fan whir at −26 dB inside `upcycle.tscn`;
  `scenes/amb_reef_swell.tscn` — a 14 s muffled current at −24 dB inside
  `reef_rescue.tscn`. Both loop the full buffer and keep playing while a
  briefing/game-over card pauses the tree.
- Reduced motion flag affects animations/transitions (ambient/idle tweens come to
  rest: menu motes and entrance, briefing pop, dialogue/recap lifts, circuit-ring
  pulse, portal glow/bob, the shop receipt punch) but never audio.

## Scene Transitions
- `SceneTransition.change_scene` fades in 0.5s, holds 1.0s, fades out 0.5s; faster with reduced motion.
- Blocks input while busy; handles paused tree.

## Stats & Settings
- `stats_menu.tscn`: shows score, best, lifetime, inventory, reef stats, best streak, volume sliders (incl. ambience).
- World menu: volume sliders (master/music/ambience/sfx), reduced motion checkbox, upgrade buttons, progress bars.
- Main menu: painted vista backdrop, save summary, and a framed "THE ISLE" world-preview
  postcard (`scenes/ui/world_preview.tscn`) with ambient motes (`scenes/ui/mote.tscn`)
  drifting over the island vista. Motes freeze under reduced motion. The postcard plays
  a one-time golden shimmer sweep the first time you visit the menu after closing an
  island circuit (`postcard_shimmer_played` save flag; static flash under reduced motion).

## Shop UI conveniences
- Two-column counter inside a dark rounded panel: **Sell material** on the left lists each
  material as a fixed row (`Name · unit$` / `×count` / `+value$` with Sell 1 / 5 / All), and
  **Spend money** + **Activity** stack on the right. Row nodes are addressed by scene-unique
  names (`%Row_Polyethylene` etc.), so the layout can move without touching the script.
- Bulk sales pop a gold "SOLD … (bulk +25%)" receipt with a punch animation; receipts stack
  top-right, right-aligned on a fixed-width row, sliding in and reflowing as they expire.
- Undo last sale is all-or-nothing: if the bag cannot fit the lot back it is denied (with a
  capacity hint in the button tooltip) instead of half-refunding. Undo plays a REVERSED
  stamp, an exiting receipt, and red flashes on the coin line / row count.
- The capacity line shows both expansion routes (shop cash price and the island-map trash
  cost), so the upgrade is discoverable wherever the player is looking. First sale in a save
  also earns the one-shot **Room for more?** nudge.
- Late game: after Patron of the Isle, the shop sells the **Tidekeeper's Pact** (2500$,
  one-time) — a permanent +10 kg bag and the KEEPER OF THE TIDE achievement.

## Files
- `.godot/` — editor cache.
- `scenes/` — all .tscn scenes.
- `scripts/` — GDScript source.
- `sprites/`, `sound/`, `fonts/`, `resources/` — assets.
- `export/`, `export_presets.cfg` — exports.
- `guide.md` — player how-to-play guide.

## Running
Open the project folder in Godot 4 and run from `main_menu.tscn`.

## Verifying
`godot --headless --path . -s tools/smoke_test.gd` — the smoke test walks every
scene under `scenes/`, link-checks every `ext_resource` path (scenes and
referenced `.tres`) and instantiates each scene headlessly; the exit code is
the failure count (0 = clean). Run it after large scene/script edits — it
catches broken sub-resources and bad `@onready` paths in one shot.

Slot save regression harnesses (each owns the `user://slots` dir it creates and
refuses to run if player data already exists):
- `godot --headless --script tools/slot_test.gd` — slugify, create/list/switch/
  rename/delete, identity round-trip, backup isolation.
- `godot --headless --script tools/migration_test.gd` — legacy `save.json`
  migrates into the `island` slot exactly once.
- `godot --headless --script tools/slot_ui_test.gd` — boots the real main menu,
  seeds two islands, and drives picker show/rows/rename/close.

`godot --headless --script tools/tide_test.gd` — deterministic tide rotation,
modifier bounds, and the once-per-day claim.

`tools/` also holds the PIL sprite/ambience generation scripts.

## Exporting
Export presets live in `export_presets.cfg` (Web, Android, Linux). Export templates for
Godot 4.7.2 are installed. All presets exclude `tools/`, `export/`, `opencode.json`
and `scenes/world.tscn.bak` from the pack; the Godot MCP addon ships only the
`game_bridge/` autoload dependencies plus `core/mcp_log.gd` (the editor-side tooling
is excluded) so exported builds still autoload cleanly. Verified headless builds (Nov 2026):
- `godot --headless --export-debug "Linux" export/linux/build.x86_64` — builds and launches with no script errors.
- `godot --headless --export-debug "Web" export/web/index.html` — builds clean; serve over HTTP(S) with cross-origin-isolation headers for threads.
- `godot --headless --export-debug "Android" export/android/build.apk` — builds and signs cleanly (no device install from this machine).
`export/` is git-ignored.
## Writing changes
Changes land as the overnight loop cycles — see `overnight_sprint.txt` for a running log of iterations. The game is fully playable from a fresh save: menu → world map → reef rescue → upcycle bench → shop → circuit complete, with NPCs, bottles, starfish and achievements as optional flavour that persists between sessions.

## Full achievement list (33)
An island for every title the stats page tracks:

- **Reef & Bench starters** — FIRST DIVE, FIRST SORT, FIRST SALE, FIRST FAVOUR, ROUND THE ISLE.
- **Bench regulars** — BENCH REGULAR (10 runs), BENCH MASTER (25 runs), HOT STREAK (15-sort streak), SILK TOUCH (5 flawless shifts).
- **Dive regulars** — REEF REGULAR (10 dives), REEF VETERAN (25 dives), DEEP DIVE (400 m), TO THE ABYSS (900 m), HEAVY HARVEST (30 kg in one dive), RHYTHM OF THE REEF (9-chain combo, x4 score), CLEAN SWEEP (5 clean dives), REEF CHARTER.
- **Collections** — REEF REGISTRY (meet all four species), STARLIGHT (five hidden starfish), TIDE MESSAGES (all three bottles), THE PACT'S REPLY (the hidden pact bottle), TIDE KEEPER (all four messages the tide left), THE FOUR TIDES (log all four daily tides in the keeper's almanac), THE KEEPER'S LETTER (find the note the first keeper left, at Oda's spot on the west shore, once the almanac is complete).
- **Island quests** — HARBOR HERO (every quest tier turned in), PATRON OF THE ISLE (1500$ gift), KEEPER OF THE TIDE (2500$ pact), LOOP MASTER (25 circuits).
- **Economy** — WELL OFF (lifetime 300$), MARKET CONTACT (+1$/unit), CACHE FOUND (buy the Deep Cache), ROOM TO SPARE (reach a 30 kg cap), GOLDEN TOUCH (10 golden scraps).
- **Capstone** — ISLAND STEWARD: every other achievement earned.
