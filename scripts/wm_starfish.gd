extends Area2D
class_name WorldStarfish

## A decorative "tidepool" starfish collectible. Five of them hide around
## the island; walking over one collects it forever (ids are saved), pops a
## floating "+1 starfish" callout and feeds the STARLIGHT achievement.
## Unlike the bottles these carry no story — they are the island's open
## secret for players who walk the far corners.

const FLOATING_TEXT_SCENE := preload("res://scenes/ui/floating_text.tscn")
const FxSparkle := preload("res://scripts/fx_sparkle.gd")

@export var starfish_id: String = "starfish_1"


func _ready() -> void:
	if GameState.is_starfish_found(starfish_id):
		queue_free()
		return
	add_to_group("starfish")
	body_entered.connect(_on_body_entered)
	# Gentle glint so the starfish reads as collectible, not decor.
	if not GameSettings.reduce_motion and has_node("Sprite2D"):
		var tw := create_tween().set_loops()
		tw.tween_property($Sprite2D, "modulate", Color(1.3, 1.1, 0.75, 1.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property($Sprite2D, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node) -> void:
	if not (body is Node2D and body.is_in_group("player")):
		return
	if GameState.is_starfish_found(starfish_id):
		queue_free()
		return
	var total: int = GameState.mark_starfish_found(starfish_id)
	AudioManager.play_sfx("pickup", 1.5)
	set_deferred("monitoring", false)
	if has_node("Sprite2D"):
		var ap := create_tween()
		ap.tween_property($Sprite2D, "scale", Vector2(1.35, 1.35), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ap.tween_property($Sprite2D, "scale", Vector2.ZERO, 0.26).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Floating callout at the pickup spot: "starfish n/5".
	var lbl: FloatingText = FLOATING_TEXT_SCENE.instantiate()
	lbl.position = global_position + Vector2(-40.0, -30.0)
	lbl.rise_distance = 30.0
	lbl.hold_time = 1.1
	lbl.z_index = 40
	get_tree().current_scene.add_child(lbl)
	lbl.present("Starfish %d/5" % total, Color(1.0, 0.75, 0.4, 1.0), 17)
	FxSparkle.burst(get_tree().current_scene, global_position, Color(1.0, 0.75, 0.4, 1.0), {"amount": 10, "lifetime": 0.5})
	# Let the pop play before the node leaves the tree.
	await get_tree().create_timer(0.45).timeout
	queue_free()
