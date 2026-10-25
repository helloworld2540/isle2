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
	var tween := create_tween()
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	tween.tween_property(fade, "color:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(path)
	await get_tree().create_timer(1).timeout
	var tween2 := create_tween()
	tween2.tween_property(fade, "color:a", 0.0, 0.5)
	await tween2.finished
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
