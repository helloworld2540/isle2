extends Area2D

## The far point: a rumour with a body. A hooded figure who never speaks,
## only watches. Meeting them once is remembered by the island — and by the
## achievement catalogue.

const DIALOGUE_SCENE := preload("res://scenes/ui/npc_dialogue.tscn")

var _lantern_tween: Tween = null


func _ready() -> void:
	if GameState.watcher_seen:
		# He was never there twice. The save remembers him, so the island does
		# not keep him either.
		queue_free()
		return

	# The lantern breathes — a slow warm swell you can spot across the water.
	# Reduced motion holds it still; he was never about the light.
	var sprite := get_node("Sprite2D") as Sprite2D
	if GameState.is_achievement_unlocked("whole_sea"):
		# Every page the sea ever wrote has been read. The watcher sets the
		# lantern down: no pulse, just a dim, steady ember. Nothing left to
		# watch for — and nothing left that needs watching.
		if sprite:
			sprite.modulate = Color(0.72, 0.78, 0.9, 0.72)
	elif not GameSettings.reduce_motion:
		if sprite:
			_lantern_tween = create_tween().set_loops()
			_lantern_tween.tween_property(sprite, "modulate", Color(0.92, 0.9, 0.77, 1.0), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_lantern_tween.tween_property(sprite, "modulate", Color(0.85, 0.9, 1.0, 0.96), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
			"You turned in time to catch him watching. No one else ever has.",
			"He watches the water because that is his job. The island shows you four tides and hides the fifth.",
			"He doesn't ask you to leave. He never wanted anything changed — only looked after.",
			"The lantern stays lit. That is all you can know.",
		]
	)

	# The keeper turned around fast enough — so the island lets him go. He
	# dissolves into the water behind the card; the watcher never stands there
	# twice, not even in the same sitting.
	var sprite := get_node("Sprite2D") as Sprite2D
	if _lantern_tween and _lantern_tween.is_valid():
		_lantern_tween.kill()
	if sprite:
		var tw := create_tween()
		if GameSettings.reduce_motion:
			tw.tween_property(sprite, "modulate", Color(sprite.modulate.r, sprite.modulate.g, sprite.modulate.b, 0.0), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		else:
			tw.tween_property(sprite, "modulate", Color(sprite.modulate.r, sprite.modulate.g, sprite.modulate.b, 0.0), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(queue_free)
	else:
		queue_free()
