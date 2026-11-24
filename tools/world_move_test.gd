extends SceneTree

## World-map movement gate.
##
## The tutorial's first beat is "tap the ground and walk there", and the world
## map is the player's only way around the island. This drives the real player
## controller on the real world.tscn: a tap on a walkable cell must produce a
## path, actually move the keeper to that cell, light the tutorial's step 2 and
## clear the path highlight when it arrives. A tap on water must fall back to
## the nearest walkable cell instead of doing nothing (the old soft-lock class:
## tap routes nowhere, tutorial never advances).
##
## Run with autoloads:
##   XDG_DATA_HOME=/tmp/isle2_verify godot --headless --path . -s tools/world_move_test.gd
## Refuses to run if real player slots exist. Exits 0 on success, 1 otherwise.
## Wired into tools/all_audits.sh.

const WORLD := "res://scenes/world.tscn"

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
	if DirAccess.dir_exists_absolute(slot_dir) and not DirAccess.get_files_at(slot_dir).is_empty():
		print(C_YELLOW + "SKIP:" + C_RESET + " player slots present at " + slot_dir + ", not touching them")
		quit(0)
		return
	_print_header("World Map Movement Tests")

	change_scene_to_file(WORLD)
	if not await _await_scene("world.tscn", 200):
		_fail("world.tscn did not load")
		_finish()
		return

	var world: Node = current_scene
	var player: Node = _find_player(world)
	var layer: TileMapLayer = world.get_node("Geography/WorldMap") as TileMapLayer
	if player == null or layer == null:
		_fail("player or WorldMap missing")
		_finish()
		return

	# --- Dismiss the first-run welcome guide the way a player does. It pauses
	# the tree while it is up, which would freeze the keeper before the tap.
	if not await _dismiss_welcome_guide(world):
		_fail("welcome guide never appeared or never dismissed")
		_finish()
		return
	var td: Node = root.get_node("TutorialDirector")
	_check(_step_number() == 1, "tour armed at step 1 before moving")

	# --- A tap on walkable ground walks there and advances the tour.
	var start_cell := layer.local_to_map(layer.to_local((player as Node2D).global_position))
	var target_cell := _find_walkable_near(layer, start_cell, 4)
	_check(target_cell != start_cell, "found a second walkable cell within 4 tiles")
	var target_world: Vector2 = layer.to_global(layer.map_to_local(target_cell))
	(player as Node2D).call("_calculate_path_to", target_world)
	_check((player as Node).get("path").size() > 0, "tap produced a path")
	_check(_step_number() == 2, "tap lit tutorial step 2 (move)")
	_ok("walking from %s to cell %s…" % [start_cell, target_cell])
	var arrived := await _wait_arrival(player, target_cell, layer, _arrival_timeout(player))
	_check(arrived, "keeper reached the tapped cell")
	_check((player as Node).get("path").is_empty(), "path cleared after arrival")
	_check(_step_number() == 2, "tour did not regress after moving")

	# --- A tap on water must still route somewhere.
	var water_cell: Variant = _find_unwalkable_near(layer, target_cell, 4)
	if water_cell != null:
		(player as Node2D).call("_calculate_path_to", layer.to_global(layer.map_to_local(water_cell)))
		_check((player as Node).get("path").size() > 0, "water tap fell back to a walkable cell instead of dead-routing")
	else:
		_skipped += 1
		print(C_YELLOW + "→" + C_RESET + " (no unwalkable cell in range to test the fallback)")

	_finish()

## The tour step persists to the save; that is the value every other scene
## reads, so it is the honest one to assert on.
func _step_number() -> int:
	var sm: Node = root.get_node("SaveManager")
	return int(sm.call("load_game").get("tutorial_step", 0))

## Plays the first-run card queue like a player: the step-1 hint owns the
## screen first (non-modal), then the welcome guide (modal) pauses the tree.
## Both are dismissed through their own buttons, so the tour is armed and the
## keeper can move.
func _dismiss_welcome_guide(world: Node) -> bool:
	for i in 300:
		await create_timer(0.05).timeout
		if paused:
			for child in world.get_children():
				if String(child.scene_file_path).ends_with("tutorial.tscn"):
					child.call("_on_dismiss_pressed")
			await create_timer(0.2).timeout
			return not paused
		for child in world.get_children():
			if String(child.scene_file_path).ends_with("tutorial_hint.tscn") and child.visible:
				child.call("_on_dismiss_pressed")
	return false

func _find_player(world: Node) -> Node:
	for child in world.get_children():
		if child is Node2D and (child as Node2D).is_in_group("player"):
			return child
		if child.get_child_count() > 0:
			var nested := _find_player(child)
			if nested != null:
				return nested
	return null

func _find_walkable_near(layer: TileMapLayer, centre: Vector2i, radius: int) -> Vector2i:
	for r in range(1, radius + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var cell := centre + Vector2i(dx, dy)
				if _walkable(layer, cell):
					return cell
	return centre

func _find_unwalkable_near(layer: TileMapLayer, centre: Vector2i, radius: int) -> Variant:
	for r in range(1, radius + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var cell := centre + Vector2i(dx, dy)
				if not _walkable(layer, cell):
					return cell
	return null

func _walkable(layer: TileMapLayer, cell: Vector2i) -> bool:
	var td := layer.get_cell_tile_data(cell)
	return td != null and td.get_custom_data("Walkable") == true

## Arrival budget for a tap-to-move walk, derived from production tuning rather
## than a hard-coded window: the design-time fallback radius (world tiles) priced
## at the production move time per tile.
func _arrival_timeout(player: Node) -> float:
	var world_player_script := load("res://scripts/wm_player.gd") as GDScript
	return float(world_player_script.FALLBACK_RADIUS) * float(player.get("MOVE_TIME"))

func _wait_arrival(player: Node, cell: Vector2i, layer: TileMapLayer, timeout: float) -> bool:
	var waited := 0.0
	while waited < timeout:
		await create_timer(0.1).timeout
		waited += 0.1
		var now := layer.local_to_map(layer.to_local((player as Node2D).global_position))
		if now == cell:
			return true
	return false

func _await_scene(suffix: String, frames: int) -> bool:
	for i in frames:
		await create_timer(0.05).timeout
		var scene := current_scene
		if scene != null and String(scene.scene_file_path).ends_with(suffix):
			return true
	return false

## Quitting while the world's tweens and timers are mid-flight makes the
## headless process crash at teardown; free the scene and let the tree settle.
func _shutdown_cleanly() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	await create_timer(0.3).timeout
	await process_frame
	quit(0 if _fails == 0 else 1)

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
	await _shutdown_cleanly()

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
