extends Area2D
@export var target_scene: String = ""
@export var warn_if_empty: bool = false
@onready var label: Label = get_node_or_null("Label")

var _warn_label: Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var tween := create_tween()
	tween.set_loops()
	if AudioManager.get_reduced_motion():
		tween.tween_property(self, "scale", Vector2(1.02, 1.02), 1.2)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.2)
	else:
		tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _make_warn() -> void:
	if _warn_label and is_instance_valid(_warn_label):
		return
	_warn_label = Label.new()
	_warn_label.text = "No trash collected yet. Try Reef Rescue first."
	_warn_label.modulate = Color(1.0, 0.7, 0.3, 0.95)
	_warn_label.position = Vector2(-110, -80)
	add_child(_warn_label)
	var tw := create_tween()
	tw.tween_property(_warn_label, "modulate:a", 0.0, 1.5)
	tw.tween_callback(_warn_label.queue_free)

func _on_body_entered(body) -> void:
	if not is_instance_valid(body) or not body.is_in_group("player"):
		return
	if target_scene == "":
		return
	if warn_if_empty and int(GameState.trash_inventory) <= 0 and target_scene.find("upcycle") != -1:
		_make_warn()
		return
	if label:
		label.modulate = Color(0.2, 1.0, 0.4, 1)
	AudioManager.play_sfx("portal")
	if AudioManager.get_reduced_motion():
		SceneTransition.change_scene(target_scene)
	else:
		var pulse := create_tween()
		pulse.tween_property(self, "scale", Vector2(1.34, 1.34), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pulse.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
		pulse.tween_callback(func(): SceneTransition.change_scene(target_scene))
