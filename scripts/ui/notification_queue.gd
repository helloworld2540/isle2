extends CanvasLayer
class_name HUDNotificationQueue
# Lightweight HUD notification queue utility. Add as child or autoload; shows
# short-lived labels stacked at the top edge without overlapping.

var _queue: Array[Dictionary] = []
var _active: Label = null

func push(text: String, color: Color = Color(1.0, 1.0, 1.0, 1.0), duration: float = 1.6) -> void:
	_queue.append({"text": text, "color": color, "duration": duration})
	_try_show_next()

func _try_show_next() -> void:
	if is_instance_valid(_active):
		return
	if _queue.is_empty():
		return
	var e: Dictionary = _queue.pop_front()
	_spawn(e)

func _spawn(e: Dictionary) -> void:
	var lbl := load("res://scenes/ui/label.tscn").instantiate() as Label
	lbl.text = str(e.get("text", ""))
	lbl.modulate = e.get("color", Color(1.0, 1.0, 1.0, 1.0)) as Color
	lbl.modulate.a = 0.0
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.custom_minimum_size = Vector2(320, 0)
	lbl.z_index = 120
	add_child(lbl)
	lbl.position = Vector2(24, 24)
	_active = lbl
	var dur := float(e.get("duration", 1.6))
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "position", lbl.position + Vector2(0, 4), 0.16)
	tw.tween_interval(max(0.2, dur))
	tw.tween_property(lbl, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_active = null
		lbl.queue_free()
		_try_show_next()
	)
