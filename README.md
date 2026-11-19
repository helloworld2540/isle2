# Isle 2

A Godot 4 2D project: a world-map hub with two minigames, an economy, shop, NPC quests, upgrades, and progression.

## Project Info
- Engine: Godot 4.x
- Type: 2D game project (single-player, local save)
- Entry scenes: `main_menu.tscn` → `world.tscn`
- Shipping version: 1.3.0 — see `overnight_sprint.txt`
- Working directory: `/media/seethathuman/data/godotProjects/isle2`
- Shipped builds: Linux (`export/linux/build.x86_64`), Web (`export/linux/` HTML5 set), Android (`export/android/` signed APK) — presets in `export_presets.cfg`, all three verified end-to-end (see `overnight_sprint.txt`).

## Architecture

### In-game extras
- **About page** behind the pause menu (and the main menu bottom-right) —
  credits the keeper earned the page: engine, art, sound, writings, version,
  license, and a private line for anyone who finished the catalogue.

### Game modes
- **Normal** — tide always visible, almanac fills, conditions bend the world.
- **Hide the tide** (settings toggle) — every surface goes quiet ("The sea keeps its own counsel"). Same rules, same world, no cheats.

### Autoloads (singletons)
| Name | Script | Role |
|---|---|---|
| `GameState` | `scripts/game_state.gd` | Shared cross-scene state (score, inventory, bests, upgrades) |
| `SaveManager` | `scripts/save_manager.gd` | JSON save/load, multi-slot storage at `user://slots/<slug>/` |
| `AudioManager` | `scripts/audio_manager.gd` | SFX/BGM playback, buses, volumes, reduced motion |
| `GameSettings` | `scripts/game_settings.gd` | Persisted per-player toggles (reduce motion) |
| `SceneTransition` | `scripts/scene_transition.gd` | Fade overlay scene changes |
| `TutorialDirector` | `scripts/tutorial_director.gd` | Step-by-step first-playthrough guide (walk → dive → sort → cash in) — teaches navigation, reef mechanics, the 30 px swipe and that sorts burn Reef Debris, plus the inventory lesson (10 kg bag, per-material weights, bulk bonus, tide tip) inline on the sell step | (plus one-shot nudges incl. the tide report and the dockhand's tip)

### Modules
- **Tide** (`scripts/tide_report.gd`, global `TideReport`) — the deterministic
  four-day weather: `today()`/`for_day()`, typed accessors (`garbage_bias`,
  `fish_speed_multiplier`, `belt_speed_multiplier`, `golden_chance_multiplier`,
  `hud_line()`, `summary()`, `blurb()`, `ambient_line()`, `today_key()`), the
  calendar rotation plus the seller of tomorrow's foresight (`tip_cost()` on
  `GameState`).
- **World map** (`scripts/wm_*`) — player movement (BFS pathfinding on TileMapLayer), portals, NPCs (milestone beats per achievement), menus, settings, progress bars, ambient life (gulls tempered by tide, sea sparkle, a distant sailboat, foghorn, harbor cries, starfish collectathon, bottle journal, a far-point watcher and his note), and the tide HUD/report banner.

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
- **Wrapping rows**: the stats page's action row is an `HFlowContainer`, so
  Back / Guide / Ledger / Registry / Almanac / Restore / Reset wrap onto a
  second line instead of overflowing a narrow (mobile/1152 px) window.
- **Layout gate**: `tools/layout_audit.gd` boots every screen at 1152×648 and
  fails if any visible UI control extends past the window (scroll content and
  world-space labels excluded). Run it with the other harnesses before a cut.
- **Card lane**: `scripts/ui/card_queue.gd` (`CardQueue`, a static RefCounted)
  serialises every popup card island-wide — the welcome guide, NPC
  conversations, tutorial step hints, the achievement/tide banner and the
  world-map run recap. A card calls `CardQueue.request(self, priority)`, gets
  `_card_activate()` when its turn comes, and calls `release()` / `withdraw()`
  on close or tree exit. Modals (PRIORITY_MODAL) jump ahead of ambient cards
  (PRIORITY_AMBIENT); cards owned outside the queue (pause menu, briefing,
  confirm panel) block activation through the `ui_modal_card` group, so two
  voices never speak at once and a hint never lands under a conversation.
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
  `golden_chance_multiplier`) rather than raw keys, so there is no per-scene RNG. The shop sells a **dockhand's tide tip** ($25) that names tomorrow's tide — the only way to look ahead, bought one day at a time.
