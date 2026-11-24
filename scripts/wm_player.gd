extends CharacterBody2D

## The islander on the world map: tap-to-move with BFS pathfinding on
## walkable tiles, walk/idle animations and tide-aware movement.

@export var MOVE_TIME := 0.3

## Design-time fallback: how far (in world tiles) the keeper searches out from
## an unwalkable or off-map tap target before snapping to the nearest walkable
## cell. One tuned constant instead of a per-call magic number.
const FALLBACK_RADIUS := 8

## Emitted when a tap-to-move walk finishes — one "movement cycle" (a single
## BFS run). Portals listen for it so a pad the keeper spawned beside can stay
## inert through that first walk instead of bouncing them back into the scene
## they just left.
signal move_cycle_finished

@onready var animated_sprite: AnimatedSprite2D = $"AnimatedSprite2D"
@onready var world_map: TileMapLayer = $"../../Geography/WorldMap"

var is_moving := false
var path: PackedVector2Array = []
var current_dir := Vector2.DOWN
var global_target_pos: Vector2
var _path_highlight: Node2D

func _ready() -> void:
	add_to_group("player")
	_restore_position()
	global_target_pos = global_position
	_path_highlight = load("res://scenes/ui/node2_d.tscn").instantiate() as Node2D
	_path_highlight.top_level = true
	_path_highlight.z_index = -1
	add_child(_path_highlight)
	_refresh_move_time()


# The world map is re-entered from portals and the menu, so pick up the spot
# the player left from instead of the scene's authored position.
func _restore_position() -> void:
	var saved: Variant = SaveManager.load_player_position()
	if saved is Vector2:
		global_position = saved

func _refresh_move_time() -> void:
	var mult: float = max(0.01, GameState.get_move_speed_multiplier())
	MOVE_TIME = max(0.05, (0.3 / mult) * 0.5 + 0.15)


# Called by the world menu after an upgrade purchase.
func refresh_upgrades() -> void:
	_refresh_move_time()

func _clear_highlight() -> void:
	if not _path_highlight:
		return
	for c in _path_highlight.get_children():
		c.queue_free()

func _refresh_highlight() -> void:
	_clear_highlight()
	if not world_map or not _path_highlight:
		return
	for world_pos in path:
		var tile := load("res://scenes/ui/color_rect.tscn").instantiate() as ColorRect
		tile.color = Color(1.0, 1.0, 1.0, 0.114)
		var ts := Vector2(128.0, 128.0)
		if world_map.tile_set:
			ts = Vector2(world_map.tile_set.tile_size)
		tile.size = ts
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
	var start_cell := Vector2i.ZERO
	var end_cell := Vector2i.ZERO
	if world_map:
		start_cell = world_map.local_to_map(world_map.to_local(starting_pos))
		end_cell = world_map.local_to_map(world_map.to_local(world_pos))
	if world_map and not _is_walkable(end_cell):
		end_cell = _nearest_walkable_cell(end_cell, FALLBACK_RADIUS)
	var route := _bfs(start_cell, end_cell)
	for cell in route:
		if world_map:
			path.append(world_map.to_global(world_map.map_to_local(cell)))
	_refresh_highlight()
	if not path.is_empty():
		TutorialDirector.notify("move")

func _physics_process(_delta: float) -> void:
	if is_moving or path.is_empty():
		return
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
	# Only the end of the whole run counts as a cycle; _on_move_finished also
	# fires between tiles.
	if path.is_empty():
		move_cycle_finished.emit()

func _update_animation(dir: Vector2) -> void:
	if not animated_sprite:
		return
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
	if not world_map:
		return false
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
	return route

func _nearest_walkable_cell(target: Vector2i, max_radius: int = FALLBACK_RADIUS) -> Vector2i:
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
