extends CanvasLayer

var fade: ColorRect
var busy: bool = false

func is_busy() -> bool:
	return busy

func instant_clear() -> void:
	# Drop any in-flight fade and make the overlay transparent immediately.
	busy = false
	if is_instance_valid(fade):
		fade.color.a = 0.0
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	layer = 100
	fade = load("res://scenes/ui/color_rect.tscn").instantiate() as ColorRect
	fade.color = Color(0, 0, 0, 0)
	fade.anchor_right = 1.0
	fade.anchor_bottom = 1.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

func change_scene(path: String) -> void:
	if busy:
		return
	busy = true
	if get_tree().paused:
		get_tree().paused = false
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
	await get_tree().process_frame
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	# Fade out instantly: pausing the tree stops tweens, so the fade-out must not depend on time.
	if is_instance_valid(fade):
		fade.color.a = 0.0
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
