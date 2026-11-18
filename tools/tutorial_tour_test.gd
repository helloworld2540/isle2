extends SceneTree

## Regression harness for the five-step first-playthrough tour
## (scripts/tutorial_director.gd). Asserts the tour advances in order when
## each scene event fires, on a fresh save, and never re-arms once DONE.
##
## Run with --path . so the autoloads resolve:
##   XDG_DATA_HOME=/tmp/isle2_verify godot --headless --path . -s tools/tutorial_tour_test.gd
## XDG_DATA_HOME is isolated; real slots are never touched.

var _fails := 0

func _initialize() -> void:
	await process_frame
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir):
		print("SKIP: slots present at %s, not touching them" % slot_dir)
		quit(0)
		return

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

	print("tutorial_tour_test: %d failure(s)" % _fails)
	quit(_fails)


func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "[FAIL] ") + what)
	if not ok:
		_fails += 1
