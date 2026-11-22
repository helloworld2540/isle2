extends SceneTree

## Temporary regression harness for the backup story: save rotation through
## .bak/.bak2, load_game() standing a backup in for an unreadable primary,
## restore_backup(), and backup_summary() reporting what the backup holds.
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
	var base: String = ProjectSettings.globalize_path("user://")
	var legacy: String = base + "save.json"
	var slot_dir: String = SaveManagerScript.SLOT_DIR
	if FileAccess.file_exists(legacy) or DirAccess.dir_exists_absolute(slot_dir):
		print(C_YELLOW + "SKIP:" + C_RESET + " player data present, not touching it")
		quit(0)
		return
	_print_header("Save Backup / Restore Tests")

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
	_print_summary()
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
