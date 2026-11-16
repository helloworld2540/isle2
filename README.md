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
- **World map** (`scripts/wm_*`) — player movement (BFS pathfinding on TileMapLayer), portals, NPCs, menus, settings, progress bars.
- **Minigames**
  - Upcycle: `upcycle.tscn` (`scripts/upcycle.gd`) — belt sorting into material bins.
  - Reef Rescue: `reef_rescue.tscn` (`scripts/reef_rescue.gd`) + `rr_fish.tscn` (`scripts/rr_fish.gd`) — drone collection, combo, fish hazard.
- **Shop**: `shop.tscn` (`scripts/shop_menu.gd`) with pure pricing in `scripts/shop_ledger.gd`.
- **Tutorial**: `scripts/tutorial_director.gd` (autoload) + `scenes/ui/tutorial_hint.tscn`
  non-modal step cards. Steps fire on world/reef/upcycle/shop scene entry and on
  gameplay events (`move`, `reef_entered`, `sorted`, `sold`); progress persists as
  save key `tutorial_step` (1..5, `999` = complete).
- **UI**: `scripts/ui/*`, `scenes/ui/*` — reused overlay primitives.
- **Audio**: `scripts/audio_manager.gd`.

## State & Save
- Save path: `user://save.json` (Godot user dir).
- `SaveManager.has_save/new_save/save_game/load_game`.
- `GameState` fields: `upcycle_score`, `reef_garbage`, `reef_fish`, `trash_inventory`, `trash_by_type{}`, `inventory_capacity_level`, `best_upcycle_score`, `best_sort_streak`, `best_reef_depth`, `best_reef_fish`, `lifetime_earnings`, `sort_streak`, `deep_cache`, `deep_cache_tier`.
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
- Two buses: Master, Music. Volumes persisted in save.
- SFX candidates with extensions .ogg/.wav/.mp3; pitch jitter 0.96–1.04.
- BGM loops per scene ("menu", "world", "upcycle", "shop", "reef").
- Reduced motion flag affects animations/transitions.

## Scene Transitions
- `SceneTransition.change_scene` fades in 0.5s, holds 1.0s, fades out 0.5s; faster with reduced motion.
- Blocks input while busy; handles paused tree.

## Stats & Settings
- `stats_menu.tscn`: shows score, best, lifetime, inventory, reef stats, best streak, master volume.
- World menu: volume sliders (master/music), reduced motion checkbox, upgrade buttons, progress bars.
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

## Files
- `.godot/` — editor cache.
- `scenes/` — all .tscn scenes.
- `scripts/` — GDScript source.
- `sprites/`, `sound/`, `fonts/`, `resources/` — assets.
- `export/`, `export_presets.cfg` — exports.
- `guide.md` — player how-to-play guide.

## Running
Open the project folder in Godot 4 and run from `main_menu.tscn`.