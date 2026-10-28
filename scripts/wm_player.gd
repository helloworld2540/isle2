extends CharacterBody2D

@export var MOVE_TIME := 0.3

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var world_map: TileMapLayer = $"../WorldMap"

var is_moving := false
var path: PackedVector2Array = []
var current_dir := Vector2.DOWN
var global_target_pos: Vector2
var _path_highlight: Node2D

func _ready() -> void:
	add_to_group("player")
	global_target_pos = global_position
	_path_highlight = Node2D.new()
	_path_highlight.top_level = true
	_path_highlight.z_index = -1
	add_child(_path_highlight)

func _clear_highlight() -> void:
	for c in _path_highlight.get_children():
		c.queue_free()

func _refresh_highlight() -> void:
	_clear_highlight()
	for world_pos in path:
		var tile := ColorRect.new()
		tile.color = Color(1.0, 1.0, 1.0, 0.114)
		tile.size = Vector2(world_map.tile_set.tile_size) if world_map.tile_set else Vector2(128, 128)
		tile.global_position = world_pos - (tile.size * 0.5)
		_path_highlight.add_child(tile)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var global_click_pos := get_global_mouse_position() 
		_calculate_path_to(global_click_pos)
		get_viewport().set_input_as_handled()

func _calculate_path_to(world_pos: Vector2) -> void:	
	path.clear()
	var starting_pos := global_target_pos if is_moving else global_position
	var start_cell := world_map.local_to_map(world_map.to_local(starting_pos))
	var end_cell := world_map.local_to_map(world_map.to_local(world_pos))

	# If the clicked tile is not walkable, fall back to the nearest walkable one.
	if not _is_walkable(end_cell):
		end_cell = _nearest_walkable_cell(end_cell, 8)

	var route := _bfs(start_cell, end_cell)

	for cell in route:
		path.append(world_map.to_global(world_map.map_to_local(cell)))
	
	_refresh_highlight()

func _physics_process(_delta: float) -> void:
	# Update pathfinding tile
	if is_moving: return
	if path.is_empty(): return
		
	global_target_pos = path[0]
	path.remove_at(0)
	
	var dir := global_position.direction_to(global_target_pos)
	_update_animation(dir)
	_move_to_target()

func _move_to_target() -> void:
	is_moving = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "global_position", global_target_pos, MOVE_TIME)
	tween.finished.connect(_on_move_finished)

func _on_move_finished() -> void:
	is_moving = false
	_refresh_highlight()

func _update_animation(dir: Vector2) -> void:
	if absf(dir.x) >= absf(dir.y):
		current_dir = Vector2(signf(dir.x), 0)
	else:
		current_dir = Vector2(0, signf(dir.y))
		
	if current_dir.x > 0:
		animated_sprite.play("player_right")
	elif current_dir.x < 0:
		animated_sprite.play("player_left")
	elif current_dir.y > 0:
		animated_sprite.play("player_down")
	elif current_dir.y < 0:
		animated_sprite.play("player_up")

func _is_walkable(cell: Vector2i) -> bool:
	var tile_data := world_map.get_cell_tile_data(cell)
	return tile_data != null and tile_data.get_custom_data("Walkable") == true

func _bfs(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if start == goal or not _is_walkable(start) or not _is_walkable(goal):
		return []
		
	var queue: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: start}
	var current: Vector2i
	
	while not queue.is_empty():
		current = queue.pop_front()
		if current == goal:
			break
			
		for neighbor in _get_walkable_neighbors(current):
			if not came_from.has(neighbor):
				came_from[neighbor] = current
				queue.append(neighbor)
				
	if not came_from.has(goal):
		var best_cell: Vector2i = start
		var best_dist: float = INF
		for visited in came_from.keys():
			var d: float = visited.distance_to(goal)
			if d < best_dist:
				best_dist = d
				best_cell = visited
		if best_cell == start:
			return []
		goal = best_cell

	var route: Array[Vector2i] = []
	var step := goal
	
	while step != start:
		route.append(step)
		step = came_from[step]
		
	route.reverse()
	print("[bfs] start, end:", start, goal)
	print("[bfs] route:", route)
	return route

func _nearest_walkable_cell(target: Vector2i, max_radius: int) -> Vector2i:
	for r in range(1, max_radius + 1):
		for sx in range(-r, r + 1):
			for sy in range(-r, r + 1):
				if abs(sx) != r and abs(sy) != r:
					continue
				var c := target + Vector2i(sx, sy)
				if _is_walkable(c):
					return c
	return target

func _get_walkable_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var next_cell: Vector2i = cell + dir
		if _is_walkable(next_cell):
			neighbors.append(next_cell)
	return neighbors
