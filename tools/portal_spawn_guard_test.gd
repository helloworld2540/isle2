extends SceneTree

## Portal spawn-guard gate.
##
## Leaving a station drops the keeper back on the world map a little outside
## the pad they came out of (RETURN_DISTANCE ≈ 120 px). If they then tap
## somewhere on the far side, the shortest BFS route walks straight over that
## pad — and before the guard they were warped back into the scene they had just
## left. This drives the real world scene and the real player controller:
##
##   1. A keeper who spawns beside a pad is guarded (one who spawns far is not).
##   2. Walking across the pad on the way out does NOT re-enter it.
##   3. Once the keeper is clear, the pad is live again (walking back in enters).
##   4. A walk that deliberately ENDS on the pad still enters, guard or not.
##
## The upcycle pad's entry material is granted up front: with an empty bag the
## pad would refuse entry anyway and hide the very bug this guards against.
##
## Run with autoloads:
##   XDG_DATA_HOME=/tmp/isle2_verify godot --headless --path . -s tools/portal_spawn_guard_test.gd
## Exits 0 on success, 1 on any failure. Wired into tools/all_audits.sh.

const WORLD := "res://scenes/world.tscn"
const UPCYCLE := "res://scenes/upcycle.tscn"
const PORTAL := "PortalUpcycle"
var SaveManagerScript: GDScript
var WorldPortalScript: GDScript

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
	_print_header("Portal Spawn Guard Tests")
	await process_frame
	SaveManagerScript = load("res://scripts/save_manager.gd") as GDScript
	WorldPortalScript = load("res://scripts/wm_portal.gd") as GDScript
	_wipe_slots()

	var gs: Node = root.get_node("GameState")
	if gs and gs.has_method("reset"):
		gs.call("reset")
	# Entry material for the upcycle pad, so a missing guard would really warp
	# the keeper instead of being masked by the pad's own "no Debris" warning.
	(gs.get("trash_by_type") as Dictionary)["Reef Debris"] = 5

	# --- Load 1: baseline. No saved spot, so the keeper spawns at the authored
	# position, far from every pad: nothing should be guarded.
	if not await _reload_world():
		_fail("world.tscn did not load")
		_finish()
		return
	var world: Node = current_scene
	await _settle(world)
	var player: Node = _find_player(world)
	var portal: Node = _find_child_named(world, PORTAL)
	if player == null or portal == null:
		_fail("world is missing the keeper or %s" % PORTAL)
		_finish()
		return
	_check(not bool(portal.get("_spawn_guard_armed")), "pad unguarded when the keeper spawns far away")
	var spawn: Vector2 = (portal as Node2D).global_position + Vector2(WorldPortalScript.RETURN_DISTANCE, 0.0)

	# --- Load 2: as if just out of the station — the keeper spawns 100 px beside
	# the pad, then taps a spot on the far side.
	root.get_node("SaveManager").call("save_player_position", spawn)
	if not await _reload_world():
		_fail("second world load failed")
		_finish()
		return
	world = current_scene
	player = _find_player(world)
	portal = _find_child_named(world, PORTAL)
	if player == null or portal == null:
		_fail("second load is missing the keeper or %s" % PORTAL)
		_finish()
		return
	await _settle(world)
	_check(await _await_guard(portal, true), "pad guarded when the keeper spawns beside it")

	var layer: TileMapLayer = world.get_node("Geography/WorldMap") as TileMapLayer
	var start_cell: Vector2i = layer.local_to_map(layer.to_local((player as Node2D).global_position))
	var far_cell: Vector2i = start_cell + Vector2i(-3, 0)
	(player as Node2D).call("_calculate_path_to", layer.to_global(layer.map_to_local(far_cell)))
	var routed: bool = (player.get("path") as PackedVector2Array).size() > 0
	_check(routed, "the leaving walk produced a route")
	await _wait_idle(player, 12.0)
	# Give a stray transition time to fire before declaring it did not.
	await create_timer(0.8).timeout
	var still_world: bool = _scene_is("world.tscn")
	_check(still_world, "walking across the pad did NOT warp the keeper back in")
	if still_world:
		_check(not bool(portal.get("_spawn_guard_armed")), "guard released once the keeper walked clear")
		# The pad is live again: walk back onto it and expect the real entry.
		(player as Node2D).call("_calculate_path_to", (portal as Node2D).global_position)
		if not await _await_scene("upcycle.tscn", 400):
			_fail("walking back onto the cleared pad did not enter")
		else:
			_ok("walking back onto the cleared pad still enters")

	# --- Load 3: spawn beside the pad and tap the pad itself. The walk ENDS on
	# it, so it must still enter even though the guard was armed at spawn.
	await create_timer(0.8).timeout
	root.get_node("SaveManager").call("save_player_position", spawn)
	if not await _reload_world():
		_fail("third world load failed")
		_finish()
		return
	world = current_scene
	player = _find_player(world)
	portal = _find_child_named(world, PORTAL)
	if player == null or portal == null:
		_fail("third load is missing the keeper or %s" % PORTAL)
		_finish()
		return
	await _settle(world)
	_check(await _await_guard(portal, true), "pad guarded on the third load")
	(player as Node2D).call("_calculate_path_to", (portal as Node2D).global_position)
	if not await _await_scene("upcycle.tscn", 400):
		_fail("a walk that ends on the guarded pad did not enter")
	else:
		_ok("a walk that ends on the guarded pad still enters")

	_finish()


