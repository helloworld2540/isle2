extends Sprite2D

## Red-tinted wake streak that blooms at the bottom edge to telegraph an
## incoming fish a beat before it rises into view. Swells slightly as it
## fades, then frees itself. Never follows the fish — it marks the lane
## the fish will rise through.

const LIFE := 1.15
const TINT := Color(1.0, 0.35, 0.28, 0.62)

func _ready() -> void:
	texture = preload("res://sprites/rr/wake.png")
	centered = true
	modulate = TINT
	if GameSettings.reduce_motion:
		queue_free()
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, LIFE).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(self, "scale", Vector2(1.3, 1.3), LIFE).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(queue_free)
