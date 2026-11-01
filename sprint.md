
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
