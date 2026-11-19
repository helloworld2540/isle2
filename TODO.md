# Current project todo:

Sorted by importance. The overnight loop pulls from the top.

## High
- Keep `tools/all_audits.sh` green after every scene/script edit; fix harness drift (e.g. `uid=`-aware regexes) rather than weakening the checks.
- Balance pass DONE (2026-11-19): `tools/pacing_sim.gd` measures the fresh-save loop at ~$32/loop, matching the guide's +$34/+$32/+$32 — no rebalance needed. Re-run the sim after any economy constant moves.

## Medium
- Tutorial: the isolated `tutorial_tour_test` harness passes under `tools/all_audits.sh`; still walk the first-playthrough flow live via godot-mcp (isolated XDG_DATA_HOME) and tighten any step whose copy or trigger no longer matches the scene.
- Mobile: re-run the 1152×648 layout audit and touch-target audit after the menu restyle; both currently PASS inside `tools/all_audits.sh` — keep them green.

## Low
- Sprites: .kra exports verified current (bottle/star/watcher/boat/rr_bg all exported same-minute as sources; `*~` backups untracked). Re-check after any future art pass.
- Docs: keep README/guide/TODO in sync with shipped behaviour each iteration; update `overnight_sprint.txt` with a dated entry per cycle.
- `wm_flow_dots.gd` reduced-motion parity verified OK (static chevrons remain, travelling dots stop) — no further work unless the trail rendering changes.

## Cleanup (asset hygiene, reviewed 2026-11-19)
- Candidate orphan sprites (tracked in git, unreferenced by scenes/scripts; audio excluded — it is reference-by-key and all keys resolve): `sprites/starfish.png`, `sprites/sub.png`, `sprites/sky_blurred.png`, `sprites/wm_npc/npc1..4.png`, `sprites/player_anim/player_walk0000..0002.png`, `sprites/upcycle/fire.png`, `sprites/upcycle/pump.png`. Likely pre-refresh leftovers — confirm with a final in-game pass, then delete or move to `sprites/placeholders/` in one commit.
