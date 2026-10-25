extends CharacterBody2D

const CELL_SIZE := 128.0
const MOVE_TIME := 0.2
const STEP_SPEED := 5.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var world_map: TileMapLayer = get_tree().get_first_node_in_group("WorldMap")

var is_moving: bool = false
var move_tween: Tween
var path: PackedVector2Array = []
var current_dir: Vector2 = Vector2.DOWN

func _ready() -> void:
	add_to_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_target_from_screen(event.global_position)
		# consume so UI doesn't also respond if needed
	get_viewport().set_input_as_handled()

func _set_target_from_screen(screen_pos: Vector2) -> void:
	var start_cell := world_map.local_to_map(global_position)
	var end_cell := world_map.local_to_map(world_map.to_local(screen_pos)) if world_map.is_inside_tree() else world_map.local_to_map(screen_pos)
	# Convert global screen click to tilemap local first
	end_cell = world_map.local_to_map(world_map.get_global_transform().affine_inverse() * screen_pos)
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
	var target := path[0]
	var dir := (target - global_position).normalized() * CELL_SIZE
	dir = dir.snapped(Vector2(CELL_SIZE, CELL_SIZE))
	if dir == Vector2.ZERO:
		path.remove_at(0)
		return
	input_to_animation(dir.normalized())
	var actual_dir := dir.normalized()
	_move_one_cell(actual_dir)

func _move_one_cell(direction: Vector2) -> void:
	is_moving = true
	var target := global_position + direction * CELL_SIZE
	move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_LINEAR)
	move_tween.tween_property(self, "global_position", target, MOVE_TIME)
	move_tween.finished.connect(_on_move_finished)

func _on_move_finished() -> void:
	is_moving = false
	global_position = global_position.snapped(Vector2(CELL_SIZE, CELL_SIZE))
	if not path.is_empty():
		path.remove_at(0)

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
	return td != null and td.has_custom_data("walkable") and td.get_custom_data("walkable") == true

func _bfs(start: Vector2i, goal: Vector2i) -> PackedVector2Array:
	var result := PackedVector2Array()
	if start == goal:
		result.append(start)
		return result
	if not _is_walkable(start) or not _is_walkable(goal):
		return result
	var queue := [start]
	var came_from := {}
	came_from[start] = Vector2i(-1, -1)
	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		if current == goal:
			break
		for nb in _neighbors(current):
			if not came_from.has(nb):
				came_from[nb] = current
				queue.append(nb)
	if not came_from.has(goal):
		return result
	var cur := goal
	var seq := []
	while cur != Vector2i(-1, -1):
		seq.append(cur)
		cur = came_from[cur]
	seq.reverse()
	for v in seq:
		result.append(v)
	return result

func _neighbors(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var n := c + d
		if _is_walkable(n):
			out.append(n)
	return out
