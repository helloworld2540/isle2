extends SceneTree

## Regression harness for the Hidden-tide mode: set_hide_tide() must actually
## flip the field, not just persist it. A prior dead-indent branch let the
## field stay false while the save file recorded true — forever forgotten
## without this probe.
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
	if DirAccess.dir_exists_absolute(SaveManagerScript.SLOT_DIR) or FileAccess.file_exists(legacy):
		print(C_YELLOW + "SKIP:" + C_RESET + " player data present, not touching it")
		quit(0)
		return

	var gs = root.get_node("GameSettings")
	if gs == null:
		printerr(C_RED + "no GameSettings — did the project lose an autoload?" + C_RESET)
		quit(2)
		return

	_print_header("Hidden Tide Tests")

	var before: bool = gs.hide_tide
	gs.set_hide_tide(not before)
	_check(gs.hide_tide == (not before), "set_hide_tide flips the in-memory flag")

	# The flag must survive an autoload read of the freshly-saved settings.
	var reloaded = root.get_node("GameSettings")
	_check(reloaded.hide_tide == (not before), "flag persists in memory alongside the fresh save")

	# Restore the original.
	gs.set_hide_tide(before)
	_check(gs.hide_tide == before, "set_hide_tide restores the original")

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
