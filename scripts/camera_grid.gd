extends Camera2D

@export var grid_size: Vector2 = Vector2(128, 128)
@export var snap_speed: float = 4
	 

func _process(delta: float) -> void:
	if get_parent() == null:
		return
	# Target is the camera position snapped to the tile grid, like classic
	# Pokemon maps; move toward it smoothly for a stepped-but-fluid pan.
	var target: Vector2 = get_parent().global_position.snapped(grid_size)
	global_position = global_position.lerp(target, clampf(snap_speed * delta, 0.0, 1.0))
