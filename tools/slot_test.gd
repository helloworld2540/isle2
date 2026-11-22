extends SceneTree

## Temporary regression harness for the multi-slot save system. Refuses to run
## if the player already owns slots, then exercises create/rename/switch/delete
## against the real SaveManager.
const SaveManagerScript := preload("res://scripts/save_manager.gd")

# ANSI color codes
const C_RESET := "\u001b[0m"
const C_BOLD := "\u001b[1m"
const C_RED := "\u001b[31m"
const C_GREEN := "\u001b[32m"
const C_YELLOW := "\u001b[33m"
const C_BLUE := "\u001b[34m"
const C_CYAN := "\u001b[36m"

var _fails := 0
var _passes := 0
var _skipped := 0
var _start_time: int = 0

func _initialize() -> void:
	_start_time = Time.get_ticks_msec()
	if DirAccess.dir_exists_absolute(SaveManagerScript.SLOT_DIR):
		print(C_YELLOW + "SKIP:" + C_RESET + " existing slots present, not touching player data")
		quit(0)
		return
	_print_header("Multi-Slot Save Tests")
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
	_print_summary()
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
		_passes += 1
		print(C_GREEN + "✓" + C_RESET + " " + what)
	else:
		_fails += 1
		print(C_RED + "✗" + C_RESET + " " + what)


func _print_header(title: String) -> void:
	var line := "═".repeat(title.length() + 4)
	print(C_CYAN + line + C_RESET)
	print(C_CYAN + "  " + title + "  " + C_RESET)
	print(C_CYAN + line + C_RESET)
	print("")


func _print_summary() -> void:
	var elapsed := (Time.get_ticks_msec() - _start_time) / 1000.0
	var total := _passes + _fails + _skipped
	var line := "─".repeat(50)
	print("")
	print(C_CYAN + line + C_RESET)
	print(C_BOLD + "RESULTS:" + C_RESET + " " + C_GREEN + str(_passes) + C_RESET + "  " + C_RED + "FAILED:" + C_RESET + " " + str(_fails) + "  " + C_YELLOW + "SKIPPED:" + C_RESET + " " + str(_skipped))
	var time_str := "%0.2f" % elapsed
	print(C_BOLD + "TOTAL:" + C_RESET + " " + str(total) + "  " + C_BLUE + "TIME:" + C_RESET + " " + time_str + "s")
	if _fails == 0:
		print(C_BOLD + "STATUS:" + C_RESET + " " + C_GREEN + "✓ ALL TESTS PASSED" + C_RESET)
	else:
		print(C_BOLD + "STATUS:" + C_RESET + " " + C_RED + "✗ " + str(_fails) + " TEST(S) FAILED" + C_RESET)
	print(C_CYAN + line + C_RESET)
