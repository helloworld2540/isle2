# Release checklist

Export presets: `Web`, `Android`, `Linux` (`export_presets.cfg`).

## Verified (as of 2026-11-17)

- **Linux** x86_64 exports clean; headless boot reports zero script errors and
  stays alive (killed by timeout, exit 124 expected — Godot's `--headless`
  game binary does not quit on its own).
- **Web** (HTML5) exports clean; artifact set complete (`.html`/`.js`/`.wasm`/
  `.pck`/icons/worklets).
- **Android** exports clean; APK is signed and passes Godot's own verifier.
- **Headless harnesses** (`tools/`): `smoke_test` 49 scenes / 0 failures;
  `slot_test` 0 failures; `migration_test` PASS; `slot_ui_test` 0 failures;
  `tide_test` 0 failures. (`tide_test`, `migration_test` exit non-zero on
  failure; each harness wipes `user://slots` itself.)
- **Editor import** is clean (no errors on full reimport).
- **Frame-soak**: world boots frozen and steps 120 frames at once with
  no crash (heavy first-paint pass).
- **Backup chain** verified by `tools/restore_test.gd`: rotation creates
  `.bak` on the second write; `backup_summary()` reads the backup (money);
  `load_game()` stands the `.bak` in for a corrupt primary; `restore_backup()`
  rolls the island back intact. 0 failures.
- **Tide Ledger** verified live: button counts from `LEDGER_IDS` (0/7) and
  the legend counts what remains; seven rows wired in the scene.
- **Scene identity** verified by `tools/unique_id_audit.py`: no repeated
  `unique_id=` in any `.tscn`. PASS.
- **Mobile touch floor** verified by Touch-target audit: PASS: every Button
  carries a >=44 px minimum in both axes. PASS.
- **Fresh-save boot** at the designed 1152x648 renders the welcome card,
  the world HUD and the tide line; the desktop window pins to 1152x648 at
  boot (`GameSettings._ready`).

Harnesses that own `user://slots` (slot_test, migration_test, slot_ui_test,
tide_test) refuse to run against existing player data and wipe their slots
afterwards. `tools/count_ach.gd` (temporary) once-checked 39 unique
achievement definitions.

## Pre-flight

Target directories must exist before exporting — the Linux export fails
outright when its output directory is missing.

## Pre-flight

Run `tools/all_audits.sh` before cutting or publishing a build. It runs
every harness (smoke, slot, migration, slot_ui, tide, restore) and both
Python audits (touch, unique_id); refuses to run against real player
slots. Exits 0 only when everything is green.

## Known notes

- Export packages include `res://tools/` (debug harnesses) and
  `res://addons/` is excluded by the `addons/` gitignore rule for source,
  though the packed game is a build artifact anyway.
- The editor writes `project.godot` on import/save; the [display] pin could
  not live there safely, so the desktop window is pinned in
  `GameSettings._ready` instead (see `TODO.md`).
- The `export/` dir is gitignored; builds were written to
  `/tmp/opencode/isle2-smoke/` during verification, freeing the repo from
  binaries.

## Pending (not verified)

- Web/Android runtime smoke on actual browsers/devices (exports compile;
  runtime launch not exercised here).
- Perf on low-end Android devices.
- Store assets (icon splash, screenshots, market descriptions).
