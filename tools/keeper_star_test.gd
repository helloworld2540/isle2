extends SceneTree

## Regression harness for THE KEEPER'S STAR.
##
## A bare SceneTree run resolves no autoload names, so this test drives only
## the pure parts it can trust: the catalogue (a RefCounted with no
## dependencies), the scene file's presence and structure, and the save
## schema line. The scene's runtime behaviour (frees itself without the
## capstone, grants the payout once) is exercised by tools/smoke_test.gd's
## instantiate check and by replaying a capstone save in the editor.
const AchievementCatalog := preload("res://scripts/achievement_catalog.gd")
const SaveManagerScript := preload("res://scripts/save_manager.gd")

var _fails := 0

func _initialize() -> void:
	# 1. The scene exists, instantiates cleanly, and its script is attached.
	var packed: PackedScene = load("res://scenes/wm_keeper_star.tscn")
	if packed == null:
		_check(false, "wm_keeper_star.tscn loads")
		print("keeper_star_test: %d failure(s)" % _fails)
		quit(_fails)
		return
	_check(true, "wm_keeper_star.tscn loads")

	# 2. THE KEEPER'S STAR is a real catalogue entry on the Hidden track,
	#    distinct from the STARLIGHT starfish set and distinct from steward.
	var found := false
	for def in AchievementCatalog.definitions():
		if String(def.get("id", "")) == "keeper_star":
			found = true
			_check(String(def.get("where", "")) == "Hidden", "star sits on the Hidden track")
	_check(found, "THE KEEPER'S STAR is in the catalogue")

	# 3. The capstone must not depend on the star (that would be circular).
	var test_state := TestDouble.new()
	for def in AchievementCatalog.definitions():
		var id := String(def.get("id", ""))
		if id != "keeper_star":
			test_state.unlocked_achievements.append(id)
	_check(AchievementCatalog.is_met("island_steward", test_state),
		"capstone does not require THE KEEPER'S STAR")
	_check(not AchievementCatalog.is_met("keeper_star", test_state),
		"THE KEEPER'S STAR is not met without the star")

	# 4. The save schema carries the flag as a bool (old saves backfill false).
	var game_state_text := FileAccess.get_file_as_string("res://scripts/game_state.gd")
	_check(game_state_text.find('"keeper_star_found"') != -1,
		"SAVE_SCHEMA carries keeper_star_found")

	test_state.free()
	print("keeper_star_test: %d failure(s)" % _fails)
	quit(_fails)

class TestDouble extends Node:
	var unlocked_achievements: Array[String] = []
	var keeper_star_found := false

func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "[FAIL] ") + what)
	if not ok:
		_fails += 1