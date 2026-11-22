extends SceneTree
## Portal reachability audit.
##
## The world map's tap-to-walk uses BFS over cells flagged Walkable in the
## TileSet's custom data. If a tileset edit ever flips the flag on the row
 ## the portals / NPCs / the player stand on, the island softlocks: taps
## route nowhere and the tutorial's reef step can never be reached.
##
## Asserts, on the real world.tscn:
##   1. The Player's spawn cell is walkable.
##   2. Every Portal* node stands on a walkable cell OR touches one of the
##      four walkable cells around it (a pad one cell off the path is still
##      fair — the player must be able to stand next to it to be detected).
##   3. Every WorldNPC (under NPCs/) stands on or adjoins a walkable cell,
##      so quests and gifts can never be stranded off the path.
##   4. At least one full path exists from spawn to the reef portal via BFS.
##   5. Every authored collectible (Bottle*, Starfish*, KeeperStar,
##      FarPointWatcher) stands on or adjoins a walkable cell. These nodes
##      are freed at runtime by their unlock logic, so their placement is
##      read straight from world.tscn's text — the authored truth, not the
##      post-lock scene tree.
##
## Run:  godot --headless --path . -s tools/portal_reach_test.gd
## Exits 0 on success, 1 on any failure. Wired into tools/all_audits.sh.

## Node-name prefixes for authored world content whose placement must stay
## reachable. Kept as a list so new collectibles are one word added here.
const CONTENT_PREFIXES: Array[String] = ["Bottle", "Starfish", "KeeperStar", "FarPointWatcher"]

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
	_print_header("Portal Reachability Tests")
	var scene: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	var layer: TileMapLayer = scene.get_node_or_null("WorldMap") as TileMapLayer
	var player: Node2D = scene.get_node_or_null("Player") as Node2D
	if layer == null or player == null:
		_fail("WorldMap layer or Player missing")
		_quit(1)
		return

	var spawn_cell: Vector2i = layer.local_to_map(layer.to_local(player.global_position))
	if _walkable(layer, spawn_cell):
		_ok("spawn cell %s walkable" % spawn_cell)
	else:
		_fail("spawn cell %s NOT walkable" % spawn_cell)

	for child in scene.get_children():
		if not String(child.name).begins_with("Portal"):
			continue
		if not child is Area2D:
			continue
		var cell: Vector2i = layer.local_to_map(layer.to_local((child as Node2D).global_position))
		if _walkable(layer, cell) or _has_walkable_neighbour(layer, cell):
			_ok("%s at %s reachable" % [child.name, cell])
		else:
			_fail("%s at %s has no walkable cell to stand on" % [child.name, cell])

	# NPCs: quests/gifts must never be unreachable.
	var npcs_node: Node = scene.get_node_or_null("NPCs")
	if npcs_node == null:
		_fail("NPCs group missing")
	else:
		for npc in npcs_node.get_children():
			if not npc is Area2D:
				continue
			var cell: Vector2i = layer.local_to_map(layer.to_local((npc as Node2D).global_position))
			if _walkable(layer, cell) or _has_walkable_neighbour(layer, cell):
				_ok("NPC %s reachable" % npc.name)
			else:
				_fail("NPC %s has no walkable cell to stand on" % npc.name)

	# Collectibles: read authored placements from the scene file (their runtime
	# nodes are freed by the unlock logic before this audit sees the tree).
	_fails += _authored_placement_audit(layer)

	# BFS from spawn; must be able to reach the reef portal's neighbourhood.
	var reef: Node2D = null
	for child in scene.get_children():
		if String(child.name) == "PortalReefRescue":
			reef = child as Node2D
	if reef == null:
		_fail("PortalReefRescue missing (children: %s)" % [scene.get_children().map(func(c): return str(c.name))])
	else:
		var reef_cell: Vector2i = layer.local_to_map(layer.to_local(reef.global_position))
		if _bfs_reaches(layer, spawn_cell, reef_cell):
			_ok("BFS path spawn -> reef portal")
		else:
			_fail("no BFS path from spawn %s to reef cell %s" % [spawn_cell, reef_cell])

	_print_summary()
	_quit(0 if _fails == 0 else 1)

## Scans world.tscn's source text for authored content nodes and verifies each
## one's authored `position` lands on or beside a walkable cell. Returns the
## number of failures. Positions are the values the level designer wrote, so
## this gate catches a collectible dropped into rock regardless of the
## runtime unlock logic having freed it.
func _authored_placement_audit(layer: TileMapLayer) -> int:
	var fails := 0
	var text: String = FileAccess.get_file_as_string("res://scenes/world.tscn")
	if text.is_empty():
		print(C_RED + "✗" + C_RESET + " could not read scenes/world.tscn for placement audit")
		return 1
	var name_re := RegEx.create_from_string('^\\[node name="([^"]+)"')
	var pos_re := RegEx.create_from_string('^position = Vector2\\(([-0-9.]+), ([-0-9.]+)\\)')
	var pending_name := ""
	var checked := 0
	for line in text.split("\n"):
		var nm := name_re.search(line)
		if nm != null:
			pending_name = nm.get_string(1)
			continue
		if pending_name.is_empty():
			continue
		var pm := pos_re.search(line)
		if pm == null:
			continue
		var node_name := pending_name
		pending_name = ""
		var matches := false
		for prefix in CONTENT_PREFIXES:
			if node_name.begins_with(prefix):
				matches = true
				break
		if not matches:
			continue
		checked += 1
		var world_pos := Vector2(float(pm.get_string(1)), float(pm.get_string(2)))
		var cell: Vector2i = layer.local_to_map(layer.to_local(world_pos))
		if _walkable(layer, cell) or _has_walkable_neighbour(layer, cell):
			_ok("%s authored at %s reachable" % [node_name, cell])
		else:
			print(C_RED + "✗" + C_RESET + " " + "%s authored at %s has no walkable cell to stand on" % [node_name, cell])
			fails += 1
	if checked == 0:
		print(C_RED + "✗" + C_RESET + " authored placement audit matched 0 content nodes — did the scene format change?")
		fails += 1
	return fails

func _walkable(layer: TileMapLayer, cell: Vector2i) -> bool:
	var td := layer.get_cell_tile_data(cell)
	return td != null and td.get_custom_data("Walkable") == true

func _has_walkable_neighbour(layer: TileMapLayer, cell: Vector2i) -> bool:
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if _walkable(layer, cell + dir):
			return true
	return false

func _bfs_reaches(layer: TileMapLayer, start: Vector2i, goal: Vector2i) -> bool:
	var visited := {start: true}
	var queue: Array[Vector2i] = [start]
	var found := false
	while not queue.is_empty() and not found:
		var current: Vector2i = queue.pop_front()
		if current == goal:
			found = true
			break
		for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var next: Vector2i = current + dir
			if visited.has(next):
				continue
			if _walkable(layer, next):
				visited[next] = true
				queue.append(next)
	# The reef pad itself might be unwalkable (it is a trigger); standing next
	# to it is enough.
	if not found:
		for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			if visited.has(goal + dir):
				return true
	return found

func _ok(label: String) -> void:
	_passes += 1
	print(C_GREEN + "✓" + C_RESET + " " + label)

func _fail(label: String) -> void:
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

func _quit(code: int) -> void:
	await process_frame
	quit(code)
