extends CharacterBody2D

const CELL_SIZE := 128.0
const MOVE_TIME := 0.2
const STEP_SPEED := 5.0 # (Note: This is unused in your script currently)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var world_map: TileMapLayer = get_parent().get_node_or_null("WorldMap")

var is_moving: bool = false
var move_tween: Tween
var path: PackedVector2Array = []
var current_dir: Vector2 = Vector2.DOWN
var exact_target_pos: Vector2 # Added to fix snapping

func _ready() -> void:
	add_to_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Get the actual 2D world position instead of the screen pixel
		var world_click_pos = get_global_mouse_position() 
		
		print("[player] click world position: ", world_click_pos)
		_set_target_from_screen(world_click_pos)
		
		get_viewport().set_input_as_handled()

func _set_target_from_screen(screen_pos: Vector2) -> void:
	if world_map == null:
		push_error("[player] world_map is null")
		return
	var start_cell := world_map.local_to_map(world_map.to_local(global_position))
	var end_cell := world_map.local_to_map(world_map.to_local(screen_pos))
	
	var route := _bfs(start_cell, end_cell)
	if route.is_empty():
		return
		
	path.clear()
	for c in route:
		path.append(world_map.to_global(world_map.map_to_local(c)))

func _physics_process(_delta: float) -> void:
	if is_moving:
		return
	if path.is_empty():
		_stop_animation()
		return
		
	exact_target_pos = path[0]
	path.remove_at(0)
	var dir := (exact_target_pos - global_position).normalized()
	
	# Optional safeguard for floating point inaccuracies
	if dir != Vector2.ZERO:
		input_to_animation(dir)
	_move_one_cell(dir)

func _move_one_cell(direction: Vector2) -> void:
	is_moving = true
	move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_LINEAR)
	move_tween.tween_property(self, "global_position", exact_target_pos, MOVE_TIME)
	move_tween.finished.connect(_on_move_finished)

func _on_move_finished() -> void:
	is_moving = false
	# Directly apply the exact target position instead of snapping to a hard grid
	global_position = exact_target_pos 

func input_to_animation(d: Vector2) -> void:
	if absf(d.x) >= absf(d.y):
		current_dir = Vector2(signf(d.x), 0)
	else:
		current_dir = Vector2(0, signf(d.y))
	_play_animation_for(current_dir)

func _play_animation_for(direction: Vector2) -> void:
	if direction.x > 0:
		animated_sprite.play("player_right")
	elif direction.x < 0:
		animated_sprite.play("player_left")
	elif direction.y > 0:
		animated_sprite.play("player_down")
	elif direction.y < 0:
		animated_sprite.play("player_up")

func _stop_animation() -> void:
	if animated_sprite.is_playing():
		animated_sprite.pause()

func _is_walkable(cell: Vector2i) -> bool:
	var td := world_map.get_cell_tile_data(cell)
	return td != null and td.has_custom_data("Walkable") and td.get_custom_data("Walkable") == true

func _bfs(start: Vector2i, goal: Vector2i) -> PackedVector2Array:
	var result := PackedVector2Array()
	if start == goal:
		print("empty??")
		return result # Return empty, no need to pathfind to current spot
		
	if not _is_walkable(start) or not _is_walkable(goal):
		print("not walkable???")
		print(_is_walkable(start))
		print(_is_walkable(goal))
		return result
		
	var queue := [start]
	var came_from := {}
	came_from[start] = Vector2i(-1, -1)
	
	var current: Vector2i # Declared OUTSIDE the while loop to fix Godot 4 scope error
	
	while queue.size() > 0:
		current = queue.pop_front()
		if current == goal:
			break
		for n: Vector2i in _neighbors(current):
			if not came_from.has(n):
				came_from[n] = current
				queue.append(n)
				
	if current == start:
		print("[bfs] start_neighbors=", _neighbors(start))
		
	if not came_from.has(goal):
		print("[bfs] goal not reachable.")
		return result

	var cur := goal
	var seq := []
	while cur != Vector2i(-1, -1):
		seq.append(cur)
		cur = came_from[cur]
		
	seq.reverse()
	
	# Skip the first node (the starting position) so the player doesn't try to move 0 pixels
	for i in range(1, seq.size()):
		result.append(seq[i])
		
	return result

func _neighbors(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d: Vector2i in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var n := c + d
		if _is_walkable(n):
			out.append(n)
	return out
