extends Area2D
class_name WorldKeeperStar

## THE KEEPER'S STAR — the one the island saved for the keeper who kept
## everything.
##
## A sixth starfish, hidden at the far point east of the watcher. It does not
## exist until ISLAND STEWARD is earned (the node frees itself otherwise, so
## fresh shores and unfinished journals never see it), it is not counted
## toward the five-star STARLIGHT set, and finding it pays the island's last
## gift: a card, a bell, +$50 and THE KEEPER'S STAR achievement.
##
## Finding it counts nothing else — it is the epilogue, not another chore on
## the checklist.

const DIALOGUE_SCENE := preload("res://scenes/ui/npc_dialogue.tscn")
const FLOATING_TEXT_SCENE := preload("res://scenes/ui/floating_text.tscn")
const FxSparkle := preload("res://scripts/fx_sparkle.gd")


func _ready() -> void:
	# The star is a secret the island only shares with its steward, and a
	# one-shot after that. Both checks free the node quietly.
	if GameState.keeper_star_found:
		queue_free()
		return
	if not GameState.is_achievement_unlocked("island_steward"):
		queue_free()
		return
	add_to_group("keeper_star")
	body_entered.connect(_on_body_entered)
	# A slow indigo glint so it reads as collectible, not decor, and unlike
	# the other starfish it does not tick — it waits.
	if not GameSettings.reduce_motion and has_node("Sprite2D"):
		var tw := create_tween().set_loops()
		tw.tween_property($Sprite2D, "modulate", Color(1.16, 1.1, 1.5, 1.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property($Sprite2D, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node) -> void:
	if not (body is Node2D and body.is_in_group("player")):
		return
	if GameState.keeper_star_found:
		queue_free()
		return
	GameState.mark_keeper_star_found()
	AudioManager.play_sfx("harbor_bell", 0.7)
	set_deferred("monitoring", false)
	FxSparkle.burst(get_tree().current_scene, global_position, Color(0.65, 0.7, 1.6, 1.0), {"amount": 22, "lifetime": 0.9, "vel_min": 25.0, "vel_max": 80.0, "gravity": 20.0})
	# A one-shot card from the island itself — the watcher does not speak, so
	# the island does it for him.
	var dialogue := DIALOGUE_SCENE.instantiate()
	get_tree().current_scene.add_child(dialogue)
	dialogue.present(
		"THE KEEPER'S STAR",
		[
			"You walked all the way to the far point and the island was waiting.",
			"One last star, keeper — the one the island saved. Not for reef or tide, but for you, for staying.",
			"Keep the shore and keep the ledger. The rest is up to you.",
			"— the island",
		]
	)
	# A floating marker so the reward reads at a glance.
	var lbl: FloatingText = FLOATING_TEXT_SCENE.instantiate()
	lbl.position = global_position + Vector2(-52.0, -34.0)
	lbl.rise_distance = 34.0
	lbl.hold_time = 1.4
	lbl.z_index = 40
	get_tree().current_scene.add_child(lbl)
	lbl.present("The Keeper's Star  +$%d" % GameState.KEEPER_STAR_MONEY, Color(1.0, 0.84, 0.4, 1.0), 20)
	# Let the pop play before the node leaves the tree.
	await get_tree().create_timer(0.6).timeout
	queue_free()
