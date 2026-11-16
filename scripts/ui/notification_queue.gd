extends CanvasLayer
class_name HUDNotificationQueue
# Lightweight HUD notification queue utility. Add as child or autoload; shows
# short-lived labels one at a time in a bottom-centre lane — 24 px off the
# screen edge, clear of the corner HUD panels, and lifted above any
# bottom-centre card (the tutorial step hint).

var _queue: Array[Dictionary] = []
var _active: Label = null

func push(text: String, color: Color = Color(1.0, 1.0, 1.0, 1.0), duration: float = 1.6) -> void:
	_queue.append({"text": text, "color": color, "duration": duration})
	_try_show_next()

func _try_show_next() -> void:
	if _active:
		return
	if _queue.is_empty():
		return
	var e: Dictionary = _queue.pop_front()
	_spawn(e)

const LABEL_SCENE := preload("res://scenes/ui/label.tscn")

func _spawn(e: Dictionary) -> void:
	var lbl := LABEL_SCENE.instantiate() as Label
	lbl.text = str(e.get("text", ""))
	lbl.modulate = e.get("color", Color(1.0, 1.0, 1.0, 1.0)) as Color
	lbl.modulate.a = 0.0
	lbl.add_theme_font_size_override("font_size", 18)
	# Dark outline keeps the toast legible over bright water and busy UI.
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.09, 0.9))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.z_index = 120
	# Full-width bottom band, 24 px off the edge; lift clear above any bottom card.
	var card_h := _bottom_card_height()
	var lift := (card_h + 12.0) if card_h > 0.0 else 0.0
	lbl.anchor_left = 0.0
	lbl.anchor_right = 1.0
	lbl.anchor_top = 1.0
	lbl.anchor_bottom = 1.0
	lbl.offset_left = 0.0
	lbl.offset_right = 0.0
	lbl.offset_top = -64.0 - lift
	lbl.offset_bottom = -24.0 - lift
	add_child(lbl)
	_active = lbl
	var dur := float(e.get("duration", 1.6))
	if GameSettings.reduce_motion:
		# No fade in/out under reduced motion: hold the toast solid, then drop it.
		lbl.modulate.a = 1.0
		var hold := get_tree().create_timer(max(0.2, dur))
		hold.timeout.connect(func() -> void:
			_active = null
			lbl.queue_free()
			_try_show_next()
		)
		return
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(max(0.2, dur))
	tw.tween_property(lbl, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_active = null
		lbl.queue_free()
		_try_show_next()
	)


## Height of the tallest visible bottom-centre card (the tutorial step hint),
## or 0 when the lane is free, so a toast stacks cleanly above it.
func _bottom_card_height() -> float:
	var tree := get_tree()
	if tree == null:
		return 0.0
	var height := 0.0
	for node in tree.get_nodes_in_group("hud_bottom_card"):
		if node is Control and (node as Control).visible:
			var c := node as Control
			height = maxf(height, maxf(c.size.y, c.get_combined_minimum_size().y))
	return height
