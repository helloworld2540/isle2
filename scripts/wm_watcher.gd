extends Area2D

## The far point: a rumour with a body. A hooded figure who never speaks,
## only watches. Meeting them once is remembered by the island — and by the
## achievement catalogue.

const DIALOGUE_SCENE := preload("res://scenes/ui/npc_dialogue.tscn")


func _ready() -> void:

	# The lantern breathes — a slow warm swell you can spot across the water.
	# Reduced motion holds it still; he was never about the light.
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if GameState.is_achievement_unlocked("whole_sea"):
		# Every page the sea ever wrote has been read. The watcher sets the
		# lantern down: no pulse, just a dim, steady ember. Nothing left to
		# watch for — and nothing left that needs watching.
		if sprite:
			sprite.modulate = Color(0.72, 0.78, 0.9, 0.72)
	elif not GameSettings.reduce_motion:
		if sprite:
			var tw := create_tween().set_loops()
			tw.tween_property(sprite, "modulate", Color(1.0, 0.95, 0.8, 1.0), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(sprite, "modulate", Color(0.85, 0.9, 1.0, 0.96), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if GameState.watcher_seen:
		# He is still there. He does not walk, does not announce, does not
		# leave. He was never going to be caught twice.
		return
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not (body is Node2D and body.is_in_group("player")):
		return
	if GameState.watcher_seen:
		return
	GameState.mark_watcher_seen()
	# The harbor bell, far away and low — the island noticed you noticed.
	AudioManager.play_sfx("harbor_bell", 0.6)
	set_deferred("monitoring", false)
	var dialogue := DIALOGUE_SCENE.instantiate()
	get_tree().current_scene.add_child(dialogue)
	dialogue.present(
		"THE FAR POINT",
		[
			"You turned around fast enough to catch him. Nobody ever does.",
			"He watches the water because he has to. The island shows you four tides; it keeps the fifth to itself.",
			"He does not ask you to leave. He never wanted anything moved — only kept.",
			"The lantern stays lit. That is all you can know, and all you should.",
		]
	)
