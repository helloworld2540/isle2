extends SceneTree

## Temporary regression harness for the backup story: save rotation through
## .bak/.bak2, load_game() standing a backup in for an unreadable primary,
## restore_backup(), and backup_summary() reporting what the backup holds.
const SaveManagerScript := preload("res://scripts/save_manager.gd")

var _fails := 0

func _initialize() -> void:
	var base: String = ProjectSettings.globalize_path("user://")
	var legacy: String = base + "save.json"
	var slot_dir: String = SaveManagerScript.SLOT_DIR
	if FileAccess.file_exists(legacy) or DirAccess.dir_exists_absolute(slot_dir):
		print("SKIP: player data present, not touching it")
		quit(0)
		return

	var sm: Node = SaveManagerScript.new()
	root.add_child(sm)
	sm.ensure_bound()

	_check(not sm.has_backup(), "no backup on a fresh boot")

	# 1. First write ever: nothing to rotate into .bak yet.
	var d1: Dictionary = sm.load_game()
	d1["money"] = 100
	sm.save_game(d1)
	_check(not sm.has_backup(), "first write creates no .bak (nothing to rotate)")

	# 2. Second write: the 100 save rotates into .bak.
	var d2: Dictionary = sm.load_game()
	d2["money"] = 200
	sm.save_game(d2)
	_check(sm.has_backup(), "second write rotates the previous into .bak")

	# 3. backup_summary() reports what .bak holds (money 100).
	var summary: Dictionary = sm.backup_summary()
	_check(int(summary.get("money", -1)) == 100, "backup_summary reads the .bak (money 100)")

	# 4. Corrupt the primary; load_game() stands the .bak in for it.
	var slot_dir2: String = SaveManagerScript.SLOT_DIR
	var primary: String = "%s/%s/save.json" % [slot_dir2, sm.current_slot]
	var f := FileAccess.open(primary, FileAccess.WRITE)
	f.store_string("{ this is not valid json")
	f.close()
	var data: Dictionary = sm.load_game()
	_check(int(data.get("money", -1)) == 100, "load_game stands the .bak in for a corrupt primary")

	# 5. restore_backup rolls the island back to the backup.
	_check(sm.restore_backup(), "restore_backup succeeds")
	var data2: Dictionary = sm.load_game()
	_check(int(data2.get("money", -1)) == 100, "restore_backup rolls the island to the backup")

	_wipe_slots()
	print("restore_test: %d failure(s)" % _fails)
	quit(_fails)

func _wipe_slots() -> void:
	var root_dir := DirAccess.open(SaveManagerScript.SLOT_DIR)
	if root_dir:
		for sub in root_dir.get_directories():
			var path := "%s/%s" % [SaveManagerScript.SLOT_DIR, sub]
			var d := DirAccess.open(path)
			if d:
				for f2 in d.get_files():
					DirAccess.remove_absolute("%s/%s" % [path, f2])
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(SaveManagerScript.SLOT_DIR)

func _check(result: bool, what: String) -> void:
	if result:
		print("  ok  " + what)
	else:
		_fails += 1
		printerr("[FAIL] " + what)
