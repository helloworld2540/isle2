extends Area2D

## A "message in a bottle" collectible. Walking over one reads it, marks it
## read in GameState and opens the story on the dialogue card. Read bottles
## never respawn (their ids are saved under bottles_read).

const DIALOGUE_SCENE := preload("res://scenes/ui/npc_dialogue.tscn")

@export var bottle_id: String = "bottle_1"
@export_multiline var story_lines: Array[String] = ["Hello, sailor."]

func _ready() -> void:
	if GameState.is_story_read(bottle_id):
		queue_free()
		return
	add_to_group("story_bottle")
	body_entered.connect(_on_body_entered)
	
	# Gentle bob so the bottle reads as "something to pick up".
	if not GameSettings.reduce_motion and has_node("Sprite2D"):
		var tw := create_tween().set_loops()
		$Sprite2D.position = Vector2.ZERO
		tw.tween_property($Sprite2D, "position:y", -6.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property($Sprite2D, "position:y", 0.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node) -> void:
	if not (body is Node2D and body.is_in_group("player")):
		return
	_read()


func _read() -> void:
	if GameState.is_story_read(bottle_id):
		queue_free()
		return
	GameState.mark_story_read(bottle_id)
	AudioManager.play_sfx("quest_complete", 0.95)
	set_deferred("monitoring", false)
	
	var dialogue = DIALOGUE_SCENE.instantiate()
	get_tree().current_scene.add_child(dialogue)
	dialogue.present("Message in a Bottle", story_lines)
	queue_free()