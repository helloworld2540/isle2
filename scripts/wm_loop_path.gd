extends Line2D

## Dashed guide line that links the numbered world-map portals into one loop.
## Points are taken from the portals themselves so the line follows the scene.

@export var portal_paths: Array[NodePath] = []
@export var pulse_time := 1.8


func _ready() -> void:
	points = _collect_points()
	if points.size() < 2:
		return
	
	var pulse := create_tween().set_loops()
	pulse.tween_property(self, "modulate:a", 0.45, pulse_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(self, "modulate:a", 0.9, pulse_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _collect_points() -> PackedVector2Array:
	var collected: PackedVector2Array = []
	for path in portal_paths:
		var portal := get_node_or_null(path)
		if portal is Node2D:
			collected.append((portal as Node2D).global_position)
	return collected
