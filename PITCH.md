# Trash Island 2 — Game Pitch

A cozy, single-player trash-recycling adventure set on a tile-based island. You explore a world map, befriend three trash-collecting NPCs, and run two arcade-heavy minigames whose output feeds a shared economy: an Upcycle conveyor-belt sorter and a deep-sea Reef Rescue. Everything you gather, sell, swap, and upgrade persists in a local JSON save so each run continues where you left off.

## Game overview

**Description.** Trash Island 2 (working title *isle2*) is a cozy single-player trash-recycling adventure. You explore a tile-based world map, meet three NPCs (Mara, Tom, Kai), and play two short arcade minigames — *Upcycle* and *Reef Rescue* — whose output feeds one shared island economy. Sorted recyclables and deep-sea debris become inventory that you sell and trade at the island Shop, and the trash-weight currency you earn funds movement, collection, inventory-capacity, and Deep Cache upgrades. Progress, inventory, best scores, and upgrade levels persist through a local save file (`user://save.json`); a Continue summary on the main menu surfaces best scores, per-material inventory totals, and lifetime earnings so players can resume from the exact moment they left off. **How to verify:** open the project in Godot 4 and run `main_menu.tscn` → tap **Continue** → confirm per-material totals, bests, and lifetime earnings are restored; then step into `world.tscn` and confirm the player stands on a walkable TileMap with visible portals and three NPC bubbles.

**Keywords:** cozy · recycling · minigame economy · quests · progression

**Genre:** Casual adventure / minigame collection with a light economy and progression loop.

## Concept

Trash Island 2 imagines the "second life" of a once-polluted island: you are its caretaker, converting scattered trash into value through play rather than dialogue trees. The inspiration bends tidy-shop sim loops together with light adventure worlds — instead of combat or death, your obstacles are conveyor belts, fast debris, and greedy fish, and the only currency in town is weight.

The purpose is to make recycling feel readable and rewarding: immediate feedback on every correct sort, escalating stakes (streaks, combos, closing spawns, fish hazards), a clear progression curve through six upgrade types, and NPCs who only hand out the next quest once you've actually cleaned up the previous mess. The main objectives are to collect and sort trash in Upcycle, gather deep-sea debris in Reef Rescue, sell materials at the Shop, finish each NPC's two-tier turn-in quests, and upgrade your kit until the island's inventory and best scores plateau.

The intended experience is relaxing but purposeful: short sessions (a Reef Rescue run or a clean Upcycle streak can be a complete session), satisfying sorting, gentle hazards, and steady progression without punishment for honest mistakes (wrong sorts reset the streak but deduct no score).

## Gameplay

**World map.** You tap a tile on the TileMap and the camera follows an animated, highlighted pedestrian that walks a BFS-shortest path (`world.tscn` with `scripts/wm_player.gd`; route line tinted under `wm_portal.gd` Area2Ds). *Minigames* load from portal hotspots on body-enter, with a warning if you're about to open Upcycle with an empty inv (see `wm_portal.gd`). Three named NPCs — Mara, Tom, and Kai — greet you with typewriter dialogue and a first-visit trash reward, then offer two-tier turn-in quests (e.g., "8 Polyethylene → 3 Glass") with progress labels and a golden glow when ready to deliver (`scripts/wm_npc.gd`). World pause freezes the tree and opens volume sliders, a reduced-motion checkbox, an upgrade panel with live trash-cost previews, an inventory-full/heavy status indicator, and the global Progress HUD (`scripts/wm_menu.gd`, `scripts/wm_progress.gd`).