- **Bottles**: `scripts/bottle_catalog.gd` — canonical title/lines for every message in a bottle; the world pickup and the stats page's Tide Ledger both read it.
- **Fish journal**: `scripts/fish_catalog.gd` — canonical names/blurbs for the six reef species; the dive pops "New species!" on a first sighting and the stats page's Reef Registry re-shows every earned note.
- **Collectibles & streaks**: golden belt scrap (+2 score) and golden reef debris (+1 bonus) spawn at 12%; lifetime trackers (clean dives, flawless shifts, golden finds, best combo/haul) feed achievements — REEF REGISTRY, CLEAN SWEEP, SILK TOUCH, GOLDEN TOUCH, RHYTHM OF THE REEF, HEAVY HARVEST, HOT STREAK.
- **The courier's chime**: first Silverfin sighting plays a synthesized two-note glass chime (`sound/sfx/silverfin.wav`) — the registry has its own voice.
- **The courier crosses the strait**: on Eel Run days a pale streak sweeps the world map (`scenes/wm_courier.tscn`, `scripts/wm_courier.gd`) — ambience only, no card, no prompt. Once THE LAST LETTER is read, the flyby comes sooner and more often: the sea keeps the keeper company.
- **The front door remembers**: the main-menu Continue summary now badges ✳ The Pale Courier and ✦ The Whole Sea alongside Harbor Hero and Patron of the Isle.
- **The Courier's Wake**: earning THE PALE COURIER queues a one-time world-map recap card (same path as The Last Page) — the Silverfin earns ink, not just a badge.
- **The quiet harbor**: once THE WHOLE SEA is earned the dock's gull flock cries ~80% less often, the far-jetty calls stretch and never draw an answer — and the far-point watcher sets his lantern down (the pulse stops; a dim, steady ember remains). The sea is finished talking.
- **The first keeper's margin notes**: every minigame briefing card carries a rotating handwritten line from the keeper who came before (`scripts/margin_notes.gd`, two voices — bench and water), surfaced through `MinigameIntro.set_flavor_line`. On Eel Run the hand turns to a third voice — the courier's day has its own notes.
- **Run identity**: zero-miss bench shifts earn FLAWLESS SHIFT, zero-bump dives earn CLEAN DIVE — printed on the summary and world-map recap cards. Earning THE WHOLE SEA also queues a one-time "The Last Page" recap card — never overwriting a pending run recap.

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
- Slot rows sign themselves: once the Silverfin is logged, the island that
  saw it carries ✳ in the slot picker (and the front door recalls the same
  mark), so the keeper can find the one with the story at a glance.
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
  single island, **Load Save** loads it directly. Each row also shows the
  island's **day count** (`tide_days_visited`) alongside money/score, and the
  main menu's continue summary includes it too.

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
- Story-arc persisted state worth knowing about: `bottles_read`, `starfish_found`, `fish_met`, `keeper_star_found`, `courier_passes`, `courier_letter_day`, `courier_letters_bought`, `tides_logged`, `tide_almanac_granted`, `fifth_tide_granted`, `watcher_seen`, `harbor_tips_bought`, `harbor_tip_day` — every one of these feeds at least one achievement predicate. `tools/schema_audit.py` walks the table and flags relics that lost their external readers, which is the signature of a partially-reverted feature.

## Inventory & material weight
- Inventory capacity is in **kg**: `10 + 10 × inventory_capacity_level`.
- Each item costs its material weight (e.g. Polyethylene 1, Propylene 2, Glass 3, Nylon 2, Reef Debris 1).
- `GameState.get_inventory_weight()` reports the kg used (`trash_by_type` × weights).
- Upgrades shop spend trash in trash-weight currency.

## Economy Formulas
- Trash types: Polyethylene, Polypropylene, Glass, Nylon, Reef Debris.
- Shop sell rates: Polyethylene 2, Polypropylene 3, Glass 5, Nylon 4, Reef Debris 1.
- Bulk bonus: stock ≥ 5 → ×1.25 earnings (+1.35 on Glass Calm via `GLASS_CALM_BULK_BONUS`).
- **Standing order** (`ShopLedger.order_material()`): one material pays
  +1$/unit each tide day — Glass Calm → Glass, Eel Run → Nylon, Slack Water →
  Polyethylene, Night Drift → Polypropylene. Deterministic off the same tide,
  so the row price, the preview line and the payout always agree. The shop's
  row shows the boosted unit price; Hide the tide still pays it but does not
  name the order.
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
- Spawns are weighted, not uniform: Goldie 20 / Nemo 26 / Crab 22 (regulars), Grey Reef Shark 14, Starfish 14, Silverfin 10 — doubled to 20 on Eel Run, the courier's day. The Starfish drifts at 0.42× a fish's speed, spawns already on the reef floor (no bottom wake), and carries a calm amber edge marker instead of the red fish flare.
- A dive with no pickups and no fish bumps is not counted (no dive counter, depth best, recap card or haul).
- Game over: camera shake + confetti, summary panel.

