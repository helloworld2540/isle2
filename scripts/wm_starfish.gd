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
	# Gentle idle so the starfish reads as alive in the pool, not a decal: a
	# soft glint plus a slow rock that carries the light across its arms.
	if not GameSettings.reduce_motion and has_node("Sprite2D"):
		var sprite := $Sprite2D
		# Rest each starfish at its own angle so the five don't look stamped
		# from the same mould. Seeded from the id and position so the rock is
		# varied but the pool looks the same every visit.
		var rest_angle := _idle_rng().randf_range(-0.35, 0.35)
		sprite.rotation = rest_angle
		var glint := create_tween().set_loops()
		glint.tween_property(sprite, "modulate", Color(0.885, 0.854, 0.854, 1.0), 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		glint.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var sway := create_tween().set_loops()
		sway.tween_property(sprite, "rotation", rest_angle + 0.15, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sway.tween_property(sprite, "rotation", rest_angle - 0.15, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## A per-starfish RNG seeded from its id and world position, so the idle rock is
## varied but deterministic — the pool looks the same every time the keeper
## walks past.
func _idle_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(starfish_id) ^ (int(global_position.x) * 73856093) ^ (int(global_position.y) * 19349663)
	return rng


func _on_body_entered(body: Node) -> void:
	if not (body is Node2D and body.is_in_group("player")):
		return
	if GameState.is_starfish_found(starfish_id):
		queue_free()
		return
	var total: int = GameState.mark_starfish_found(starfish_id)
	AudioManager.play_sfx("pickup", 1.5)
	if total == 1:
		TutorialDirector.nudge("starfish")
	elif total == 4:
		TutorialDirector.nudge("starfish_final")
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
	lbl.present("Starfish %d/5" % total, Color(1.0, 0.75, 0.4, 1.0), 20)
	FxSparkle.burst(get_tree().current_scene, global_position, Color(1.0, 0.75, 0.4, 1.0), {"amount": 10, "lifetime": 0.5})
	# Let the pop play before the node leaves the tree.
	await get_tree().create_timer(0.45).timeout
	queue_free()
