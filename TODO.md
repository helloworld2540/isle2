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

## Release
- `tools/ship_audit.sh` reports READY (all 7 gates green, clean tree) as of 2026-11-19 — a full `tools/export_gate.sh --re-export` would cut fresh Linux/Web/Android builds whenever a release is wanted. Not cut yet; 1.3.0 is the shipping build.