## World Map
- Player: tap-to-move pathfinding (BFS) on walkable TileMap cells; highlighted path.
- Move speed affects world MOVE_TIME.
- Portals: Area2D; trigger on body enter; warn if empty inventory when targeting upcycle.
- NPCs: `WorldNPC` — dialogue, first-visit reward, 2-tier quests with material demands and trash rewards; progress labels, golden glow when ready. **Oda** the tide-watcher (`npc_oda`, west of Mara on the same walkable row) has no quests: she keeps the island's almanac, and because she is `tide_aware` she sprinkles the day's tide observation into every conversation — the whole island shares one opinion of the sea each day — and once THE KEEPER'S LETTER is read she never stops mentioning the first keeper. Tom and Nina do the same trick for TIDE KEEPER (the three shore notes): they notice you read their letters — and Mara and Kai do it for KEEPER OF THE TIDE (the Pact funded): the island noticed who paid. The whole cast also bickers in-world about the clock myth (wheels, tides, brass) — Oda’s inside-cover telling has five disagreeing voices attached. (Any `WorldNPC` can do the same via the reusable `milestone_beats` dictionary — achievement id → line.) All five named islanders carry a beat for completing the whole catalogue (ISLAND STEWARD) — the capstone speaks everywhere.

## Audio
- Buses: Master, Music, SFX, Ambience. Volumes persisted in save.
- SFX candidates with extensions .ogg/.wav/.mp3; pitch jitter 0.96–1.04.
- BGM loops per scene ("menu", "world", "upcycle", "shop", "reef").
- Signature stingers: `shift_complete` (A4 → E5 bell motif, 22050 Hz) closes the
  upcycle shift; `achievement` covers story/cards; `combo` punches at sort ×3.
- Harbor ambience (`scripts/wm_harbor_ambience.gd`, `scenes/wm_harbor_ambience.tscn`
  in `world.tscn`): a sparse, lower-pitched gull cry every 90–170 s (trimmed
  −12 dB on the Ambience bus) with an occasional answer, layered over the
  animated flock. The flock's own cries sit at −9 dB and 75–180 s — distant
  birds, not a chorus. It is audio-only and so
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
- `stats_menu.tscn`: shows score, best, lifetime, inventory, reef stats, best streak, volume sliders (incl. ambience). The deeds column records the one-time tide gifts too (the bottle gift and the starfish tide pool each flip to "paid") alongside the almanac, the fish, the courier and the far point.
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

## Building & verifying
Requirements: Godot **4.7.2 stable** and the matching export templates
(`4.7.2.stable`) for your target platforms. The repo is fully self-contained:
`git clone`, open in the editor, or run the harnesses headless. See
the overnight sprint log for the full build path.

## Verifying
`godot --headless --path . -s tools/smoke_test.gd` — the smoke test walks every
scene under `scenes/`, link-checks every `ext_resource` path (scenes and
referenced `.tres`), instantiates each scene headlessly **and verifies that
every `script =` assignment declared in the scene is live on the instantiated
node** (the `[node …]` header-line `script` trap is silently dropped by the
deserializer); the exit code is the failure count (0 = clean). Run it after
large scene/script edits — it catches broken sub-resources, bad `@onready`
paths and silently-scriptless nodes in one shot.

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

