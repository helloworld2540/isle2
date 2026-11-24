extends SceneTree

## Corrupt-save fuzz gate for the GameState codec.
##
## A save can be hand-edited, half-written by a crash, or half-synced from a
## cloud backup. `restore()` must degrade each bad field to a safe default —
## never abort halfway and leave the island with a mix of old and new values,
## and never let a hostile number poison the economy (negative money, INT64
## overflow from 1e30, bag keys that do not exist).
##
## Technique: before each hostile payload, seed visible marker values directly
## on the autoload. If `restore()` aborts on a type error, the markers survive
## (the function returned early), so both "did not crash" and "fully restored"
## are proven in one shot.
##
## Run with autoloads:
##   XDG_DATA_HOME=/tmp/isle2_verify godot --headless --path . -s tools/save_fuzz_test.gd
## Refuses to run if real player slots exist. Exits 0 on success, 1 otherwise.
## Wired into tools/all_audits.sh.

## Real materials — the bag must never hold anything else. Derived from the
## production trash table so the gate cannot drift from the game.
var GameStateScript: GDScript
var SaveManagerScript: GDScript
var MATERIALS: Array[String] = []

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
	await process_frame
	GameStateScript = load("res://scripts/game_state.gd") as GDScript
	SaveManagerScript = load("res://scripts/save_manager.gd") as GDScript
	for t in GameStateScript.DEFAULT_TRASH_TYPES:
		MATERIALS.append(String(t))
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir) and not DirAccess.get_files_at(slot_dir).is_empty():
		print(C_YELLOW + "SKIP:" + C_RESET + " player slots present at " + slot_dir + ", not touching them")
		quit(0)
		return
	_print_header("Corrupt-Save Fuzz Tests")

	var sm: Node = root.get_node("SaveManager")
	var gs: Node = root.get_node("GameState")
	sm.call("ensure_bound")
	var save_path := ProjectSettings.globalize_path("user://slots/island/save.json")
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())

	_hostile_cases(gs, save_path)
	_positive_case(gs, save_path)

	_print_summary()
	await process_frame
	quit(0 if _fails == 0 else 1)

## Every hostile payload is written, then restore() is called with markers
## primed. All invariants must hold afterwards.
func _hostile_cases(gs: Node, save_path: String) -> void:
	var cases: Array = [
		{"label": "money as a word", "payload": {"money": "lots"}},
		{"label": "money as an object", "payload": {"money": {"a": 1}}},
		{"label": "money negative", "payload": {"money": -500, "lifetime_earnings": -9}},
		{"label": "best depth as 1e30", "payload": {"best_reef_depth": 1e30}},
		{"label": "best depth NaN", "payload": {"best_reef_depth": "NaN"}},
		{"label": "bag as an array", "payload": {"trash_by_type": [1, 2, 3]}},
		{"label": "bag with a junk value", "payload": {"trash_by_type": {"Glass": "nine"}}},
		{"label": "bag with an unknown material", "payload": {"trash_by_type": {"Glass": 4, "Unobtanium": 99}}},
		{"label": "bottles as a string", "payload": {"bottles_read": "notanarray"}},
		{"label": "last run as a string", "payload": {"last_run": "oops"}},
		{"label": "achievements as an object", "payload": {"achievements": {"x": true}}},
		{"label": "bool as a word", "payload": {"deep_cache": "definitely", "tidekeeper": "true"}},
	]
	for case in cases:
		_write_payload(save_path, case["payload"])
		_prime_markers(gs)
		gs.call("restore")
		_check_invariants(gs, String(case["label"]))

