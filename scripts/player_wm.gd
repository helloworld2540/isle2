extends CharacterBody2D

@export var MOVE_TIME := 0.3

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var world_map: TileMapLayer = $"../WorldMap"

var is_moving := false
var path: PackedVector2Array = []
var current_dir := Vector2.DOWN
var global_target_pos: Vector2

func _ready() -> void:
	add_to_group("player")
	global_target_pos = global_position

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
	
	var route := _bfs(start_cell, end_cell)

	for cell in route:
		path.append(world_map.to_global(world_map.map_to_local(cell)))

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
		return []

	var route: Array[Vector2i] = []
	var step := goal
	
	while step != start:
		route.append(step)
		step = came_from[step]
		
	route.reverse()
	print("[bfs] start, end:", start, goal)
	print("[bfs]", route)
	return route

func _get_walkable_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var next_cell: Vector2i = cell + dir
		if _is_walkable(next_cell):
			neighbors.append(next_cell)
	return neighbors
