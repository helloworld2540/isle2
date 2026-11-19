extends Area2D

## A "message in a bottle" collectible. Walking over one reads it, marks it
## read in GameState and opens the story on the dialogue card. Read bottles
## never respawn (their ids are saved under bottles_read).

const DIALOGUE_SCENE := preload("res://scenes/ui/npc_dialogue.tscn")
const BottleCatalog := preload("res://scripts/bottle_catalog.gd")

## The base collectathon is three bottles. The fourth appears only after the
## Tidekeeper's Pact is funded — a reply written for the keeper alone.
const BASE_BOTTLE_IDS := ["bottle_tide", "bottle_gull", "bottle_light"]
const PACT_BOTTLE_ID := "bottle_pact"
## The keeper's own note appears only once the tide almanac is finished —
## the first keeper's answer to the player who learned the sea.
const KEEPER_BOTTLE_ID := "bottle_keeper"
## Corl's folded paper washes up once the keeper has bought seven days of
## tomorrow. The foresight arc's one physical artifact.
const CORL_BOTTLE_ID := "bottle_corl"
## The watcher's note washes up once the far point has been seen — the
## rumour's paper tail, on the path you took to him.
const WATCHER_BOTTLE_ID := "bottle_watcher"
## The far point's reply washes up once the keeper's star is found — the
## epilogue's own paper tail, at the tip of the island.
const FAR_POINT_BOTTLE_ID := "bottle_far_point"

@export var bottle_id: String = "bottle_1"
## Optional override; when empty (the default) the canonical text comes from
## BottleCatalog so the world pickup and the Tide Ledger never drift apart.
@export_multiline var story_lines: Array[String] = []

func _ready() -> void:
	if bottle_id == PACT_BOTTLE_ID and not _pact_arc_complete():
		# The pact message only exists for keepers who funded the Pact — it is
		# not a fourth bottle to squint at from a distance.
		queue_free()
		return
	if bottle_id == KEEPER_BOTTLE_ID and not _almanac_complete():
		# The keeper only writes back once the almanac is complete.
		queue_free()
		return
	if bottle_id == CORL_BOTTLE_ID and not _whisperer_complete():
		# Corl only leaves the counter when he is paid seven days' worth.
		queue_free()
		return
	if bottle_id == WATCHER_BOTTLE_ID and not GameState.watcher_seen:
		# The watcher does not answer what has not been seen.
		queue_free()
		return
	if bottle_id == FAR_POINT_BOTTLE_ID and not GameState.keeper_star_found:
		# The far point only replies to the keeper who found the star.
		queue_free()
		return
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


## The pact message exists once the player funded the Tidekeeper's Pact AND
## found (or read) the three base bottles. Reading them after the purchase
## works too — the bottle simply appears on any later world load.
func _pact_arc_complete() -> bool:
	if not GameState.tidekeeper:
		return false
	for base in BASE_BOTTLE_IDS:
		if not GameState.is_story_read(base):
			return false
	return true


## The almanac gate for the keeper's note.
func _almanac_complete() -> bool:
	return GameState.tides_logged.size() >= 4


## Seven days of tomorrow, bought and paid for — the flag Corl's bottle
## reads. Achieves alongside THE WHISPERER (the catalogue reads the same
## counter), so the two land in the same breath.
func _whisperer_complete() -> bool:
	return GameState.harbor_tips_bought >= 7


func _read() -> void:
	if GameState.is_story_read(bottle_id):
		queue_free()
		return
	GameState.mark_story_read(bottle_id)
	# The far point writes back — one card, once.
	if bottle_id == WATCHER_BOTTLE_ID:
		TutorialDirector.nudge("watcher_note")
	# One-shot pointer to the Tide Ledger once the base set is complete.
	var base_found := 0
	for id in GameState.bottles_read:
		if id != PACT_BOTTLE_ID and id != KEEPER_BOTTLE_ID and id != CORL_BOTTLE_ID and id != WATCHER_BOTTLE_ID and id != FAR_POINT_BOTTLE_ID:
			base_found += 1
	if base_found >= 3:
		TutorialDirector.nudge("ledger")
	# Corl and the first keeper get the bell; the far point gets the deep swell.
	if bottle_id == CORL_BOTTLE_ID or bottle_id == KEEPER_BOTTLE_ID or bottle_id == FAR_POINT_BOTTLE_ID:
		AudioManager.play_sfx("harbor_bell", 0.7)
	else:
		AudioManager.play_sfx("quest_complete", 0.95)
	set_deferred("monitoring", false)
	
	var lines := story_lines if not story_lines.is_empty() else BottleCatalog.lines_of(bottle_id)
	var dialogue = DIALOGUE_SCENE.instantiate()
	get_tree().current_scene.add_child(dialogue)
	dialogue.present(BottleCatalog.title_of(bottle_id), lines)
	queue_free()
