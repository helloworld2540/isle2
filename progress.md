# Progress

Loop state file. `TODO.md` remains the master backlog (docs_audit and the
audits gate read it); this file is the running summary the loop reads first.

## Current Goal
Keep `tools/all_audits.sh` green, expand scene-first gameplay, and harden the
game against the failure classes players can actually hit (soft-locks, lost
saves, broken transitions, unpaying sales). Each cycle: pick the next
unfinished TODO, build, test through real scenes, update the docs, commit.

## Agent Rules
- Do not ask questions unless truly blocked.
- Make reasonable assumptions and continue.
- Work on unfinished TODOs in order.
- Mark completed TODOs with [x].
- Add new bugs, ideas, and follow-up work as TODOs.
- Run tests, lint, or build when available.
- Do not run destructive commands, force pushes, production deploys, or
  database resets.
- Never inject inputs into the player's live game session; use isolated
  harnesses (XDG_DATA_HOME) instead.
- Project settings that must survive editor cycles are re-asserted in code
  (see tools/README.md), because the editor rewrites project.godot from memory.

## Active TODO
- [ ] Review the project structure and pick the next safe improvement.

## Completed
- [x] Created progress.md.
- [x] Web export uses Godot's default HTML shell (custom `res://web_shell.html` removed).
- [x] `tools/all_audits.sh` extended with export_preset/orphan/reference/achievement gates.
- [x] Save writes atomic (temp + rename) with .bak/.bak2 rotation; multi-slot isolation.
- [x] Stretch aspect durable at runtime via GameSettings (editor cannot strip it).
- [x] `portal_reach_test` — spawn/portals/NPCs/collectibles on walkable cells + BFS path.
- [x] `loop_flow_test` — full circuit reef → upcycle → shop with payouts and $15 bonus.
- [x] `save_fuzz_test` — 12 hostile saves restore safely; three abort paths fixed.
- [x] `shop_sale_test` — bulk/sub-threshold payout, undo, save round trip.
- [x] `world_move_test` — tap-to-walk + first-run card queue on the real world scene.
- [x] `reference_audit.py` — all 279 literal res:// references resolve.
- [x] Tom NPC un-stranded (was walled on all sides, quests unreachable).
- [x] ReceiptStack teardown no longer errors when the shop exits mid-animation.

## Backlog Ideas
- [ ] Extend `loop_flow_test` if a fourth station or a new transition ships.
- [ ] Extend `save_fuzz_test` when new schema types are added.
- [ ] Upcycle/reef gameplay harnesses driven by synthesized input (currently the
      gate drives handlers directly).
- [ ] Re-check .kra sprite exports after any art pass (docs rule).
- [ ] Re-run `tools/ship_audit.sh` before the next export cut.

## Blocked
- None.
