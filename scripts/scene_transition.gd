extends CanvasLayer

var fade: ColorRect
var busy: bool = false

func _ready() -> void:
	layer = 100
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.anchor_right = 1.0
	fade.anchor_bottom = 1.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

func change_scene(path: String) -> void:
	if busy:
		return
	busy = true
	var fade_in_time := 0.5
	var hold_time := 1.0
	var fade_out_time := 0.5
	if AudioManager.get_reduced_motion():
		fade_in_time = 0.12
		hold_time = 0.05
		fade_out_time = 0.12
	var tween := create_tween()
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	tween.tween_property(fade, "color:a", 1.0, fade_in_time)
	await tween.finished
	get_tree().change_scene_to_file(path)
	await get_tree().create_timer(hold_time).timeout
	var tween2 := create_tween()
	tween2.tween_property(fade, "color:a", 0.0, fade_out_time)
	await tween2.finished
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
