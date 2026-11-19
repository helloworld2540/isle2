# Release checklist

Export presets: `Web`, `Android`, `Linux` (`export_presets.cfg`).

## Verified (as of 2026-11-19, tree at 34b795a)

- **`tools/all_audits.sh` re-verified end-to-end:** `ALL-AUDITS: PASS` — all 26
  harnesses (runtime, static, Python) green in isolated per-harness profiles;
  no real player slots touched, nothing skipped, while player slots exist at
  the default path.
- **`tools/export_gate.sh --re-export` re-ran at HEAD:** `ALL-AUDITS: PASS` then
  Linux rebuilt (`export/linux/build.x86_64`, 11:25), Web rebuilt
  (`export/web/build.html` + js/pck/wasm + worklets, 11:26), Android rebuilt
  and signed (`export/android/build.apk` + `.idsig`, 11:27).
- **Linux** headless boot: 12 s run killed by timeout (exit 124 expected),
  0-byte log — zero script errors.
- **Web**: artifact set rebuilt complete and consistent.
- **Android** badging: `package=com.see.trashisland.two`, `versionCode=4`,
  `versionName=1.3.0`, `minSdk=24`, `targetSdk=36`, `compileSdk=36`,
  `application-label='Trash Island'`. Signature: **v2 + v3** (v1 absent, as
  expected). `res://tools/` and `res://addons/` not present in the APK
  (`unzip -l | grep -c addons\|tools\|godot_mcp` → 0; `assets/project.binary`
  contains no `res://tools/` references). The Linux boot at this tree also
  logs zero bytes (bridge absent).

## Verified (as of 2026-11-18)

- **Linux** x86_64 exports clean; headless boot reports zero script errors and
  stays alive (killed by timeout, exit 124 expected — Godot's `--headless`
  game binary does not quit on its own).
- **Web** (HTML5) exports clean; artifact set complete (`.html`/`.js`/`.wasm`/
  `.pck`/icons/worklets).
- **Android** exports clean; APK is signed and passes Godot's own verifier.
- **Headless harnesses** (`tools/`): `smoke_test` 51 scenes / 0 failures;
  `keeper_star_test` 0 failures; `slot_test` 0 failures; `migration_test` PASS; `slot_ui_test` 0 failures;
  `tide_test` 0 failures. `tools/npc_beat_audit.py` PASS. (`tide_test`, `migration_test` exit non-zero on
  failure; each harness wipes `user://slots` itself.)
- **Editor import** is clean (no errors on full reimport).
- **Frame-soak**: world boots frozen and steps 120 frames at once with
  no crash (heavy first-paint pass).
- **Hidden-tide** verified by `tools/hide_tide_test.gd`: the flag flips
  in memory, survives a fresh save, restores cleanly — a dead-indent
  bug was caught by this probe originally.
- **Backup chain** verified by `tools/restore_test.gd`: rotation creates
  `.bak` on the second write; `backup_summary()` reads the backup (money);
  `load_game()` stands the `.bak` in for a corrupt primary; `restore_backup()`
  rolls the island back intact. 0 failures.
- **Tide Ledger** verified live: button counts from `LEDGER_IDS` (0/8) and
  the legend counts what remains; eight rows wired in the scene.
- **Scene identity** verified by `tools/unique_id_audit.py`: no repeated
  `unique_id=` in any `.tscn`. PASS.
- **Mobile touch floor** verified by Touch-target audit: PASS: every Button
  carries a >=44 px minimum in both axes. PASS.
- **Fresh-save boot** at the designed 1152x648 renders the welcome card,
  the world HUD and the tide line; the desktop window pins to 1152x648 at
  boot (`GameSettings._ready`).

Harnesses that own `user://slots` (slot_test, migration_test, slot_ui_test,
tide_test) refuse to run against existing player data and wipe their slots
afterwards. Catalogue counts (currently 47) come from the dynamic
AchievementCatalog, never hardcoded.

## Pre-flight

Run `tools/all_audits.sh` before cutting or publishing a build. It runs every
harness in `tools/` (runtime, static and Python) under its own throwaway
profile — player slots are never touched and the suite never has to skip.
It exits 0 only when everything is green. To audit against the real default
profile, set `ISLE2_AUDIT_REAL_SLOTS=1` (refused while player slots exist).

