extends SceneTree

## Regression harness for THE KEEPER'S STAR.
##
## Run with --path . so the project autoloads resolve:
##   XDG_DATA_HOME=/tmp/isle2_verify godot --headless --path . -s tools/keeper_star_test.gd
## XDG_DATA_HOME isolates the user data dir; the test refuses to run if player
## slots already exist there, and cleans up after itself either way.
const AchievementCatalog := preload("res://scripts/achievement_catalog.gd")

var _fails := 0

func _initialize() -> void:
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir):
		print("SKIP: slots present at %s, not touching them" % slot_dir)
		quit(0)
		return

	var gs: Node = root.get_node("GameState")

	# --- 1. Fresh boot: the star must free itself (no capstone yet).
	var star1: Node = load("res://scenes/wm_keeper_star.tscn").instantiate()
	root.add_child(star1)
	await process_frame
	_check(not is_instance_valid(star1) or star1.is_queued_for_deletion(),
		"fresh save: star frees itself (no ISLAND STEWARD)")

	# --- 2. Seed the capstone in the in-memory autoload, then persist.
	var ids: Array[String] = []
	for def in AchievementCatalog.definitions():
		var id := String(def.get("id", ""))
		if id != "keeper_star" and id != "island_steward":
			ids.append(id)
	ids.append("island_steward")
	gs.unlocked_achievements = ids
	gs.keeper_star_found = false
	gs._evaluate_achievements(true)
	_check(gs.is_achievement_unlocked("island_steward"), "capstone granted in memory")
	gs.flush_save()

	# --- 3. A fresh boot of the world with the capstone must show the star.
	var star2: Node = load("res://scenes/wm_keeper_star.tscn").instantiate()
	root.add_child(star2)
	await process_frame
	_check(is_instance_valid(star2) and not star2.is_queued_for_deletion(),
		"steward save: star persists at the far point")

	# --- 4. Collecting it: flag flips, payout once, achievement fires.
	var money_before: int = gs.money
	gs.mark_keeper_star_found()
	_check(gs.keeper_star_found, "keeper_star_found flips on find")
	_check(gs.money == money_before + 50, "one-time +$50 payout (%d)" % (gs.money - money_before))
	gs.mark_keeper_star_found()
	_check(gs.money == money_before + 50, "second call does not pay twice")
	_check(gs.is_achievement_unlocked("keeper_star"), "THE KEEPER'S STAR achievement fires")

	# --- 5. Schema round-trip: save → restore keeps the flag and the payout.
	gs.flush_save()
	gs.keeper_star_found = false
	gs.money = 0
	gs.restore()
	_check(gs.keeper_star_found, "keeper_star_found survives the schema round-trip")
	_check(gs.money == money_before + 50, "money survives the round-trip (%d)" % gs.money)

	# --- 6. Capstone does not depend on the star (no circular unlock).
	gs.unlocked_achievements.erase("keeper_star")
	_check(AchievementCatalog.is_met("island_steward", gs),
		"capstone does not require THE KEEPER'S STAR")

	star2.queue_free()
	_wipe()
	print("keeper_star_test: %d failure(s)" % _fails)
	quit(_fails)

func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "[FAIL] ") + what)
	if not ok:
		_fails += 1

func _wipe() -> void:
	var base := ProjectSettings.globalize_path("user://slots")
	_remove_dir(base)

func _remove_dir(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	for entry in d.get_directories():
		_remove_dir(path + "/" + entry)
	for f in d.get_files():
		DirAccess.remove_absolute(path + "/" + f)
	DirAccess.remove_absolute(path)