**Upcycle** (`upcycle.tscn` / `scripts/upcycle.gd`). Five material bins line a 5-column × 3-row belting grid (160 px cells); items spawn on a 1.0-second cadence (max 10), with a scaling belt speed of `clamp(90 + score*0.4, 90, 220)` px/s and a bouncy "FIVE ON THE BELT!" banner at ≥5 (streak unlocked). Items bob subtly on the conveyor. Swipe (≥30 px) to place each item in the matching material bin to score, advance your recycled counter, and feed inventory. Streaks pulse the UI and scale the sort-sfx pitch; at 5 items you get a milestone blip and the banner. Wrong sorts and burned hazards reset the streak but never deduct score. **How to verify:** Play Upcycle and watch the HUD count per material and belt load; intentionally sort a wrong item — the streak indicator resets but your score line stays put.

**Reef Rescue** (`reef_rescue.tscn` / `scripts/reef_rescue.gd` + `scripts/rr_fish.gd`). You pilot a drone through a smoothly-scrolling coral stratum at 75–120 px/s depending on drone height, collecting garbage (1 kg per pickup) while dodging harmless-but-tagging fish. Three fish contacts end the run with a shake + confetti payoff panel that credits debris to your inventory. The spawn cadence starts at 0.8 s and tightens down to 0.32 s as depth rises; pickups sparkle in item color and pop the combo multiplier (every 3 rapid pickups inside 2 s gives ×1, ×2, ×3, etc.); an escape button and ESC both raise a safe exit-path popup. Debris credit = `max(1, round(garbage)) + (deep_cache ? 5×tier + 3×capacity_level : 0)`, capped by free capacity, with a toast if the inventory is full. **How to verify:** make a run, watch the depth label climb, smash 3 pieces fast — the combo multiplier pops up — and 3 fish later the summary panel reveals your credited debris.

**Economy.** Inventory is weighted in kg (Polyethylene 1, Polypropylene 2, Glass 3, Nylon 2, Reef Debris 1) on a 60 + 20 × `inventory_capacity_level` kg budget. The Shop (`shop.tscn` / `scripts/shop_menu.gd`) buys materials at fixed rates (Polyethylene 2, Polypropylene 3, Glass 5, Nylon 4, Reef Debris 1 trash-weight each) with a 1.25× bulk bonus when you hold ≥5 of a type, and the Sell 1 / Sell 5 / Sell All + undo buttons respect your capacity. Upgrades spend trash directly: move speed +8 %/level, collection radius +12 px/level, Deep Cache (30 score purchase, 15 × tier to upgrade, with +5 tier and +3 × capacity_level debris), and capacity bumps cost 6 + 3 × current level for 20 kg more. NPC quests turn in one material for another (e.g., "8 Polyethylene → 3 Glass", "6 Nylon → 4 Polypropylene") with a ✓ for visited and ★ for quest-complete over the head (`wm_npc.gd`). Everything saves to `user://save.json` via `SaveManager.save_game()` / `load_game()` whether you idle, manual-pause, or portal-transition autosave.

## Innovation

Isle 2 stands apart by merging **two distinct arcade tracks inside one persistent economy** instead of shipping disjointed minigames with no carry-over:

- **Existing approach:** separate minigames, no memory of each other.
- **Our approach:** a shared weighted inventory and trash-weight currency, so a quick Upcycle belt sweep funds the next Reef dive upgrade, and vice-versa.
- **What changed:** players read their own mix (light materials for speed, Reef Debris for bulk weight), spend a single resource with capacity-aware feedback, and juggle NPC quests that reshape the material mix — turning two mechanics into one market.

Compared to superficial cleaning sims (trash kittens, river-cleaners), the difference is the **cross-mode feedback loops**: streaks/combo multipliers upcycle everything you sort, Deep Cache tiers scale economy-wide, and every upgrade is priced in the currency you're already choosing to stockpile.

## Development

Built in **Godot 4.x** with **GDScript** under a 2D Forward Plus project (`project.godot`), with four autoloads — `GameState`, `SaveManager`, `AudioManager`, `SceneTransition` — and modular code under `scripts/` scoped by feature (`wm_*`, upcycle/reef, shop, audio, UI widgets). The architecture splits cleanly: world map (portal, NPC, BFS, pause), Upcycle minigame (belt, bins, scoring, streaks), Reef Rescue (drone inertia, fish, spawn ramp), chip-based shop, and shared UI primitives. State layers persist into JSON at `user://save.json` (restore / reset / persist mirrors across autoload + save manager).

