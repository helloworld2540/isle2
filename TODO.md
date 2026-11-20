# Current project todo:

Sorted by importance. The overnight loop pulls from the top.

## High
- Keep `tools/all_audits.sh` green after every scene/script edit; fix harness drift (e.g. `uid=`-aware regexes) rather than weakening the checks.
- Web export shell RESOLVED (2026-11-19): preset points at tracked res://web_shell.html; fresh_clone.sh now PASSES end-to-end. Any future custom_html_shell edit must reference a git-tracked file — export/ is gitignored by design.
- Stretch aspect RESOLVED (2026-11-20): the editor rewrites project.godot from its in-memory ProjectSettings on restart/shutdown, so a disk edit alone is never durable. `GameSettings._ready()` now re-asserts `content_scale_aspect = KEEP` at runtime on every platform; the project.godot key stays for editor previews. Covered by tools/README.md's corrected rule.
- Balance pass DONE (2026-11-19): `tools/pacing_sim.gd` measures the fresh-save loop at ~$32/loop, matching the guide's +$34/+$32/+$32 — no rebalance needed. Re-run the sim after any economy constant moves.

## Medium
- New `tools/world_move_test.gd` gate: real tap-to-walk + the first-run card queue (hint → welcome guide → step card). Extend it if the world spawns more cards.
- New `tools/shop_sale_test.gd` gate: bulk/sub-threshold payouts, undo, and save durability exercised through the real shop scene. Found and fixed a ReceiptStack reflow error when the shop exits mid-animation.
- New `tools/save_fuzz_test.gd` gate: 12 hostile saves must restore to safe defaults; found and fixed three abort paths (int(Dictionary), bag-as-array, INT64 overflow) plus silent bottle/character corruption. Extend the case list when new schema types ship.
- New `tools/loop_flow_test.gd` gate: the full circuit (reef → world → upcycle → world → shop) runs on real scenes and asserts the dive payout, both return trips and the $15 circuit bonus. Extend it if a fourth station or a new transition path ships.
- New `tools/reference_audit.py` gate: all 279 literal `res://` references resolve (mutation-tested). Extend it if dynamic path building ever becomes common.
- New `tools/shop_sale_test.gd` gate: bulk/sub-threshold payouts, undo, and save durability exercised through the real shop scene. Found and fixed a ReceiptStack reflow error when the shop exits mid-animation.
- New `tools/save_fuzz_test.gd` gate: 12 hostile saves must restore to safe defaults; found and fixed three abort paths (int(Dictionary), bag-as-array, INT64 overflow) plus silent bottle/character corruption. Extend the case list when new schema types ship.
- New `tools/loop_flow_test.gd` gate: the full circuit (reef → world → upcycle → world → shop) runs on real scenes and asserts the dive payout, both return trips and the $15 circuit bonus. Extend it if a fourth station or a new transition path ships.
- New `tools/reference_audit.py` gate: all 279 literal `res://` references resolve (mutation-tested). Extend it if dynamic path building ever becomes common.
- Tutorial: `tutorial_tour_test` (isolated) passes under `tools/all_audits.sh` and the step-2 card was verified live in the running game (2026-11-20). A full live tap-through remains impractical without corrupting the user's fresh island — covered by the harness; do not fake gameplay via exec on the player's save.
- Mobile: re-run the 1152×648 layout audit and touch-target audit after the menu restyle; both currently PASS inside `tools/all_audits.sh` — keep them green.

## Low
- Sprites: .kra exports verified current (bottle/star/watcher/boat/rr_bg all exported same-minute as sources; `*~` backups untracked). Re-check after any future art pass.
- Docs: keep README/guide/TODO in sync with shipped behaviour each iteration; update `overnight_sprint.txt` with a dated entry per cycle.
- `wm_flow_dots.gd` reduced-motion parity verified OK (static chevrons remain, travelling dots stop) — no further work unless the trail rendering changes.

## Release
- `tools/ship_audit.sh` reports READY (all 7 gates green) as of 2026-11-19; since then the Web preset regression was fixed and all three platforms re-verified on the dev tree (Linux boots, Android APK signs, Web shell references index.js) plus a fresh-clone PASS (2026-11-20). 1.3.0 remains the shipping build; `tools/export_gate.sh --re-export` cuts fresh builds on demand.
- `tools/export_preset_audit.py` guards presets (tracked references, tools/addons exclusions, Web shell markers) — keep it in all_audits.sh.

## Display
- `window/stretch/aspect="keep"` is DURABLE (2026-11-20): applied at runtime by `GameSettings._ready()` (`Window.CONTENT_SCALE_ASPECT_KEEP`) so no editor rewrite can strip it; the project.godot key is a preview-only mirror. Verified: headless boot with an isolated profile emits no script errors; all_audits green.
