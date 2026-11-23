extends SceneTree

## End-to-end loop harness: World → Reef Rescue → World → Upcycle → World →
## Shop, completing the island circuit.
##
## The unit harnesses each test one scene in isolation; this one proves the
## *connective tissue* the player actually walks: a portal fires the real
## SceneTransition, the minigame loads, a finished run banks its haul into
## GameState, the return trip lands back on the world map, and the next
## portal in the circuit still works afterwards.
##
## Run with autoloads:
##   XDG_DATA_HOME=/tmp/isle2_verify godot --headless --path . -s tools/loop_flow_test.gd
## Refuses to run if real player slots exist. Exits 0 on success, 1 on any
## failure. Wired into tools/all_audits.sh.

const WORLD := "res://scenes/world.tscn"
const REEF := "res://scenes/reef_rescue.tscn"
const UPCYCLE := "res://scenes/upcycle.tscn"
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
	_print_header("Island Loop Flow Tests")

	await process_frame
	_wipe_slots()
	
	# Reset GameState to ensure clean in-memory state
	var gs_reset: Node = root.get_node("GameState")
	if gs_reset and gs_reset.has_method("reset"):
		gs_reset.call("reset")

	# --- World boots as the managed current scene (not a side-attached node),
	# so SceneTransition's change_scene_to_file has a real scene to replace.
	change_scene_to_file(WORLD)
	if not await _await_scene("world.tscn", 200):
		_fail("world.tscn did not load")
		_finish()
		return
	_ok("world.tscn loaded as current_scene")

	var gs: Node = root.get_node("GameState")
	var world: Node = current_scene
	var portal_reef: Node = _find_child_named(world, "PortalReefRescue")
	if portal_reef == null:
		_fail("PortalReefRescue missing from world")
		_finish()
		return
	_check(String(portal_reef.get("target_scene")) == REEF, "reef portal targets reef_rescue.tscn")

	# --- Step through the reef portal the way a player does.
	await _enter_portal(world, portal_reef)
	if not await _await_scene("reef_rescue.tscn", 300):
		_fail("reef portal did not transition into reef_rescue.tscn")
		_finish()
		return
	_ok("reef portal transitioned into reef_rescue.tscn")

	# --- Finish a dive with a known haul and bank it. Let the fade-in finish
	# first: SceneTransition refuses a second change_scene while busy.
	await create_timer(0.8).timeout
	var reef: Node = current_scene
	reef.set("garbage", 12.0)
	reef.set("fish", 0)
	reef.set("depth", 150.0)
	reef.set("running", true)
	var debris_before := int(gs.get("trash_by_type").get("Reef Debris", 0))
	reef.call("_game_over_summary", "manual")
	reef.call("_leave_after_summary")
	if not await _await_scene("world.tscn", 400):
		_fail("reef summary did not return to the world map")
		_finish()
		return
	_ok("reef summary returned to the world map")
	var debris_after := int(gs.get("trash_by_type").get("Reef Debris", 0))
	_check(debris_after > debris_before, "finished dive banked Reef Debris (%d → %d)" % [debris_before, debris_after])
	_check(int(gs.get("reef_dives")) >= 1, "finished dive recorded in dive count")

	# --- The world must still be drivable after a round trip: the next portal
	# in the circuit must fire too.
	world = current_scene
	var portal_upcycle: Node = _find_child_named(world, "PortalUpcycle")
	if portal_upcycle == null:
		_fail("PortalUpcycle missing after returning from the reef")
		_finish()
		return
	_check(String(portal_upcycle.get("target_scene")) == UPCYCLE, "upcycle portal targets upcycle.tscn")
	await _enter_portal(world, portal_upcycle)
	if not await _await_scene("upcycle.tscn", 300):
		_fail("upcycle portal did not transition after a reef round trip")
		_finish()
		return
	_ok("upcycle portal transitioned into upcycle.tscn after a reef round trip")

	# --- Upcycle returns to the map like the reef does. Leaving always raises
	# its summary card first (even for an untouched bench), whose Return button
	# is the actual transition.
	await create_timer(0.8).timeout
	current_scene.call("_leave_to_map")
	await create_timer(0.2).timeout
	current_scene.call("_game_over_leave")
	if not await _await_scene("world.tscn", 400):
		_fail("upcycle did not return to the world map")
		_finish()
		return
	_ok("upcycle returned to the world map")

	# --- Third leg completes the island circuit: the shop portal must fire and
	# the $15 circuit bonus must be paid exactly once.
	world = current_scene
	var portal_shop: Node = _find_child_named(world, "PortalShop")
	if portal_shop == null:
		_fail("PortalShop missing after the upcycle round trip")
		_finish()
		return
	var money_before := int(gs.get("money"))
	await _enter_portal(world, portal_shop)
	if not await _await_scene("shop.tscn", 300):
		_fail("shop portal did not transition")
		_finish()
		return
	_ok("shop portal transitioned into shop.tscn, completing the circuit")
	_check(int(gs.get("circuits_completed")) == 1, "island circuit counted once")
	_check(int(gs.get("money")) == money_before + 15, "circuit bonus paid $15 (%d → %d)" % [money_before, int(gs.get("money"))])

	_finish()

## Wait until the player's pad grace period has passed, move the player onto the
## pad and fire the portal's real entry handler.
func _enter_portal(world: Node, portal: Node) -> void:
	var player: Node2D = null
	for child in world.get_children():
		if child is Node2D and (child as Node2D).is_in_group("player"):
			player = child as Node2D
			break
	if player == null:
		_fail("no player node in the world scene")
		return
	# wm_portal ignores entries for 900 ms after the world loads.
	await create_timer(1.0).timeout
	if portal.has_method("_on_body_entered"):
		player.global_position = (portal as Node2D).global_position
		portal.call("_on_body_entered", player)
	else:
		_fail("portal %s has no _on_body_entered" % portal.name)

## Poll until current_scene's file ends with `suffix`, up to `frames` ticks of
## 50 ms. Returns true when it lands.
func _await_scene(suffix: String, frames: int) -> bool:
	for i in frames:
		await create_timer(0.05).timeout
		var scene := current_scene
		if scene != null and String(scene.scene_file_path).ends_with(suffix):
			return true
	return false

func _find_child_named(parent: Node, wanted: String) -> Node:
	for child in parent.get_children():
		if String(child.name) == wanted:
			return child
		if child.get_child_count() > 0:
			var nested: Node = _find_child_named(child, wanted)
			if nested != null:
				return nested
	return null

func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
		print(C_GREEN + "✓" + C_RESET + " " + label)
	else:
		_fails += 1
		print(C_RED + "✗" + C_RESET + " " + label)

func _ok(label: String) -> void:
	_passes += 1
	print(C_GREEN + "✓" + C_RESET + " " + label)

func _fail(label: String) -> void:
	_fails += 1
	print(C_RED + "✗" + C_RESET + " " + label)

func _finish() -> void:
	_print_summary()
	await process_frame
	quit(0 if _fails == 0 else 1)

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

func _wipe_slots() -> void:
	var slot_dir_abs := ProjectSettings.globalize_path(SaveManagerScript.SLOT_DIR)
	var root_dir := DirAccess.open(slot_dir_abs)
	if root_dir:
		for sub in root_dir.get_directories():
			var path := "%s/%s" % [slot_dir_abs, sub]
			var d := DirAccess.open(path)
			if d:
				for f in d.get_files():
					DirAccess.remove_absolute("%s/%s" % [path, f])
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(slot_dir_abs)
