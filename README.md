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
| `SaveManager` | `scripts/save_manager.gd` | JSON save/load at `user://save.json` |
| `AudioManager` | `scripts/audio_manager.gd` | SFX/BGM playback, buses, volumes, reduced motion |
| `SceneTransition` | `scripts/scene_transition.gd` | Fade overlay scene changes |
| `TutorialDirector` | `scripts/tutorial_director.gd` | Step-by-step first-playthrough guide (walk → dive → sort → sell) |

### Modules
- **World map** (`scripts/wm_*`) — player movement (BFS pathfinding on TileMapLayer), portals, NPCs, menus, settings, progress bars, and ambient life (gull flock, sea sparkle, distant boat, harbor cries).
- **Minigames**
  - Upcycle: `upcycle.tscn` (`scripts/upcycle.gd`) — belt sorting into material bins, over a low workshop-hum bed.
  - Reef Rescue: `reef_rescue.tscn` (`scripts/reef_rescue.gd`) + `rr_fish.tscn` (`scripts/rr_fish.gd`) — drone collection, combo, fish hazard, over a muffled underwater current.
- **Shop**: `shop.tscn` (`scripts/shop_menu.gd`) with pure pricing in `scripts/shop_ledger.gd`.
- **Tutorial**: `scripts/tutorial_director.gd` (autoload) + `scenes/ui/tutorial_hint.tscn`
  non-modal step cards. Steps fire on world/reef/upcycle/shop scene entry and on
  gameplay events (`move`, `reef_entered`, `sorted`, `sold`); progress persists as
  save key `tutorial_step` (1..5, `999` = complete).
- **UI**: `scripts/ui/*`, `scenes/ui/*` — reused overlay primitives. `DragScrollContainer`
  (`scripts/ui/drag_scroll.gd`) adds finger-speed mouse drag-to-scroll on top of
  ScrollContainer's native touch scrolling (shop, stats guide list). Touch targets
  ≥ 44 px, primary type ≥ 15 px.
- **Audio**: `scripts/audio_manager.gd`.

## State & Save
- Save path: `user://save.json` (Godot user dir).
- `SaveManager.has_save/new_save/save_game/load_game`.
- `GameState` fields: `upcycle_score`, `reef_garbage`, `reef_fish`, `trash_inventory`, `trash_by_type{}`, `inventory_capacity_level`, `best_upcycle_score`, `best_sort_streak`, `best_reef_depth`, `best_reef_fish`, `lifetime_earnings`, `sort_streak`, `deep_cache`, `deep_cache_tier`.
- Run counters: `reef_dives` and `upcycle_runs` number the map recap chapters ("Dive № 4 — Deep Dive", "Bench Run № 2 — Hot Streak") and feed the BENCH REGULAR / REEF REGULAR achievements; the 25-run badges (BENCH MASTER, REEF VETERAN, LOOP MASTER) and KEEPER OF THE TIDE land on the banner's legendary gold tier.
- `restore()` rehydrates from save; `reset()` zeroes state. `persist()` merges into save data.
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
- Purchase capacity cost: `6 + 3 × level` (paid fromtrash mix; deducted via `spend_trash`).
- Reef rescue debris reward: `max(1, round(garbage)) + (deep_cache ? 5×tier + 3×capacity_level : 0)`, capped by free capacity.
- Deep Cache purchase: 30 score; upgrade: 15 × tier.
- Move speed mult: `1 + 0.08 × upgrade_move`; collection radius bonus: `12 × upgrade_range`.

## Upcycle Mechanics
- Grid: 5 columns (1..5) × 3 rows (0..2), cell size 160 px. Swipe threshold 30 px.
- Materials: Polyethylene, Glass, Polypropylene, Nylon (4 bins).
- Belt: items spawn every 2.75s at score 0 (ramps down ~0.03s/point to a 0.75s floor), max 10 on belt; banner at ≥5.
- Belt speed: `clamp(75 + score*0.3, 75, 180)`.
- Bin match by material; fire hazard on body enter.
- HUD shows the banked Reef Debris count (amber at five or fewer, red when the pile is dry) so the end of a run is legible before it arrives.
- Debris-backed shift: each spawned item spends one banked Reef Debris. At 5 or fewer a one-shot "N Reef Debris left" callout fires; at zero the belt stops feeding but the run only ends once the belt is clear and nothing is in hand, closing with a gold "SHIFT COMPLETE" panel instead of a loss screen.
- Streak tracked; on return, `record_sort_streak` and `record_upcycle(score)`.

## Reef Rescue Mechanics
- Spawn interval: `0.8s` at the surface, tightening `clamp(0.8 - depth/3000, 0.32, 0.8)`; fish vs garbage probability `randfn(depth/1000, 0.5) > 0.5` (measured: ~16% fish at 0 m, ~27% at 200 m, ~43% at 400 m, ~72% at 800 m).
- Background speed 75..120 based on drone Y; depth `+= bg_speed/10`.
- Drone inertia; wall bounce × -0.3; clamped 60 px inset.
- Collection radius 66.27 + 12×upgrade_range.
- Combos: 3 garbage in 2s → multiplier `1 + floor(combo/3)`; bonus = weight × (mult-1).
- Fish limit 3 ends run; spawns edge markers for off-screen items.
- Game over: camera shake + confetti, summary panel.

## World Map
- Player: tap-to-move pathfinding (BFS) on walkable TileMap cells; highlighted path.
- Move speed affects world MOVE_TIME.
- Portals: Area2D; trigger on body enter; warn if empty inventory when targeting upcycle.
- NPCs: `WorldNPC` — dialogue, first-visit reward, 2-tier quests with material demands and trash rewards; progress labels, golden glow when ready.

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
  pulse, portal glow/bob) but never audio.

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

## Exporting
Export presets live in `export_presets.cfg` (Web, Android, Linux). Export templates for
Godot 4.7.2 are installed. Verified headless builds (Nov 2026):
- `godot --headless --export-debug "Linux" export/linux/build.x86_64` — builds and launches with no script errors.
- `godot --headless --export-debug "Web" export/web/index.html` — builds clean; serve over HTTP(S) with cross-origin-isolation headers for threads.
`export/` is git-ignored.