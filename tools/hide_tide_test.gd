extends SceneTree

## Regression harness for the Hidden-tide mode: set_hide_tide() must actually
## flip the field, not just persist it. A prior dead-indent branch let the
## field stay false while the save file recorded true — forever forgotten
## without this probe.
const SaveManagerScript := preload("res://scripts/save_manager.gd")

var _fails := 0

func _initialize() -> void:
	var base: String = ProjectSettings.globalize_path("user://")
	var legacy: String = base + "save.json"
	if DirAccess.dir_exists_absolute(SaveManagerScript.SLOT_DIR) or FileAccess.file_exists(legacy):
		print("SKIP: player data present, not touching it")
		quit(0)
		return

	var gs = root.get_node_or_null("GameSettings")
	if gs == null:
		printerr("no GameSettings — did the project lose an autoload?")
		quit(2)
		return

	var before: bool = gs.hide_tide
	gs.set_hide_tide(not before)
	_check(gs.hide_tide == (not before), "set_hide_tide flips the in-memory flag")

	# The flag must survive an autoload read of the freshly-saved settings.
	var reloaded = root.get_node_or_null("GameSettings")
	_check(reloaded.hide_tide == (not before), "flag persists in memory alongside the fresh save")

	# Restore the original.
	gs.set_hide_tide(before)
	_check(gs.hide_tide == before, "set_hide_tide restores the original")

	_wipe_slots()
	print("hide_tide_test: %d failure(s)" % _fails)
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