Major engineering beats recorded in `sprint.md` / `TODO.md`: two-tier NPC quest & dialogue branching, weighted-inventory refactor (cleaned the `spend_trash` Variant warning by inferring min weight slots), inventory-cap capacity feedback and toast messaging, portal autosave of position (improves Continue resume), reduced-motion-aware transitions (0.5/1.0/0.5s base, faster when reduced, pausing-safe through `SceneTransition.change_scene`), BGM crossfade caching (0.28s/0.12s reduced), and a headless import+runtime smoke pass after every sprint step. Assets mix generated WAV SFX/BGM placeholders, Krita-drawn sprites, polygon-extruded sprite sheets, dynamic confined tiles, and licensed royalty-free BGM from Kevin MacLeod — exported via the configured desktop preset/export directory.

## Visual and Audio Design

Warm, slightly cartoony crisp tiles with semi-transparent rounded UI panels. Reduced motion is honoured on transitions, item bobbing, and typed dialogue, with a checkbox in the pause menu. Juices include belt-bob + bin sparkle (correct sort), wrong-sort screen-shake (reduced-motion guarded), portal-pulse overshoots + ping markers, confetti and camera shake on a Reef game-over, hero entrance animations on the main menu, and toast/receipt popups for sales and pickups. Audio uses two buses (Master, Music) with per-scene BGM loops (`menu`/`world`/`upcycle`/`shop`/`reef`), SFX pitch jitter 0.96–1.04, SFX pitch scaling with streak/combo, and user-accessible volume sliders that persist into the save. Accessibility affordances include ESC exit in Reef, re-entrancy guards, focus handling, and tab-safe pause-width clamping for small viewports.

## Future Development

Target audience spans cozy-game fans, casual evening session players, and STEAM/ed-tech uplift layers (the inventory is intentionally legible in kg and material names are real polymer classes). Market opportunity is the gap between no-hazards cleaning sims and heavy economy shooters: a kind arcade game whose numbers feel like real throughput.

Roadmap drawn from existing structure: additional NPC quest variants + tier branching, expanded inventory tiers and optional multi-slot saves, deeper minigame polish (e.g., new belt modifiers, new reef biomes), mobile export via `export_presets.cfg`, plus meta-features (more portals/worlds, seasonal events, shared ghost-leaderboards for best Upcycle streak / deepest Reef dive). Small additions already templated: POI bubbles, toast queue stacking, and the more-stats deep dive from the Continue summary.

## Project Summary

Trash Island 2 is a cozy recycling adventure where you walk a tile map and play two minigames — belting-mode Upcycle and depth-scrolling Reef Rescue — whose combined output feeds a single economy of weighted materials and trash currency. Inspired by tidy-shop sim loops and gentle adventure worlds, it makes sorting feel good through streaks, combos, upgrades, and NPC quests that reshape what you're holding. Players navigate by tap, launch portals, chase streaks and combos, sell at society-rate, upgrade movement, collection radius, inventory, and Deep Cache, and everything persists to JSON mid-tunnel. Its selling point is the **shared economy**: unlike disjointed minigames, every pickup feeds everything else, with weight caps and turn-in quests injecting gentle strategy. Built in Godot 4 with GDScript, four autoloads, BFS pathing, data-driven upgrades, and headless-verified smoke, it stands out by blending arcade satisfaction with a gentle loop and accessibility (reduced motion, volumes, ESC exit).

## Summary

Trash Island 2 revolves around two arcade minigames feeding a single economy across a small tile world. Its innovation is the cross-mode trash-weight currency and tiered Deep Cache; its strengths are responsive juice, accessibility-first toggles, and a robust, easily resumable save/economy pair. Next directions are more worlds, portal variety, and leaderboards — but already, every pickup visibly moves the island forward, and nothing is wasted.

