extends SceneTree

## Regression harness for the five-step first-playthrough tour
## (scripts/tutorial_director.gd). Asserts the tour advances in order when
## each scene event fires, on a fresh save, and never re-arms once DONE.
##
## Run with --path . so the autoloads resolve:
##   XDG_DATA_HOME=/tmp/isle2_verify godot --headless --path . -s tools/tutorial_tour_test.gd
## XDG_DATA_HOME is isolated; real slots are never touched.

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
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir):
		print(C_YELLOW + "SKIP:" + C_RESET + " slots present at " + slot_dir + ", not touching them")
		quit(0)
		return
	_print_header("Tutorial Tour Tests")

	var sm: Node = root.get_node("SaveManager")
	var td: Node = root.get_node("TutorialDirector")

	# --- Boot: nothing shown yet on a fresh save.
	_check(int(sm.load_game().get("tutorial_step", 0)) == 0, "fresh save: tour step is 0")
	_check(not bool(sm.load_game().get("tutorial_seen", false)), "welcome card not auto-seen")

	# --- Step 1: world entry, move.
	td.start()
	_check(int(sm.load_game().get("tutorial_step", 0)) == 1, "start() arms STEP_MOVE (1)")
	td.notify("move")
	_check(int(sm.load_game().get("tutorial_step", 0)) == 2, "notify('move') advances to STEP_REEF (2)")

	# --- Step 2: reef entry (scene_started itself arms the notify).
	td.scene_started("reef")
	_check(int(sm.load_game().get("tutorial_step", 0)) == 3, "reef scene_started advances to STEP_SORT (3)")

	# --- Step 3: sort at the bench.
	td.notify("sorted")
	_check(int(sm.load_game().get("tutorial_step", 0)) == 4, "notify('sorted') advances to STEP_SELL (4)")

	# --- Step 4: sell at the shop.
	td.notify("sold")
	_check(int(sm.load_game().get("tutorial_step", 0)) == 5, "notify('sold') advances to STEP_FINALE (5)")

	# --- Step 5: finale arms itself; nothing completes it.
	_check(int(sm.load_game().get("tutorial_step", 0)) == 5, "STEP_FINALE does not auto-complete")

	# --- Done: a second world entry never re-arms the tour.
	var step_after := int(sm.load_game().get("tutorial_step", 0))
	td.scene_started("world")
	_check(int(sm.load_game().get("tutorial_step", 0)) == step_after, "tour does not re-arm from scene_started")

	# --- Clean up without touching player slots (isolated XDG dir).
	sm.call_deferred("wipe_slots") if sm.has_method("wipe_slots") else null

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