func _positive_case(gs: Node, save_path: String) -> void:
	# A valid save must still restore exactly — the sanitising must not round
	# real values away, and courier_letter_day's -1 sentinel must survive.
	var payload := _valid_save_payload()
	payload["money"] = 4242
	payload["lifetime_earnings"] = 9999
	payload["best_reef_depth"] = 742
	payload["deep_cache"] = true
	payload["courier_letter_day"] = -1
	payload["bottles_read"] = ["bottle_tide", "bottle_gull"]
	payload["trash_by_type"] = {"Glass": 3, "Reef Debris": 5}
	_write_payload(save_path, payload)
	_prime_markers(gs)
	gs.call("restore")
	_check(int(gs.get("money")) == 4242, "valid save: money restored exactly")
	_check(int(gs.get("best_reef_depth")) == 742, "valid save: depth restored exactly")
	_check(bool(gs.get("deep_cache")), "valid save: bool restored")
	_check(int(gs.get("courier_letter_day")) == -1, "valid save: -1 sentinel preserved")
	_check(int((gs.get("trash_by_type") as Dictionary).get("Glass", -1)) == 3, "valid save: Glass restored")
	_check(int((gs.get("trash_by_type") as Dictionary).get("Reef Debris", -1)) == 5, "valid save: Reef Debris restored")
	_check((gs.get("bottles_read") as Array).size() == 2, "valid save: read bottles restored")

## Seed values that a successful restore MUST overwrite. If restore aborts on
## a type error, at least one marker survives and the case fails.
func _prime_markers(gs: Node) -> void:
	gs.set("money", 777)
	gs.set("best_reef_depth", 777)
	gs.set("courier_letter_day", 777)
	gs.set("deep_cache", true)
	var bottles: Array = gs.get("bottles_read")
	bottles.clear()
	bottles.append("MARKER")
	var bag: Dictionary = gs.get("trash_by_type")
	bag.clear()
	bag["Glass"] = 3
	gs.call("_recompute_inventory")

func _check_invariants(gs: Node, label: String) -> void:
	_check(int(gs.get("money")) != 777, "%s: restore completed (money overwritten)" % label)
	_check(int(gs.get("money")) >= 0, "%s: money is non-negative" % label)
	_check(int(gs.get("best_reef_depth")) >= 0 and int(gs.get("best_reef_depth")) <= 9_000_000_000_000,
		"%s: depth in safe range (%d)" % [label, int(gs.get("best_reef_depth"))])
	_check(int(gs.get("courier_letter_day")) != 777, "%s: sentinel key overwritten" % label)
	var bag: Dictionary = gs.get("trash_by_type")
	var bag_ok := bag.size() == MATERIALS.size()
	for mat in MATERIALS:
		if not bag.has(mat) or not (bag[mat] is int) or int(bag[mat]) < 0:
			bag_ok = false
	_check(bag_ok, "%s: bag holds exactly the five materials as non-negative ints" % label)
	var bottles: Array = gs.get("bottles_read")
	var bottles_ok := true
	for b in bottles:
		if not b is String:
			bottles_ok = false
	_check(bottles_ok, "%s: bottles_read is a string list" % label)
	_check(gs.get("last_run") is Dictionary, "%s: last_run is a dictionary" % label)

## A structurally valid save: one entry per GameState.SAVE_SCHEMA key (with the
## production defaults), plus the slot-file identity SaveManager stamps on write.
## The positive case then overrides the fields it wants to pin, so the valid-save
## key set is derived from the schema rather than hand-copied.
func _valid_save_payload() -> Dictionary:
	var payload: Dictionary = {"save_version": SaveManagerScript.SAVE_VERSION}
	for e in GameStateScript.SAVE_SCHEMA:
		var key: String = String(e[0])
		var codec: String = String(e[3])
		var def: Variant = e[2]
		match codec:
			"int":
				payload[key] = int(def)
			"float":
				payload[key] = float(def)
			"bool":
				payload[key] = bool(def)
			"string":
				payload[key] = String(def)
			"string_array":
				payload[key] = []
			"dict":
				payload[key] = {}
	return payload

func _write_payload(save_path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
		print(C_GREEN + "✓" + C_RESET + " " + label)
	else:
		_fails += 1
		print(C_RED + "✗" + C_RESET + " " + label)


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
