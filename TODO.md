# Current project todo:

Sorted by importance. The overnight loop pulls from the top.

## High
- Keep `tools/all_audits.sh` green after every scene/script edit; fix harness drift (e.g. `uid=`-aware regexes) rather than weakening the checks.
- Web export shell RESOLVED (2026-11-19): preset points at tracked res://web_shell.html; fresh_clone.sh now PASSES end-to-end. Any future custom_html_shell edit must reference a git-tracked file — export/ is gitignored by design.
- Stretch aspect: `window/stretch/aspect="keep"` was tried and REVERTED — the running editor keeps its loaded copy and re-stamps project.godot on save, wiping the line. Re-attempt only via the editor's own settings UI (or after a restart), never by editing project.godot on disk while the editor is open.
- Balance pass DONE (2026-11-19): `tools/pacing_sim.gd` measures the fresh-save loop at ~$32/loop, matching the guide's +$34/+$32/+$32 — no rebalance needed. Re-run the sim after any economy constant moves.

## Medium
- Tutorial: `tutorial_tour_test` (isolated) passes under `tools/all_audits.sh` and the step-2 card was verified live in the running game (2026-11-20). A full live tap-through remains impractical without corrupting the user's fresh island — covered by the harness; do not fake gameplay via exec on the player's save.
- Mobile: re-run the 1152×648 layout audit and touch-target audit after the menu restyle; both currently PASS inside `tools/all_audits.sh` — keep them green.

## Low
- Sprites: .kra exports verified current (bottle/star/watcher/boat/rr_bg all exported same-minute as sources; `*~` backups untracked). Re-check after any future art pass.
- Docs: keep README/guide/TODO in sync with shipped behaviour each iteration; update `overnight_sprint.txt` with a dated entry per cycle.
- `wm_flow_dots.gd` reduced-motion parity verified OK (static chevrons remain, travelling dots stop) — no further work unless the trail rendering changes.

## Release
- `tools/ship_audit.sh` reports READY (all 7 gates green) as of 2026-11-19; since then the Web preset regression was fixed and all three platforms re-verified on the dev tree (Linux boots, Android APK signs, Web shell references index.js) plus a fresh-clone PASS (2026-11-20). 1.3.0 remains the shipping build; `tools/export_gate.sh --re-export` cuts fresh builds on demand.
- `tools/export_preset_audit.py` guards presets (tracked references, tools/addons exclusions, Web shell markers) — keep it in all_audits.sh.