## The first-run welcome guide is modal and pauses the tree, and the portals arm
## their spawn guard on a deferred call. Wait for the guide to land, dismiss it
## (so the keeper can actually walk), then let the tree stay unpaused.
func _settle(world: Node) -> void:
	await create_timer(1.2).timeout
	var calm := 0
	for i in 300:
		if paused:
			calm = 0
			for child in world.get_children():
				if String(child.scene_file_path).ends_with("tutorial.tscn"):
					child.call("_on_dismiss_pressed")
			await create_timer(0.2).timeout
			continue
		for child in world.get_children():
			if String(child.scene_file_path).ends_with("tutorial_hint.tscn") and child.visible:
				child.call("_on_dismiss_pressed")
		calm += 1
		if calm >= 6:
			return
		await create_timer(0.05).timeout


## Polls the pad's guard flag; the deferred arm can land a few frames after the
## scene swap. Returns true once it matches `expected` within `timeout` seconds.
func _await_guard(portal: Node, expected: bool, timeout: float = 3.0) -> bool:
	var waited := 0.0
	while waited < timeout:
		if bool(portal.get("_spawn_guard_armed")) == expected:
			return true
		await create_timer(0.05).timeout
		waited += 0.05
	return bool(portal.get("_spawn_guard_armed")) == expected


## Swaps in a fresh world.tscn and waits for the *new* instance, since the old
## scene is also world.tscn and a path check alone would match instantly.
func _reload_world() -> bool:
	var old: Node = current_scene
	change_scene_to_file(WORLD)
	for i in 400:
		await create_timer(0.05).timeout
		var scene := current_scene
		if scene != null and scene != old and String(scene.scene_file_path).ends_with("world.tscn"):
			return true
	return false


func _scene_is(suffix: String) -> bool:
	var scene := current_scene
	return scene != null and String(scene.scene_file_path).ends_with(suffix)


func _await_scene(suffix: String, frames: int) -> bool:
	for i in frames:
		await create_timer(0.05).timeout
		if _scene_is(suffix):
			return true
	return false


## Blocks until the keeper's BFS run drains (or the keeper leaves the tree).
func _wait_idle(player: Node, timeout: float) -> void:
	var waited := 0.0
	while waited < timeout:
		await create_timer(0.1).timeout
		waited += 0.1
		if not is_instance_valid(player) or not player.is_inside_tree():
			return
		var moving: bool = bool(player.get("is_moving"))
		var path: PackedVector2Array = player.get("path")
		if not moving and path.is_empty():
			return


func _find_player(world: Node) -> Node:
	for child in world.get_children():
		if child is Node2D and (child as Node2D).is_in_group("player"):
			return child
		if child.get_child_count() > 0:
			var nested := _find_player(child)
			if nested != null:
				return nested
	return null


func _find_child_named(parent: Node, wanted: String) -> Node:
	for child in parent.get_children():
		if String(child.name) == wanted:
			return child
		if child.get_child_count() > 0:
			var nested := _find_child_named(child, wanted)
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
