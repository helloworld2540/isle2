extends Label

## One-shot floating text used for score popups, sale receipts and banners.
## Configure the feel with the exported values, then call present() once.

class_name FloatingText

const WORLD_FONT := preload("res://resources/world_bold.tres")

@export var rise_distance := 42.0
@export var fade_in_time := 0.16
@export var hold_time := 0.9
@export var fade_out_time := 0.3
## >1.0 plays a short pop-in punch before settling.
@export var punch_scale := 1.0

var _rest_position := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A world-map callout sits under the 0.45 camera zoom, so it renders at less
## than half size. Embolden it and give it an outline (pair with a large
## font_size) so it stays legible over the busy tile map. Screen-space callers
## leave this alone — their text is already full size.
func make_world_legible() -> void:
	add_theme_font_override("font", WORLD_FONT)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	add_theme_constant_override("outline_size", 10)


## Font size is interpreted as on-screen pixels; world-space callers must pass a
## larger value to compensate for the camera zoom (see make_world_legible).
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
	if rise_distance != 0.0 and not GameSettings.reduce_motion:
		tw.parallel().tween_property(self, "position", _rest_position + Vector2(0, -rise_distance), fade_in_time + hold_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# The pop-in punch is pure motion; skip it under reduced motion and let
	# the card hold its resting size. The settle happens invisibly at spawn.
	if punch_scale > 1.0 and not GameSettings.reduce_motion:
		scale = Vector2(punch_scale, punch_scale)
		tw.parallel().tween_property(self, "scale", Vector2.ONE, fade_in_time * 1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Writers of hold_time expect a full hold before the fade-out; without the
	# interval the card started fading the moment the fade-in finished.
	tw.tween_interval(hold_time)
	tw.tween_property(self, "modulate:a", 0.0, fade_out_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