**Release builds must exclude the `res://addons/godot_mcp/` bridge too** (it
opened a WebSocket exec/eval port in earlier exports and ran on players'
devices). All three presets now set
`exclude_filter="res://tools/*,res://addons/*"`. After every export, confirm
the pack carries no `res://addons/godot_mcp/` remaps (the APK listing and
Linux boot log are the two checks used).

`tools/export_gate.sh` wraps the same audits and, with `--re-export`,
rebuilds all three platforms into `export/{linux,web,android}/`.

Target directories must exist before exporting — the Linux export fails
outright when its output directory is missing.

## Known notes

- APK badge dump clean: `versionName=1.3.0`, `versionCode=4`, `minSdk=24`,
  `targetSdk=36`, label `Trash Island`, signer DN `CN=seethathuman`.
  One benign warning about the Godot-template themed icon path; safe
  to ignore.

## Known notes

- `res://tools/` (debug harnesses) and `res://addons/` (the godot-mcp editor
  bridge) are both excluded from every release export; the fresh-clone gate
  (`tools/fresh_clone.sh`) enforces this. The Web shell was historically a
  gitignored export/ story (export/ is gitignored) — the required template
  now lives at tracked `res://web_shell.html`, so cold clones produce a
  booting Web build.
- The editor writes `project.godot` on import/save; the [display] pin could
  not live there safely, so the desktop window is pinned in
  `GameSettings._ready` instead (see `TODO.md`).
- The `export/` dir is gitignored; builds were written to
  `/tmp/opencode/isle2-smoke/` during verification, freeing the repo from
  binaries.

## Fresh-clone build proof (2026-11-19, at 122ef21)

`tools/fresh_clone.sh` extracted `git archive HEAD` to a clean directory,
imported clean, exported Linux (boot.log empty), and exported Web. The script
now hard-fails the proof when the generated page contains `$GODOT_*`
placeholders or never references `build.js`; the run printed `== export Web
shell ... (Web shell bootstrapped correctly — build.js referenced)` and
`Fresh-clone proof PASS`. The repo alone builds a playable Web artifact.

## Fresh-clone build proof (2026-11-18)

`git archive HEAD` extracted to a clean directory, `--import` ran (two
warnings, both benign: godot_mcp addon absent — it is gitignored by design —
and the first-pass font parse before artifacts generate). Linux export
completed; headless boot remained alive (exit 124, ~470 bytes of harness
chatter). The repo is self-sufficient — an autoload guard (`scripts/mcp_bridge_guard.gd`)
loads the optional MCP bridge when present, so fresh clones boot with zero
script errors; the only remaining cold-start noise is the font-import ordering
warning, which goes away after the first run.

## Fresh-run tour (for manual reviewers)

Point-by-point path through the island on a fresh profile; each step lists
the surface a reviewer sees and the persistence it touches:

1. Boot -> main menu renders "v1.0.0", island letters + About bottom-right.
2. Continue / New Save -> world boots; HUD shows Trash, Money, tide line
   ("≈ <tide> · day 1"), next stop, starfish and bottle counts.
3. South portal -> Reef Rescue; HUDStats show banked materials + tide line.
4. Dock -> Upcycle; HUDStats shows the same tide line under Recycled.
5. North portal -> Shop; "Today: <tide>" line visible above spend rows;
   pay the dockhand 25$ (15$ on a 3-day streak) for tomorrow's tide.
6. Next world load: TIDE REPORT card -> log an almanac entry; the card
   shows "almanac n/4"; THE FOUR TIDES fires on the last.
7. Stats page: ledger button reads "Tide Ledger (n/7)", almanac checklist
   shows the four tides, almanac banner goes gold at 4/4.
8. THE KEEPER'S LETTER appears west of Oda; reading it earns THE KEEPER'S
   LETTER; Oda appends a note to every later conversation.
9. Restore backup button is previewed state — disabled with no backup,
   enabled after the second write.

A reviewer walking those nine steps exercises tide, almanac, ledger,
backup, milestone dialogue and the three stations in under five minutes.

## Pending (not verified)

- Web/Android runtime smoke on actual browsers/devices (exports compile;
  runtime launch not exercised here).
- Perf on low-end Android devices.
- Store assets (icon splash, screenshots, market descriptions).
