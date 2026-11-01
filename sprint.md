
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
