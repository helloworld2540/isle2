extends CanvasLayer

## Global scene fader (autoload). Keeps running while the tree is paused so a
## minigame intro can pause on load and the scene still fades in cleanly.

const FADE_OUT_TIME := 0.35
const FADE_IN_TIME := 0.4

var fade: ColorRect
var busy: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	fade = load("res://scenes/ui/color_rect.tscn").instantiate() as ColorRect
	fade.color = Color(0, 0, 0, 0)
	fade.anchor_right = 1.0
	fade.anchor_bottom = 1.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)


func is_busy() -> bool:
	return busy


func instant_clear() -> void:
	# Drop any in-flight fade and make the overlay transparent immediately.
	busy = false
	if fade:
		fade.color.a = 0.0
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func change_scene(path: String) -> void:
	if busy:
		return
	
	busy = true
	if get_tree().paused:
		get_tree().paused = false
	
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var out := create_tween()
	out.tween_property(fade, "color:a", 1.0, FADE_OUT_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await out.finished
	
	# Never leave a debounced GameState write behind when the scene unloads.
	if GameState.has_method("flush_save"):
		GameState.flush_save()
	
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var back := create_tween()
	back.tween_property(fade, "color:a", 0.0, FADE_IN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await back.finished
	
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
