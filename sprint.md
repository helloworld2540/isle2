
## 2026-11-01 12:24 — World-map NPC system pass.
- Added WorldNPC scene (wm_npc.tscn) + script (wm_npc.gd) with idle pulse, dialogue panel, first-visit trash reward, persistent visited state.
- Placed Mara and Tom NPCs on world.tscn.
- Fixed game_state.spend_trash warning-as-error (min inferred Variant).
- Headless import clean (only environmental GitPlugin warning).

## 2026-11-01 12:28 — NPC quest & dialogue branches pass.
- WorldNPC now supports repeat-visit lines, quest-complete lines, and an optional turn-in quest (consume trash, reward trash).
- Mara: turn in 8 Polyethylene -> 3 Glass. Tom: turn in 6 Nylon -> 4 Polypropylene.
- Name labels reflect visited (✓) and quest-complete (★).
- Fixed NPC scene connection; headless import clean.

## 2026-11-01 12:30 — Main-menu continue summary thumbnail polish.
- Expanded Continue summary to include best fish, best streak, and lifetime earnings in a compact thumbnail-style layout.
- Headless import clean.

## 2026-11-01 12:43 — NPC tier-2 quests + parser cleanup.
- Added tier-2 turn-in quests for Mara and Tom.
- Repaired wm_menu.gd broken progress-bar scaffolding; import clean.

## 2026-11-01 12:55 — NPC polish + Kai shop-themed quests.
- Added third NPC (Kai) near world center; two-tier Glass/Polyethylene quests.
- Tile-name cleanup trailing; headless import clean.

## 2026-11-01 13:46 — World cleanup + player polish.
- Removed stray empty TileMapLayer from world.tscn; grouped NPC instances under NPCs node.
- Portal pulse overshoot amplitude ticked for more juice.
- Headless import clean.

## 2026-11-01 14:54 — NPC sprites + portal/HUD polish.
- WorldNPC now loads sprites/wm_npc/npc1–4 via npc_sprite_index and hides primitive Body.
- Portal pulse extra overshoot, idle label bob; guarded against transition reentry.
- WorldProgress HUD raised layer, stronger transparency and border.
- Headless import/run clean.

## 2026-11-01 15:00 — Sprint continuation polish.
- NPC progress above-head labels hardened to reuse scene node and update live.
- Portal/pulse/juice and NPC sprite bob passes.
- WorldProgress HUD transparency/border and z layer pass.
- Headless import/run clean.

## 2026-11-01 15:05 — Reef spawn polish + runtime check.
- Reef spawn fade-in (transparency + scale back-ease) already in place; verified headless runtime.
- Desktop NPC/sprite/progress systems stable.
- Headless import/run clean (no errors).

## 2026-11-01 15:23 — Quest label z polish.
- Quest progress labels raised z order and are guaranteed visible over NPC sprites.
- Headless import/runtime validated.

## 2026-11-01 15:25 — Sprint closure.
- TODO marked NPC repeat-visit flavour variants complete.
- Headless import/runtime clean.

## 2026-11-01 15:28 — Pause menu responsive polish.
- Tightened pause width clamp and added viewport size tracking.
- Basic vertical anchor fallback for small viewports.
- Headless import/runtime clean.

## 2026-11-01 15:55 — Audio + cleanup pass.
- Generated real WAV SFX/BGM placeholders in sound/sfx and sound/bgm; AudioManager already loads .wav.
- Fixed shop_menu double UI creation; WorldProgress duplicate layer removed.
- Hardened reef escape (ESC) to record reef result and debris.
- Polished world pause upgrade panel styling and content cost labels.
- Headless import/runtime clean.

## 2026-11-01 16:18 — NPC presentation polish.
- Reduced NPC sprite scale from 0.62 to 0.46 and measured all four exported pngs so the billboards fit the tile-based world map.
- Repositioned NameLabel and QuestProgress labels dynamically above each sprite, preventing overlap with the sprite and keeping progress readable.
- Removed stale player/upcycle console debug spam.
- Updated TODO to mark NPC sprite pairing polish complete.
- Headless Godot import clean.

