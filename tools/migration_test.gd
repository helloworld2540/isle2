extends SceneTree

## Temporary regression harness: a pre-slot `user://save.json` must migrate into
## the default slot on first bind, keeping money/name and leaving no legacy file.
const SaveManagerScript := preload("res://scripts/save_manager.gd")

func _initialize() -> void:
	var base: String = ProjectSettings.globalize_path("user://")
	var legacy: String = base + "save.json"
	if FileAccess.file_exists(legacy) or DirAccess.dir_exists_absolute(SaveManagerScript.SLOT_DIR):
		print("SKIP: player data present")
		quit(0)
		return
	var f := FileAccess.open(legacy, FileAccess.WRITE)
	f.store_string(JSON.stringify({"money": 777, "upcycle_score": 12, "save_version": 1}))
	f.close()

	var sm: Node = SaveManagerScript.new()
	root.add_child(sm)
	sm.ensure_bound()
	var ok := true
	ok = _check(ok, sm.current_slot == "island", "legacy binds island (%s)" % sm.current_slot)
	ok = _check(ok, not FileAccess.file_exists(legacy), "legacy file removed")
	ok = _check(ok, sm.has_save(), "slot has save")
	var data: Dictionary = sm.load_game()
	ok = _check(ok, int(data.get("money", 0)) == 777, "money migrated")
	ok = _check(ok, String(data.get("slot_id", "")) == "island", "slot_id stamped")
	ok = _check(ok, String(data.get("slot_name", "")) == "Island", "default name")
	ok = _check(ok, sm.list_slots().size() == 1, "one slot after migration")
	ok = _check(ok, sm.list_slots()[0].get("id") == "island", "row id island")

	# The legacy save lacks every modern key: restore() must backfill with
	# defaults without crashing (old saves are load-bearing fixtures).
	var gs = root.get_node_or_null("GameState")
	if gs != null:
		gs.restore()
		ok = _check(ok, int(gs.harbor_tips_bought) == 0, "new key defaults to 0")
		ok = _check(ok, gs.tides_logged.is_empty(), "tides_logged defaults to []")
		ok = _check(ok, int(gs.money) == 777, "money restored through schema")
	else:
		print("  ok  (GameState autoload unavailable; skipped restore check)")

	# Idempotent: binding again must not re-migrate or duplicate.
	sm.current_slot = ""
	sm.ensure_bound()
	ok = _check(ok, sm.list_slots().size() == 1, "bind is idempotent")

	_wipe_slots()
	print("migration_test: %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)

func _wipe_slots() -> void:
	var root_dir := DirAccess.open(SaveManagerScript.SLOT_DIR)
	if root_dir:
		for sub in root_dir.get_directories():
			var path := "%s/%s" % [SaveManagerScript.SLOT_DIR, sub]
			var d := DirAccess.open(path)
			if d:
				for f in d.get_files():
					DirAccess.remove_absolute("%s/%s" % [path, f])
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(SaveManagerScript.SLOT_DIR)

func _check(prev: bool, result: bool, what: String) -> bool:
	print(("  ok  " if result else "[FAIL] ") + what)
	return prev and result
