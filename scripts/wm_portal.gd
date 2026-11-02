extends Area2D
@export var target_scene: String = ""
@export var warn_if_empty: bool = false
@export var warn_target_contains: String = "upcycle"
@onready var label: Label = get_node_or_null("Label")

@onready var pad: ColorRect = get_node_or_null("Pad")
var _warn_label: Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_pad()
	var idle_tween := create_tween().set_loops()
	if AudioManager.get_reduced_motion():
		idle_tween.tween_property(self, "scale", Vector2(1.02, 1.02), 1.2)
		idle_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.2)
	else:
		idle_tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		idle_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if is_instance_valid(label) and not AudioManager.get_reduced_motion():
		var label_tween := create_tween().set_loops()
		label_tween.tween_property(label, "position:y", label.position.y - 6.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		label_tween.tween_property(label, "position:y", label.position.y, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _build_pad() -> void:
	if not is_instance_valid(pad):
		pad = load("res://scenes/ui/color_rect.tscn").instantiate() as ColorRect
		pad.name = "Pad"
		pad.color = Color(0.4, 0.75, 1.0, 0.35)
		pad.size = Vector2(96, 96)
		pad.offset_left = -48
		pad.offset_top = -48
		pad.offset_right = 48
		pad.offset_bottom = 48
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pad)
		move_child(pad, 0)
	if not AudioManager.get_reduced_motion():
		var glow := create_tween().set_loops()
		glow.tween_property(pad, "modulate:a", 0.6, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		glow.tween_property(pad, "modulate:a", 0.35, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_exited(body) -> void:
	if not is_instance_valid(body) or not body.is_in_group("player"):
		return
	if is_instance_valid(_warn_label):
		_warn_label.queue_free()
		_warn_label = null
	var pad := get_node_or_null("Pad")
	if is_instance_valid(pad):
		pad.color = Color(0.4, 0.75, 1.0, 0.35)
		var exit_tw := create_tween()
		exit_tw.tween_property(pad, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var ping := get_node_or_null("PingMarker")
	if is_instance_valid(ping):
		ping.queue_free()

func _make_warn() -> void:
	if is_instance_valid(_warn_label):
		return
	_warn_label = load("res://scenes/ui/label.tscn").instantiate() as Label
	_warn_label.text = "No trash collected yet. Try Reef Rescue first."
	_warn_label.modulate = Color(1.0, 0.7, 0.3, 0.95)
	_warn_label.position = Vector2(-110, -80)
	_warn_label.scale = Vector2(1.5, 1.5)
	add_child(_warn_label)

func _on_body_entered(body) -> void:
	if not is_instance_valid(body) or not body.is_in_group("player"):
		return
	if target_scene == "":
		push_warning("wm_portal: empty target_scene")
		return
	var pad := get_node_or_null("Pad")
	if is_instance_valid(pad):
		pad.color = Color(0.6, 1.0, 0.6, 0.6)
		var hover_tw := create_tween()
		hover_tw.tween_property(pad, "scale", Vector2(1.12, 1.12), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var ping := get_node_or_null("PingMarker")
	if not is_instance_valid(ping):
		ping = load("res://scenes/ui/ping_marker.tscn").instantiate() as Label
		ping.name = "PingMarker"
		ping.text = "▶" if not is_instance_valid(ping.get("text")) else ping.text
		ping.modulate = Color(0.4, 1.0, 0.5, 0.9)
		ping.position = Vector2(-8, -72)
	if warn_if_empty and int(GameState.trash_inventory) <= 0 and target_scene.find(warn_target_contains) != -1:
		_make_warn()
		return
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and SaveManager:
		var save_data := SaveManager.load_game()
		save_data["player_position"] = [player.global_position.x, player.global_position.y]
		SaveManager.save_game(save_data)
	if SceneTransition.has_method("is_busy") and SceneTransition.is_busy():
		return
	if is_instance_valid(label):
		label.modulate = Color(0.2, 1.0, 0.4, 1)
	AudioManager.play_sfx("portal")
	if AudioManager.get_reduced_motion():
		SceneTransition.change_scene(target_scene)
	else:
		var pulse := create_tween()
		pulse.tween_property(self, "scale", Vector2(1.8, 1.8), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pulse.tween_property(self, "scale", Vector2(0.55, 0.55), 0.07)
		pulse.tween_property(self, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pulse.tween_callback(func(): SceneTransition.change_scene(target_scene))
