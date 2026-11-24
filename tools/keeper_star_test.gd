extends SceneTree

## Regression harness for THE KEEPER'S STAR.
##
## Run with --path . so the project autoloads resolve:
##   XDG_DATA_HOME=/tmp/isle2_verify godot --headless --path . -s tools/keeper_star_test.gd
## XDG_DATA_HOME isolates the user data dir; the test refuses to run if player
## slots already exist there, and cleans up after itself either way.
const AchievementCatalog := preload("res://scripts/achievement_catalog.gd")
var GameStateScript: GDScript

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
	GameStateScript = load("res://scripts/game_state.gd") as GDScript
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir):
		print(C_YELLOW + "SKIP:" + C_RESET + " slots present at " + slot_dir + ", not touching them")
		quit(0)
		return
	_print_header("Keeper's Star Tests")

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
	_check(gs.money == money_before + GameStateScript.KEEPER_STAR_MONEY, "one-time +$50 payout (%d)" % (gs.money - money_before))
	gs.mark_keeper_star_found()
	_check(gs.money == money_before + GameStateScript.KEEPER_STAR_MONEY, "second call does not pay twice")
	_check(gs.is_achievement_unlocked("keeper_star"), "THE KEEPER'S STAR achievement fires")

	# --- 5. Schema round-trip: save → restore keeps the flag and the payout.
	gs.flush_save()
	gs.keeper_star_found = false
	gs.money = 0
	gs.restore()
	_check(gs.keeper_star_found, "keeper_star_found survives the schema round-trip")
	_check(gs.money == money_before + GameStateScript.KEEPER_STAR_MONEY, "money survives the round-trip (%d)" % gs.money)

	# --- 6. Capstone does not depend on the star (no circular unlock).
	gs.unlocked_achievements.erase("keeper_star")
	_check(AchievementCatalog.is_met("island_steward", gs),
		"capstone does not require THE KEEPER'S STAR")

	star2.queue_free()
	_wipe()
	_print_summary()
	quit(_fails)

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