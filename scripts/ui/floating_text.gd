extends Label

## One-shot floating text used for score popups, sale receipts and banners.
## Configure the feel with the exported values, then call present() once.

class_name FloatingText

@export var rise_distance := 42.0
@export var fade_in_time := 0.16
@export var hold_time := 0.9
@export var fade_out_time := 0.3
## >1.0 plays a short pop-in punch before settling.
@export var punch_scale := 1.0

var _rest_position := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func present(text_value: String, color: Color = Color.WHITE, font_size: int = 18) -> void:
	text = text_value
	modulate = color
	modulate.a = 0.0
	add_theme_font_size_override("font_size", font_size)
	_rest_position = position
	
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, fade_in_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# rise_distance 0 means the caller owns positioning (e.g. receipt stacks that
	# reflow when an older entry leaves); skip the rise tween so it cannot fight.
	if rise_distance != 0.0:
		tw.parallel().tween_property(self, "position", _rest_position + Vector2(0, -rise_distance), fade_in_time + hold_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if punch_scale > 1.0:
		scale = Vector2(punch_scale, punch_scale)
		tw.parallel().tween_property(self, "scale", Vector2.ONE, fade_in_time * 1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Writers of hold_time expect a full hold before the fade-out; without the
	# interval the card started fading the moment the fade-in finished.
	tw.tween_interval(hold_time)
	tw.tween_property(self, "modulate:a", 0.0, fade_out_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
