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
##   5. Hidden collectibles (story bottles, starfish) and the watcher flag
##      the same on their cells — content can never be buried in rock.
##
## Run:  godot --headless --path . -s tools/portal_reach_test.gd
## Exits 0 on success, 1 on any failure. Wired into tools/all_audits.sh.

func _initialize() -> void:
	var scene: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	var layer: TileMapLayer = scene.get_node_or_null("WorldMap") as TileMapLayer
	var player: Node2D = scene.get_node_or_null("Player") as Node2D
	if layer == null or player == null:
		print("FAIL: WorldMap layer or Player missing")
		_quit(1)
		return

	var fails := 0
	var spawn_cell: Vector2i = layer.local_to_map(layer.to_local(player.global_position))
	if _walkable(layer, spawn_cell):
		print("ok  spawn cell %s walkable" % spawn_cell)
	else:
		print("FAIL spawn cell %s NOT walkable" % spawn_cell)
		fails += 1

	for child in scene.get_children():
		if not String(child.name).begins_with("Portal"):
			continue
		if not child is Area2D:
			continue
		var cell: Vector2i = layer.local_to_map(layer.to_local((child as Node2D).global_position))
		if _walkable(layer, cell) or _has_walkable_neighbour(layer, cell):
			print("ok  %s at %s reachable" % [child.name, cell])
		else:
			print("FAIL %s at %s has no walkable cell to stand on" % [child.name, cell])
			fails += 1

	# NPCs: quests/gifts must never be unreachable.
	var npcs_node: Node = scene.get_node_or_null("NPCs")
	if npcs_node == null:
		print("FAIL NPCs group missing")
		fails += 1
	else:
		for npc in npcs_node.get_children():
			if not npc is Area2D:
				continue
			var cell: Vector2i = layer.local_to_map(layer.to_local((npc as Node2D).global_position))
			if _walkable(layer, cell) or _has_walkable_neighbour(layer, cell):
				print("ok  NPC %s reachable" % npc.name)
			else:
				print("FAIL NPC %s has no walkable cell to stand on" % npc.name)
				fails += 1

	# Collectibles and watchers flagged with gameplay groups: story_bottle,
	# starfish — each must adjoin a walkable cell or it can never be claimed.
	for group in ["story_bottle", "starfish"]:
		for node in scene.get_tree().get_nodes_in_group(group):
			if not node is Area2D:
				continue
			var cell: Vector2i = layer.local_to_map(layer.to_local((node as Node2D).global_position))
			if _walkable(layer, cell) or _has_walkable_neighbour(layer, cell):
				print("ok  %s reachable" % node.name)
			else:
				print("FAIL %s has no walkable cell to stand on" % node.name)
				fails += 1

	# BFS from spawn; must be able to reach the reef portal's neighbourhood.
	var reef: Node2D = null
	for child in scene.get_children():
		if String(child.name) == "PortalReefRescue":
			reef = child as Node2D
	if reef == null:
		print("FAIL PortalReefRescue missing (children: %s)" % [scene.get_children().map(func(c): return str(c.name))])
		fails += 1
	else:
		var reef_cell: Vector2i = layer.local_to_map(layer.to_local(reef.global_position))
		if _bfs_reaches(layer, spawn_cell, reef_cell):
			print("ok  BFS path spawn -> reef portal")
		else:
			print("FAIL no BFS path from spawn %s to reef cell %s" % [spawn_cell, reef_cell])
			fails += 1

	print("portal_reach_test: %s" % ("PASS" if fails == 0 else "%d failure(s)" % fails))
	_quit(0 if fails == 0 else 1)

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

func _quit(code: int) -> void:
	await process_frame
	quit(code)