`godot --headless --script tools/reef_registry_test.gd` — the Reef Registry's
four tables agree: every catalogue species has a size row, a spawn weight, a
stats-page registry row and a scene button, and REEF REGISTRY demands the full
six (including the Starfish's slower drift).

`godot --headless --script tools/keeper_star_test.gd` — THE KEEPER'S STAR's
scene loads, the Hidden-track catalogue entry is real, and the ISLAND STEWARD
capstone does not depend on the epilogue star (nor the other way round).
`python3 tools/npc_beat_audit.py` — every NPC milestone beat names a real
achievement and all five islanders notice THE FAR POINT; wired into
`tools/all_audits.sh`.

`bash tools/all_audits.sh` — the one-command gate: every runtime and static
harness plus every Python audit, each under its own throwaway profile (no
player slots are touched, nothing collides, the suite never has to skip).
It exits non-zero on any failure. `ISLE2_AUDIT_REAL_SLOTS=1` restores the
old refuse-if-slots-present behaviour.

`tools/` also holds the PIL sprite/ambience generation scripts.

## Exporting
Export presets live in `export_presets.cfg` (Web, Android, Linux). Export templates for
Godot 4.7.2 are installed. All presets exclude `res://tools/*`, `res://addons/*`, `export/`, `opencode.json`
and `scenes/world.tscn.bak` from the pack; the repo ships a tiny no-op autoload guard (`scripts/mcp_bridge_guard.gd`) that loads the
addon only when it is on disk (the addon itself is gitignored and now excluded from every export) — the game runs with zero
dependencies, and the editor bridge works only in the developer's checkout. Verified headless builds (Nov 2026):
- `godot --headless --export-debug "Linux" export/linux/build.x86_64` — builds and launches with no script errors.
- `godot --headless --export-debug "Web" export/web/index.html` — builds clean; serve over HTTP(S) with cross-origin-isolation headers for threads.
- `godot --headless --export-debug "Android" export/android/build.apk` — builds and signs cleanly (no device install from this machine).
`export/` is git-ignored.
## License
All rights reserved. See `LICENSE` for what you may and may not do with the source. Fork it to learn. Do not sell it back.

## Writing changes
Changes land as the overnight loop cycles — see `overnight_sprint.txt` for a running log of iterations. The game is fully playable from a fresh save: menu → world map → reef rescue → upcycle bench → shop → circuit complete, with NPCs, bottles, starfish and achievements as optional flavour that persists between sessions.

## Full achievement list (47)
An island for every title the stats page tracks:

- **Reef & Bench starters** — FIRST DIVE, FIRST SORT, FIRST SALE, FIRST FAVOUR, ROUND THE ISLE, THE FIRST TIDE. THE YEAR KEEPER is 365 days of tides kept. THE QUIET KEEPER is three tides held without the sea naming them. THE TIDE WALKER is both badges at once.
- **Bench regulars** — BENCH REGULAR (10 runs), BENCH MASTER (25 runs), HOT STREAK (15-sort streak), SILK TOUCH (5 flawless shifts).
- **Dive regulars** — REEF REGULAR (10 dives), REEF VETERAN (25 dives), DEEP DIVE (400 m), TO THE ABYSS (900 m), HEAVY HARVEST (30 kg in one dive), RHYTHM OF THE REEF (9-chain combo, x4 score), CLEAN SWEEP (5 clean dives), REEF CHARTER.
- **Collections** — REEF REGISTRY (meet all six species), THE PALE COURIER (spot the Silverfin), THE REGULAR (read ten courier's letters at the counter), THE LAST LETTER (read all fourteen), STARLIGHT (five hidden starfish), TIDE MESSAGES (all three bottles), THE PACT'S REPLY (the hidden pact bottle), TIDE KEEPER (all four messages the tide left), THE FOUR TIDES (log all four daily tides in the keeper's almanac), THE KEEPER'S LETTER (find the note the first keeper left, at Oda's spot on the west shore, once the almanac is complete), and Corl's Folded Paper washes up near the shop path for keepers who bought him seven days of tomorrow (THE WHISPERER). THE FAR POINT itself sends a note east — a watcher's page, for those who caught him (THE FAR POINT). Read the six and THE SILENT CHORUS is yours — every voice the sea ever sent; the seventh is a blessing, not a requirement. Find THE KEEPER'S STAR and the far point answers in kind: an eighth note washes up at the island's tip, the epilogue's paper tail — and reading all eight earns THE WHOLE SEA, the hidden 44th badge. THE LONG KEEPER is yours after ten daily tide reports — the island sees its keeper first. THE STEADY KEEPER is three daily tide reports in a row. THE FAR POINT is yours if you stand at the island's eastern tip. ISLAND STEWARD additionally triggers THE FIFTH TIDE — a one-time +$250 parting card, the island showing its keeper the one tide it never wrote down.
- **Island quests** — HARBOR HERO (every quest tier turned in), PATRON OF THE ISLE (1500$ gift), KEEPER OF THE TIDE (2500$ pact), LOOP MASTER (25 circuits). THE WHISPERER (buy seven days of tomorrow from Corl the dockhand, 25$ a day).
- **Economy** — WELL OFF (lifetime 300$), MARKET CONTACT (+1$/unit), CACHE FOUND (buy the Deep Cache), ROOM TO SPARE (reach a 30 kg cap), GOLDEN TOUCH (10 golden scraps).
- **Capstone** — ISLAND STEWARD: every other achievement earned. Behind it waits **THE KEEPER'S STAR**: the sixth star at the far point east of the watcher, the one the island held back for its keeper. Walking over it pays $50, rings a bell and earns THE KEEPER'S STAR — an epilogue, not a checklist item. Behind the far point's reply waits THE WHOLE SEA: every bottle the sea ever sent, read.