## 2026-11-01 16:28 — Portal autosave + pause anchoring
- Portal transitions now write the current player position into the existing save file before changing scenes, so Continue restores the last explored spot even when pause was not used.
- Pause menu max width/clamp recomputed from the actual viewport with a 720p-safe anchor fallback.
- Headless import/runtime clean.

## 2026-11-01 16:35 — ReefEscape consistency pass.
- Unified Return-to-Map (button and ESC) through one `_leave_to_map()` flow to avoid duplicate score/debris recording.
- Added `running` guard so ESC or a second click cannot double-submit after exit starts.
- Deep Cache debris bonus applied once.
- Headless import/runtime clean.

## 2026-11-01 17:41 — Sprint polish consolidation.
- Reef debris credit, ESC NPC dismissal, shop Reef Debris sink, speed-scaled upcycle stepping all landed and import-verified.
- Headless Godot 4.7.2 import clean (only non-blocking environmental GitPlugin/VCS warnings).

## 2026-11-01 18:35 — Sprint polish continuation
- World map pause menu now plays BGM and cycles idle tracks (world/ambience/world/reef) every 18s (respects reduced motion).
- Deep Cache now scales per tier: reef debris bonus = 5 * tier; upcycle score can upgrade tier cost 15 * tier.
- Headless Godot 4.7.2 import/run clean.

## 2026-11-01 18:38 — Inventory capacity sprint pass
- GameState now caps total inventory at 30 + 15 per level; add_trash_type returns accepted count.
- World map pause panel exposes "Inventory Cap" upgrade using the same trash currency.
- Headless import/run validated.

## 2026-11-01 18:41 — Cap feedback pass
- Reef Escape now reports how much debris was lost to the inventory cap.
- Upcycle now notifies when a sorted item is dropped over the cap.
- Headless Godot import/run clean.

## 2026-11-01 18:48 — HUD polish pass
- `wm_progress.gd` now surfaces live inventory total/capacity and per-material counts in a compact label, plus the summary line.
- Headless Godot import/run clean (only environmental GitPlugin warning).

## 2026-11-01 18:53 — NPC safety pass
- Quest turn-in buttons disable when the expected reward would exceed current inventory headroom.
- Turn-in now surfaces partial reward gains with an "inventory cap" message when applicable.
- Headless Godot import/run clean.

## 2026-11-01 18:55 — Inventory UI polish pass
- Pause-menu inventory cap button turns red when inventory is at/over capacity.
- Headless Godot import/run clean.

## 2026-11-01 18:57 — UI capacity indicator
- World menu now shows inventory full/heavy status with colorized warning.
- Headless import/run clean.

## 2026-11-01 19:04 — Pickup sparkle pass
- Reef Rescue now spawns short-lived sparkles in item color on each pickup for extra game feel.
- Headless import/run clean (standard warnings only).

## 2026-11-01 19:12 — Audio polish pass
- `AudioManager.play_sfx` now accepts a pitch scale and applies subtle randomization for juicier feedback.
- Shop sells (1.03) and upgrade purchases (1.05) use the new parameter.
- Headless import/run clean.

## 2026-11-01 19:15 — Main-menu ambient polish
- Added looping ambient dot motion layer behind the menu summary for softer, more alive visual feel (respects existing randomization).
- Headless Godot import/run clean.

## 2026-11-01 19:22 — Combo feedback polish
- Upcycle now pulses the UI on combo milestones to make high-streak play feel more satisfying.
- Headless Godot import/run clean.

## 2026-11-01 19:30 — Documentation pass
- Added concise README.MD with engine/runtime, run/test paths, smoke guidance, and asset notes.
- Headless verification clean (pre-existing environmental warning only).

