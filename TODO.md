# Current project todo:

Sorted by importance. The overnight loop pulls from the top.

## High
- Keep `tools/all_audits.sh` green after every scene/script edit; fix harness drift (e.g. `uid=`-aware regexes) rather than weakening the checks.
- Balance pass: re-measure fresh-save loop pacing (reef → bench → shop) in an isolated profile and adjust spawn/economy constants if the opening drifted. Economy audit says the documented numbers still hold (0 failures); a real playthrough measurement is still pending.

## Medium
- Tutorial: the isolated `tutorial_tour_test` harness passes under `tools/all_audits.sh`; still walk the first-playthrough flow live via godot-mcp (isolated XDG_DATA_HOME) and tighten any step whose copy or trigger no longer matches the scene.
- Mobile: re-run the 1152×648 layout audit and touch-target audit after the menu restyle; both currently PASS inside `tools/all_audits.sh` — keep them green.

## Low
- Sprites: .kra exports verified current (bottle/star/watcher/boat/rr_bg all exported same-minute as sources; `*~` backups untracked). Re-check after any future art pass.
- Docs: keep README/guide/TODO in sync with shipped behaviour each iteration; update `overnight_sprint.txt` with a dated entry per cycle.
- `wm_flow_dots.gd` reduced-motion parity verified OK (static chevrons remain, travelling dots stop) — no further work unless the trail rendering changes.
