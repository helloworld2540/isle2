extends Camera2D

## World-map camera: top-level, deadzoned follow with lerp so the map
## scrolls smoothly behind the islander instead of snapping per cell.

@export var deadzone_width: float = 128.0 * 8.0
@export var deadzone_height: float = 128.0 * 5.0
@export var lerp_speed: float = 6.0

func _ready() -> void:
	set_as_top_level(true)
	if get_parent():
		global_position = get_parent().global_position

func _process(delta: float) -> void:
	var parent := get_parent()
	if parent == null or not parent:
		return
	var target: Vector2 = parent.global_position
	var diff: Vector2 = target - global_position
	var extents_x := deadzone_width * 0.5
	var extents_y := deadzone_height * 0.5
	if absf(diff.x) <= extents_x and absf(diff.y) <= extents_y:
		return
	var desired := global_position
	if absf(diff.x) > extents_x:
		desired.x = target.x - signf(diff.x) * extents_x
	if absf(diff.y) > extents_y:
		desired.y = target.y - signf(diff.y) * extents_y
	global_position = global_position.lerp(desired, clampf(lerp_speed * delta, 0.0, 1.0))