## 2026-11-01 19:42 — Reef fish penalty + Deep Cache scaling pass
- Reef rescue now treats fish contact as a penalty: 3 bumps triggers a game-over summary screen crediting debris and returning to map.
- Deep Cache debris bonus scales with inventory-cap upgrade tier (+3 per level).
- Headless Godot 4.7.2 import clean (only environmental GitPlugin warning).

## 2026-11-01 19:45 — Upcycle combo audio/visual polish
- Sort SFX pitch now scales with current streak; wrong sort/burn use lower pitches.
- Correct sort spawns bin sparkle particles; combo milestone feedback retriggered.
- Headless Godot 4.7.2 import clean.

## 2026-11-01 19:48 — Main-menu summary inventory totals
- Continue summary now lists per-material inventory totals.
- Headless Godot 4.7.2 import clean.

## 2026-11-01 19:50 — Pause menu auto-refresh on toggle
- Opening the world pause menu now refreshes upgrade UI and status text.
- Fixed indentation parse error introduced in toggle.
- Headless Godot 4.7.2 import clean.

## 2026-11-01 19:52 — Main-menu summary fix
- Corrected inventory totals formatting for parse error; added helper.
- Headless Godot 4.7.2 import clean.

## 2026-11-01 20:11 — Reef game-over juice + shop tips
- Reef Rescue now shakes camera and spawns confetti on fish-bump game over.
- Shop menu surfaces full/heavy/normal inventory tips.
- Pause panel typography pass (status/summary labels) and tip on pause menu.
- Headless import verified clean (only environmental GitPlugin warning).

## 2026-11-01 20:17 — Main-menu entrance + pause toggle guard
- Added hero entrance animation (fade/scale) for main-menu buttons/summary.
- Added reentrancy guard + focus handling to world pause toggle.
- Headless import verified clean.

## 2026-11-01 20:18 — Inventory full toast pass
- Reef game-over now surfaces "Inventory full — sell trash" toast when no debris can be credited.
- Headless import verified clean.

## 2026-11-01 20:22 — Pause menu polish
- World pause menu upgraded with tighter typography + upgrade sparkle bursts, reentrancy guard, and focus handling.
- Headless import verified clean.

## 2026-11-01 20:32 — Upcycle belt bob + portal cues pending
- Added animated trash-item bobbing on conveyor belt.
- Headless import verified clean.

## 2026-11-01 20:39 — Reef debris combo multiplier
- Reef Rescue now awards a combo multiplier based on consecutive garbage pickups (every 3 adds +1), displays as xN in pickup popups.
- Headless import verified clean.

## 2026-11-01 20:41 — Reef debris combo multiplier
- Reef Rescue now tracks rapid debris pickups within 2s and multiplies debris credit (x2/x3) with scaled sparkles and SFX pitch.
- Headless import verified clean.

## 2026-11-01 20:48 — Shop receipt toast
- Shop now spawns a floating "SOLD <material>" receipt on one-off sales.
- Headless import verified clean.

## 2026-11-01 20:57 — Sprint cycle report (README + portal + upcycle banner)
- Rewrote README.MD to introduce Isle2: engine/runtime, loop, key areas, assets, autoloads.
- Portal hover: pad scales up on body enter and resets on exit; ping marker preserved.
- Upcycle: spawn streak banner "FIVE ON THE BELT!" with scale bounce when 5 items on belt.
- Headless Godot 4.7 verification pending (MCP process exited immediately; visual runtime not captured this turn).

## 2026-11-01 21:02 — Sprint cycle report
- Upcycle wrong-sort screen shake added (reduced-motion guarded).
- NPC quest turn-in SFX now scales pitch slightly by tier.
- World pause menu now fades in smoothly when reduced motion is off.

## 2026-11-02 16:30 — Upcycle/Reef priority pass
- Upcycle spam spawn interval starts 5s then gradually tightens to 1.5s.
- Removed wrong-sort and belt-burn score punishment; feedback remains.
- Reef Rescue now grants 1 kg per garbage and auto-takes game over closure when capacity is full.
- Updated guide/help text and docs to match.
