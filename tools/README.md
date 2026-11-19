# tools/ — build & release gates

One rule decides where a check lives here: **does it need the project
autoloads (`GameState`, `SaveManager`, …) to resolve?** That decides the
invocation, not the tool's size.

## Gate commands

| Command | What it runs | Use it for |
| --- | --- | --- |
| `tools/all_audits.sh` | Every harness + every Python audit, then exits 0/1 | Before cutting or publishing a build |
| `tools/export_gate.sh` | The same audits, plus `--re-export` to rebuild Linux/Web/Android into `export/` | A full release re-cut |
| `tools/fresh_clone.sh` | Cold import → Linux export → headless boot with empty log | Proving the repo alone is enough |

`all_audits.sh` cannot see real player slots — every harness it runs gets its
own throwaway profile under `/tmp/isle2_audit_<pid>` (auto-removed on exit),
so tests never collide and real saves are never touched. It exits 0 only
when every harness is green. Running the gate against the real default
profile is opt-in via `ISLE2_AUDIT_REAL_SLOTS=1`, and refused while player
slots are present there.

```sh
XDG_DATA_HOME=/tmp/isle2_verify godot --headless --path . -s tools/keeper_star_test.gd
```

## The two invocation shapes

**`godot --headless --path . -s tools/<name>.gd`** — for anything that
needs the autoload *nodes* at runtime (`root.get_node("GameState")`).
Keeper Star and courier_flight use this. Isolate `XDG_DATA_HOME` — these
touch `user://slots` and clean up after themselves.

**`godot --headless --script tools/<name>.gd`** — pure static checks that
load scenes/scripts and assert structure (smoke, tide_test, migration_test,
slot_test, …). No autoload resolution needed; they resolve project
resources relative to cwd, so run from the repo root.

Note: autoload **identifiers are not compile-time globals in `-s`
mode**, even with `--path .`. Scripts that name `GameSettings` or
`AudioManager` fail to compile there — reference them at runtime
(`get_tree().root.get_node_or_null("…")`) or preload the script by path.
This is why the harnesses use `get_node` rather than bare autoload names.

## The harness catalogue

| Tool | Type | Asserts |
| --- | --- | --- |
| `smoke_test.gd` | scenes | Every `.tscn` loads and its scripts compile |
| `keeper_star_test.gd` | runtime | THE KEEPER'S STAR scene/badge logic, schema round-trip |
| `card_queue_test.gd` | runtime | The island-wide card lane: immediate activation, FIFO waiting, modal priority, withdraw, foreign-modal blocking |
| `layout_audit.gd` | runtime | No visible screen-space Control extends past the 1152×648 window (skips scroll content and world-space labels) |
| `courier_flight_test.gd` | runtime | WorldCourier survives only on Eel Run, hidden under reduced motion, re-arms after a pass |
| `migration_test.gd` | runtime | Legacy-save restore backfills every modern key; money survives the schema round-trip |
| `tide_test.gd` | static | Tide rotation is deterministic, modifiers in bounds, tip purchase applies/lapses |
| `reef_registry_test.gd` | static | The Reef Registry's four-way agreement: FishCatalog, FISH sizes + spawn weights, stats registry rows/buttons, and the REEF REGISTRY predicate all name the same species set (incl. the Starfish's drift speed) |
| `slot_test.gd` | runtime | Slot create/delete/re-bind, multi-island save independence |
| `slot_ui_test.gd` | runtime | Slot picker rows render from headers; rename keeps id, changes label |
| `restore_test.gd` | runtime | Backup rotation (`save.json` → `.bak` → `.bak2`) and corrupt-primary recovery |
| `hide_tide_test.gd` | runtime | Hide-the-tide flag flips, persists, restores |
| `margin_notes_test.gd` | static | Margin notes: distinct, card-safe, rotation wraps |
| `npc_beat_audit.py` | static | Every milestone beat id is a real achievement; all five islanders carry required notices |
| `schema_audit.py` | static | Save schema: no duplicate keys, valid codecs, defaults match, and warns on save keys referenced nowhere outside `game_state.gd` — the rotting-relic signature of a reverted feature |
| `font_size_audit.py` | static | Mobile legibility: every explicit `font_size` must clear 24 px (excludes `.bak` files) |
| `import_audit.py` | static | Release hygiene: every importable asset has a fresh `.import` sidecar naming it — nothing ships blank (Krita `.kra` sources are not importable and are skipped) |
| `scene_boot_audit.sh` | shell | Boots every interactive scene headless with an isolated profile; fails on script errors (parse errors, node-not-found, _ready errors). What smoke_test can't see |
| `economy_audit.py` | static | Release-time check that every number the guide promises (prices, sinks, tide modifiers, spawn weights) still matches the code — no silent rebalances |
| `ship_audit.sh` | shell | The release verdict: runs all_audits + all hygiene gates + a clean-tree check. `NOT READY` until the worktree is clean |
| `courier_arc_test.gd` | runtime | Arc-level: first letter purchase, counter increment, Silverfin log, safe world re-entry |
| `tutorial_tour_test.gd` | runtime | The five-step tour advances in order on a fresh save — move → reef → sort → sell → finale, no re-arm, no auto-complete |
| `courier_flight_test.gd` | runtime | The courier's flyby (scenes/wm_courier.tscn): survives only on Eel Run, hides under reduced motion, re-arms after a pass |
| `courier_letters_test.gd` | static | The courier's letters: ≥12 pages, distinct, card-safe lengths, rotation wraps |
| `courier_letter_test.gd` | runtime | The courier's letter: buy spends $10, marks the tide day, refuses the same-day re-buy; new tide day re-opens |
| `parity_audit.py` | static | Doc-vs-code parity: every named-mechanic marker must have either docs+code or neither. Reports OVERCLAIM (documented but not in code) and informational silents, plus beat-coverage counts for the five islanders |
| `touch_audit.py` | static | Every Button ≥ 44 px in both axes |
| `unique_id_audit.py` | static | No repeated `unique_id=` in any `.tscn` |
| `drag_scroll_audit.py` | static | Every ScrollContainer in scenes/ carries the pinned drag-scroll script (`scripts/ui/drag_scroll.gd`) — the finger-flick mandate is load-bearing |
| `docs_audit.py` | static | Docs parse; no stale placeholders |
| `walkable_probe.gd` | dev | Prints walkable-tile grid info for the camera/BFS audits |

`spawn_weight_test.gd` was wired into the gate while the weighted-spawn
ship was in flight; it was retired with a revert. Do not re-add it
without reconciling first — see the sprint log.

`courier_flight_test.gd` is wired into `tools/all_audits.sh` and asserts the
world-courier flyby survives only on Eel Run, hides under reduced motion,
and re-arms after a pass.

## Rebuild / re-export

```sh
tools/export_gate.sh --re-export   # Linux + Web + Android into export/{linux,web,android}/
tools/fresh_clone.sh               # proves the repo stands alone
```

Export target directories must exist before exporting — the Linux export
fails outright without them. APK badging is dumped after each Android
export (versionCode/versionName are in the sprint log).

## House rules for new harnesses

1. Never touch a real player's slots or saves — every harness run inside
   `all_audits.sh` gets its own isolated profile, and the suite is arranged
   so no harness sees another's `user://slots`.
2. An exit code of 0 means green; anything else means the gate fails.
