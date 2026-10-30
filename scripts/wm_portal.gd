extends Area2D
@export var target_scene: String = ""
@onready var label: Label = get_node_or_null("Label")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Continuous pulse for discoverable portals.
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body) -> void:
	if target_scene != "" and body.is_in_group("player"):
		if label: label.modulate = Color(0.2, 1.0, 0.4, 1)
		SceneTransition.change_scene(target_scene)
