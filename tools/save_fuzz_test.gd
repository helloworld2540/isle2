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

## Real materials — the bag must never hold anything else.
const MATERIALS: Array[String] = ["Polyethylene", "Polypropylene", "Glass", "Nylon", "Reef Debris"]

var _fails := 0

func _initialize() -> void:
	await process_frame
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir) and not DirAccess.get_files_at(slot_dir).is_empty():
		print("SKIP: player slots present at %s, not touching them" % slot_dir)
		quit(0)
		return

	var sm: Node = root.get_node("SaveManager")
	var gs: Node = root.get_node("GameState")
	sm.call("ensure_bound")
	var save_path := ProjectSettings.globalize_path("user://slots/island/save.json")
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())

	_hostile_cases(gs, save_path)
	_positive_case(gs, save_path)

	print("save_fuzz_test: %s" % ("PASS" if _fails == 0 else "%d failure(s)" % _fails))
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
	var payload := {
		"save_version": 1,
		"money": 4242,
		"lifetime_earnings": 9999,
		"best_reef_depth": 742,
		"deep_cache": true,
		"courier_letter_day": -1,
		"bottles_read": ["bottle_tide", "bottle_gull"],
		"trash_by_type": {"Glass": 3, "Reef Debris": 5},
	}
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

func _write_payload(save_path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

func _check(condition: bool, label: String) -> void:
	if condition:
		print("ok  %s" % label)
	else:
		print("FAIL %s" % label)
		_fails += 1
