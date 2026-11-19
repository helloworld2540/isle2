# Current project todo:

Sorted by importance. The overnight loop pulls from the top.

## High
- Re-verify the in-flight visual pass (world map gradients, menu card restyle, sprite refresh) end-to-end in the editor and commit it once `tools/all_audits.sh` is green.
- Keep `tools/all_audits.sh` green after every scene/script edit; fix harness drift (e.g. `uid=`-aware regexes) rather than weakening the checks.

## Medium
- Balance pass: re-measure fresh-save loop pacing (reef → bench → shop) after the visual/UI changes and adjust spawn/economy constants if the opening drifted.
- Tutorial: walk the full first-playthrough flow on a fresh save via godot-mcp and tighten any step whose copy or trigger no longer matches the scene.
- Mobile: re-run the 1152×648 layout audit and touch-target audit after the menu restyle; fix any overflow or sub-44 px targets.

## Low
- Sprites: audit `.kra` sources vs exported PNGs (bottle/star/watcher/boat were refreshed) so every referenced PNG is current.
- Docs: keep README/guide/TODO in sync with shipped behaviour each iteration; update `overnight_sprint.txt` with a dated entry per cycle.
- Consider a second pass on `wm_flow_dots.gd` path rendering for reduced-motion parity.
