extends Camera2D

@export var deadzone_width: float = 128.0*8
@export var deadzone_height: float = 128.0*5
@export var lerp_speed: float = 6.0

func _ready() -> void:
	# CRITICAL: Detaches the camera's transform from the parent player.
	# This allows the camera to lag behind smoothly without stuttering.
	set_as_top_level(true)
	
	# Snap the camera to the player on start so it doesn't fly in from nowhere
	if get_parent() != null:
		global_position = get_parent().global_position

func _process(delta: float) -> void:
	var parent = get_parent()
	if parent == null:
		return
		
	var target: Vector2 = parent.global_position
	var diff: Vector2 = target - global_position
	
	# Using the extents (half the width/height) for calculations
	var extents_x = deadzone_width / 2.0
	var extents_y = deadzone_height / 2.0
	
	# Per-axis dead zone: only move when player leaves the box
	if absf(diff.x) <= extents_x and absf(diff.y) <= extents_y:
		return
		
	var desired := global_position
	
	if absf(diff.x) > extents_x:
		desired.x = target.x - signf(diff.x) * extents_x
	if absf(diff.y) > extents_y:
		desired.y = target.y - signf(diff.y) * extents_y
		
	# Move towards the desired position smoothly
	global_position = global_position.lerp(desired, clampf(lerp_speed * delta, 0.0, 1.0))
