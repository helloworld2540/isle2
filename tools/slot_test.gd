extends SceneTree

## Temporary regression harness for the multi-slot save system. Refuses to run
## if the player already owns slots, then exercises create/rename/switch/delete
## against the real SaveManager.
const SaveManagerScript := preload("res://scripts/save_manager.gd")

var _fails := 0

func _initialize() -> void:
	if DirAccess.dir_exists_absolute(SaveManagerScript.SLOT_DIR):
		print("SKIP: existing slots present, not touching player data")
		quit(0)
		return
	var sm: Node = SaveManagerScript.new()
	root.add_child(sm)

	# 1. Fresh boot: binds the default id, writes nothing.
	sm.ensure_bound()
	_check(sm.current_slot == "island", "fresh bind -> island (%s)" % sm.current_slot)
	_check(not sm.has_save(), "fresh boot writes no file")

	# 2. Create two slots.
	var a: String = sm.create_slot("Main Isle")
	_check(a == "main-isle", "slug main-isle (%s)" % a)
	_check(sm.has_save(), "create writes a save")
	var b: String = sm.create_slot("Scratch")
	_check(b == "scratch", "slug scratch (%s)" % b)
	_check(sm.list_slots().size() == 2, "two slots listed")

	# 3. Identity round-trip: stamp a name, write, reload.
	var data: Dictionary = sm.load_game()
	data["money"] = 4242
	data["slot_name"] = "Scratch Pad"
	sm.save_game(data)
	var reloaded: Dictionary = sm.load_game()
	_check(int(reloaded.get("money", 0)) == 4242, "money round-trips")
	_check(String(reloaded.get("slot_name", "")) == "Scratch Pad", "name round-trips")
	_check(String(reloaded.get("slot_id", "")) == b, "slot_id stamped")

	# 4. Switch back to the first slot; identity follows the directory.
	_check(sm.switch_slot(a), "switch to main-isle")
	_check(String(sm.load_game().get("slot_id", "")) == a, "slot_id follows switch")

	# 5. Rename keeps the directory slug.
	_check(sm.rename_slot("Home Reef"), "rename succeeded")
	_check(String(sm.load_game().get("slot_name", "")) == "Home Reef", "rename sticks")
	_check(sm.current_slot == a, "rename keeps slug (%s)" % sm.current_slot)

	# 6. Duplicate name gets a suffixed slug.
	var c: String = sm.create_slot("Home Reef")
	_check(c == "home-reef", "duplicate-free slug (%s)" % c)

	# 7. Delete the active slot re-binds to a survivor.
	sm.switch_slot(c)
	var before: int = sm.list_slots().size()
	_check(sm.delete_slot(), "delete active slot")
	_check(sm.list_slots().size() == before - 1, "slot count drops")
	_check(not sm.current_slot.is_empty(), "re-bound after delete (%s)" % sm.current_slot)
	_check(sm.has_save(), "survivor still loadable")

	# Cleanup: this harness owns the slots dir it created.
	_wipe_slots()
	print("slot_test: %d failure(s)" % _fails)
	quit(_fails)

## Delete every slot file and its directory, then the slots root. DirAccess
## only removes empty directories, so files go first.
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

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok  ", what)
	else:
		_fails += 1
		printerr("[FAIL] ", what)
