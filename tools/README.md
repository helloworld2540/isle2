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

`all_audits.sh` refuses to run against real player slots: if
`$XDG_DATA_HOME/godot/app_userdata/isle2/slots` (or the default
`~/.local/share/...`) exists it skips everything and exits 0. The .gd
harnesses wipe `user://slots` themselves, so run them with an isolated
profile anyway:

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
| `courier_flight_test.gd` | runtime | WorldCourier survives only on Eel Run, hidden under reduced motion, re-arms after a pass |
| `migration_test.gd` | runtime | Legacy-save restore backfills every modern key; money survives the schema round-trip |
| `tide_test.gd` | static | Tide rotation is deterministic, modifiers in bounds, tip purchase applies/lapses |
| `slot_test.gd` | runtime | Slot create/delete/re-bind, multi-island save independence |
| `slot_ui_test.gd` | runtime | Slot picker rows render from headers; rename keeps id, changes label |
| `restore_test.gd` | runtime | Backup rotation (`save.json` → `.bak` → `.bak2`) and corrupt-primary recovery |
| `hide_tide_test.gd` | runtime | Hide-the-tide flag flips, persists, restores |
| `margin_notes_test.gd` | static | Margin notes: distinct, card-safe, rotation wraps |
| `npc_beat_audit.py` | static | Every milestone beat id is a real achievement; all five islanders carry required notices |
| `schema_audit.py` | static | Save schema: no duplicate keys, valid codecs, defaults match, and warns on save keys referenced nowhere outside `game_state.gd` — the rotting-relic signature of a reverted feature |
| `font_size_audit.py` | static | Mobile legibility: every explicit `font_size` must clear 17 px (excludes `.bak` files) |
| `import_audit.py` | static | Release hygiene: every importable asset has a fresh `.import` sidecar naming it — nothing ships blank (Krita `.kra` sources are not importable and are skipped) |
| `scene_boot_audit.sh` | shell | Boots every interactive scene headless with an isolated profile; fails on script errors (parse errors, node-not-found, _ready errors). What smoke_test can't see |
| `economy_audit.py` | static | Release-time check that every number the guide promises (prices, sinks, tide modifiers, spawn weights) still matches the code — no silent rebalances |
| `ship_audit.sh` | shell | The release verdict: runs all_audits + all hygiene gates + a clean-tree check. `NOT READY` until the worktree is clean |
| `tutorial_tour_test.gd` | runtime | The five-step tour advances in order on a fresh save — move → reef → sort → sell → finale, no re-arm, no auto-complete |
| `courier_letters_test.gd` | static | The courier's letters: ≥12 pages, distinct, card-safe lengths, rotation wraps |
| `courier_letter_test.gd` | runtime | The courier's letter: buy spends $10, marks the tide day, refuses the same-day re-buy; new tide day re-opens |
| `parity_audit.py` | static | Doc-vs-code parity: every named-mechanic marker must have either docs+code or neither. Reports OVERCLAIM (documented but not in code) and informational silents, plus beat-coverage counts for the five islanders |
| `touch_audit.py` | static | Every Button ≥ 44 px in both axes |
| `unique_id_audit.py` | static | No repeated `unique_id=` in any `.tscn` |
| `docs_audit.py` | static | Docs parse; no stale placeholders |
| `walkable_probe.gd` | dev | Prints walkable-tile grid info for the camera/BFS audits |

`spawn_weight_test.gd` was wired into the gate while the weighted-spawn
ship was in flight; it was retired with a revert. Do not re-add it
without reconciling first — see the sprint log.

## Rebuild / re-export

```sh
tools/export_gate.sh --re-export   # Linux + Web + Android into export/{linux,web,android}/
tools/fresh_clone.sh               # proves the repo stands alone
```

Export target directories must exist before exporting — the Linux export
fails outright without them. APK badging is dumped after each Android
export (versionCode/versionName are in the sprint log).

## House rules for new harnesses

1. Refuse to run against real player slots (check `user://slots` at the
   top, `quit(0)` with a `SKIP:` line).
2. Wipe `user://slots` when done — the gate depends on a clean slate.
3. Prefer static (`--script`) over runtime (`--path . -s`) unless the
   check genuinely needs live state.
4. An exit code of 0 means green; anything else means the gate fails.
