extends SceneTree

## Temporary regression harness: a pre-slot `user://save.json` must migrate into
## the default slot on first bind, keeping money/name and leaving no legacy file.
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
	if FileAccess.file_exists(legacy) or DirAccess.dir_exists_absolute(SaveManagerScript.SLOT_DIR):
		print(C_YELLOW + "SKIP:" + C_RESET + " player data present")
		quit(0)
		return
	_print_header("Save Migration Tests")
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
		_skipped += 1
		print(C_YELLOW + "→" + C_RESET + " (GameState autoload unavailable; skipped restore check)")

	# Idempotent: binding again must not re-migrate or duplicate.
	sm.current_slot = ""
	sm.ensure_bound()
	ok = _check(ok, sm.list_slots().size() == 1, "bind is idempotent")

	_wipe_slots()
	_print_summary()
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
	if result:
		_passes += 1
		print(C_GREEN + "✓" + C_RESET + " " + what)
	else:
		_fails += 1
		print(C_RED + "✗" + C_RESET + " " + what)
	return prev and result


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
