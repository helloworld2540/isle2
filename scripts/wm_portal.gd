extends Area2D
@export var target_scene: String = ""
@export var warn_if_empty: bool = false
@onready var label: Label = get_node_or_null("Label")

var _warn_label: Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var idle_tween := create_tween().set_loops()
	if AudioManager.get_reduced_motion():
		idle_tween.tween_property(self, "scale", Vector2(1.02, 1.02), 1.2)
		idle_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.2)
	else:
		idle_tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		idle_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Small label bob for affordance.
	if label and not AudioManager.get_reduced_motion():
		var label_tween := create_tween().set_loops()
		label_tween.tween_property(label, "position:y", label.position.y - 6.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		label_tween.tween_property(label, "position:y", label.position.y, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
	# Avoid re-triggering while transition is running.
	if SceneTransition.has_method("is_busy") and SceneTransition.is_busy():
		return
	if label:
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
