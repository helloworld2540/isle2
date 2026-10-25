extends Camera2D

@export var follow_dead_zone: float = 100.0
@export var lerp_speed: float = 6.0

func _process(delta: float) -> void:
	if get_parent() == null:
		return
	var target := get_parent().global_position
	var offset := target - global_position
	if offset.length() > follow_dead_zone:
		global_position = global_position.lerp(target, clampf(lerp_speed * delta, 0.0, 1.0))
		