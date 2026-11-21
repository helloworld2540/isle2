extends Area2D
class_name WorldNPC

## A named islander on the world map: dialogue, first-visit gift and
## two-tier material quests; optional milestone beats (achievement
## id → line) for story awareness.

@export_group("NPC Identity")
@export var npc_id: String = "npc_1"
@export var npc_name: String = "Friendly Cleaner"
@export_range(1, 4) var npc_sprite_index: int = 1
## Authored placeholder portrait shown on the dialogue card (sprites/npc/).
@export var portrait: Texture2D

@export_group("Dialogue")
@export_multiline var dialogue_lines: Array[String] = ["Hello! Welcome to trash island."]
@export_multiline var repeat_dialogue_lines: Array[String] = ["Good to see you again!"]
@export_multiline var quest_complete_lines: Array[String] = ["Thanks for the help!"]
@export_multiline var tier2_lines: Array[String] = ["Tier 2 unlocked. Bring more!"]
@export_multiline var flavour_variants: Array[String] = ["The tides are calm today.", "Keep the shores clean!", "Every bit of trash helps."]
@export_multiline var ambient_bubbles: Array[String] = ["*quietly humming*", "Cleanup in progress...", "Another shore, another day."]
## When set, the NPC appends the day's tide observation (TideReport.ambient_line)
## to the end of their conversation, so the island shares one opinion of the
## sea today. Reserved for NPCs who would plausibly notice the water — Oda the
## tide-watcher, mostly.
@export var tide_aware: bool = false
## Optional story beats: achievement id → line. Every earned entry is
## appended to later conversations, so an NPC can notice several things at
## once. Reads the unlock list — no dedicated save state.
@export var milestone_beats: Dictionary = {}

@export_group("First Visit Reward")
@export var reward_trash: int = 5
@export var reward_mat: String = "Polyethylene"

@export_group("Quest Tier 1")
@export var quest_material: String = ""
@export var quest_amount: int = 0
@export var quest_reward_mat: String = "Polyethylene"
@export var quest_reward_amount: int = 0

@export_group("Quest Tier 2")
@export var quest2_material: String = ""
@export var quest2_amount: int = 0
@export var quest2_reward_mat: String = "Polyethylene"
@export var quest2_reward_amount: int = 0

# Private State Variables
# Untyped so the script works before the editor refreshes its class cache.
var _dialogue = null
var _visited_flag: bool = false
var _quest_done: bool = false
var _quest_ready_fired: bool = false  ## Guard so the one-shot quest nudge only fires from this instance.
var _quest2_done: bool = false
var _visit_count: int = 0

const DIALOGUE_SCENE := preload("res://scenes/ui/npc_dialogue.tscn")
const FxSparkle := preload("res://scripts/fx_sparkle.gd")
const NpcQuests := preload("res://scripts/npc_quests.gd")

## After the Tidekeeper's Pact is funded the island talks about it. Loose
## harbor gossip, rarely gold-mint — the tide's crew keeps score.
const PACT_GOSSIP := [
	"Saw the pact keeper pass by — good folk.",
	"That's THE one. The one who kept the reef.",
	"Money talks; on this island, it also keeps the tide.",
	"They rebuild whole reefs where others see trash.",
	"Word is the tide itself answers them now.",
]

# Nodes
@onready var sprite: Sprite2D = $Sprite
@onready var name_label: Label = $NameLabel
@onready var ready_marker: Label = $ReadyMarker
@onready var quest_progress_label: Label = $QuestProgress
@onready var ambient_bubble: Label = $AmbientBubble

# Timers
var _ambient_timer: float = 0.0
var _ambient_next: float = 4.5
var _refresh_tick: float = 0.0

func _ready() -> void:
	add_to_group("npc")
	body_entered.connect(_on_body_entered)
	
	_load_saved_data()
	_apply_npc_sprite()
	_start_idle_animations()
	_update_ui_state()

func _process(delta: float) -> void:
	_ambient_timer += delta
	if _ambient_timer >= _ambient_next:
		_ambient_timer = 0.0
		_ambient_next = randf_range(3.0, 7.5)
		if not _dialogue:
			_show_ambient_bubble()
			
	_refresh_tick += delta
	if _refresh_tick >= 0.4:
		_refresh_tick = 0.0
		_update_ui_state()
		if not _quest_ready_fired:
			var quest_tier := NpcQuests.active_tier(self)
			if quest_tier > 0 and NpcQuests.has_items(self, quest_tier):
				_quest_ready_fired = true
				TutorialDirector.nudge("quest")
		if not _visited_flag and TutorialDirector.is_tour_complete():
			TutorialDirector.nudge("meet")

func _unhandled_input(event: InputEvent) -> void:
	# A queued card (waiting behind another popup) is not on screen yet; keys
	# must not close a conversation the player has not seen.
	if not _dialogue or not _dialogue.visible: return
	
	if event.is_action_pressed("ui_cancel") or \
		(event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]):
		get_viewport().set_input_as_handled()
		_close()

func _on_body_entered(body: Node) -> void:
	if not _dialogue and body is Node2D and body.is_in_group("player"):
		_show_dialogue()

# --- Initialization & State ---

func _load_saved_data() -> void:
	var data := SaveManager.load_game()
	_visited_flag = data.get("npc_visited", {}).get(npc_id, false)
	_visit_count = data.get("npc_visit_counts", {}).get(npc_id, 0)
	_quest_done = data.get("npc_quests", {}).get(npc_id, false)
	_quest2_done = data.get("npc_quests2", {}).get(npc_id, false)

func _save_flag(dict_key: String, value: Variant) -> void:
	SaveManager.update_nested(dict_key, {npc_id: value})

func _bump_visit_count() -> void:
	_visit_count += 1
	_save_flag("npc_visit_counts", _visit_count)

# --- Animations ---

func _start_idle_animations() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if sprite:
		var sp_tween := create_tween().set_loops()
		sp_tween.tween_property(sprite, "position:y", sprite.position.y - 4.0, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sp_tween.tween_property(sprite, "position:y", sprite.position.y, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply_npc_sprite() -> void:
	# World-map sprites live in sprites/wm_npc/ and are named after the
	# islander they depict (wm_mara.png, wm_tom.png, ...), the same naming
	# language as the dialogue portraits in sprites/npc/ (portrait_mara.png).
	var path := "res://sprites/wm_npc/wm_%s.png" % npc_id.trim_prefix("npc_")
	
	if not ResourceLoader.exists(path) and sprite:
		# Fallback for the un-named template instance: numeric sprite index
		# (1 = Mara, 2 = Tom, 3 = Nina, 4 = Kai).
		var names: Array[String] = ["", "mara", "tom", "nina", "kai"]
		path = "res://sprites/wm_npc/wm_%s.png" % names[clampi(npc_sprite_index, 1, 4)]

	if ResourceLoader.exists(path) and sprite:
		sprite.texture = load(path)
		sprite.centered = true
		sprite.scale = Vector2(0.46, 0.46)
		sprite.position = Vector2(0, -10)
		
		var sprite_height: float = sprite.get_rect().size.y * sprite.scale.y
		var top: float = sprite.position.y - sprite_height * 0.5
		
		if name_label:
			name_label.offset_top = top - 28.0
			name_label.offset_bottom = top - 4.0
		if quest_progress_label:
			quest_progress_label.offset_top = top + 2.0
			quest_progress_label.offset_bottom = top + 26.0
			
	if has_node("Body"):
		$Body.visible = false

# --- UI Updates ---

func _update_ui_state() -> void:
	_refresh_name_label()
	_refresh_quest_progress()
	_glow_quest_ready()

func _refresh_quest_progress() -> void:
	if not quest_progress_label: return
	
	if _quest2_done:
		quest_progress_label.text = "Quests: complete"
		quest_progress_label.modulate = Color(1.0, 0.85, 0.3, 0.95)
		return
	
	var tier := NpcQuests.active_tier(self)
	if tier == 0:
		quest_progress_label.text = ""
		return
	
	var config := NpcQuests.config(self, tier)
	var material := String(config.get("material", ""))
	var amount := int(config.get("amount", 0))
	var have := int(GameState.trash_by_type.get(material, 0))
	quest_progress_label.text = "Quest: %d/%d %s" % [mini(have, amount), amount, material]
	quest_progress_label.modulate = Color(0.6, 1.0, 0.7, 1.0) if have >= amount else Color(0.7, 0.95, 1.0, 0.9)

func _refresh_name_label() -> void:
	var nl: Label = name_label
	if not nl: return
	
	if _quest2_done:
		nl.text = npc_name + " **"
		nl.modulate = Color(1.0, 0.75, 0.2, 1.0)
	elif _quest_done:
		nl.text = npc_name + " *"
		nl.modulate = Color(1.0, 0.85, 0.3, 0.95)
	elif _visited_flag:
		nl.text = npc_name + " (visited)"
		nl.modulate = Color(0.75, 0.9, 0.75, 0.9)
	else:
		nl.text = npc_name
		nl.modulate = Color(1.0, 1.0, 1.0, 0.9)

func _glow_quest_ready() -> void:
	var tier := NpcQuests.active_tier(self)
	var ready := tier > 0 and NpcQuests.has_items(self, tier)
	
	if sprite:
		sprite.modulate = Color(1.0, 0.95, 0.55, 1.0) if ready else Color(1.0, 1.0, 1.0, 1.0)
		
	if has_node("Body") and $Body:
		$Body.color = Color(1.0, 0.95, 0.55, 1.0) if ready else Color(0.95, 0.72, 0.45, 1.0)
	
	# The star is the same language as the HUD's "Next: <name>" line: a turn-in
	# is waiting. It hides as soon as the bag no longer satisfies the quest.
	if ready_marker:
		if ready and not ready_marker.visible and not GameSettings.reduce_motion:
			_pop_ready_marker()
		ready_marker.visible = ready


func _pop_ready_marker() -> void:
	ready_marker.scale = Vector2(0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(ready_marker, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- Quest Tracking ---

## Snapshot of the quest this NPC is currently offering, for the HUD tracker.
func get_active_quest() -> Dictionary:
	return NpcQuests.entry(self)


# --- Dialogue System ---

func _prepare_lines() -> Array:
	if not _visited_flag: return dialogue_lines
	
	var base_lines: Array = repeat_dialogue_lines
	if _quest2_done and not quest_complete_lines.is_empty():
		base_lines = quest_complete_lines
	elif _quest_done and not tier2_lines.is_empty():
		base_lines = tier2_lines
		
	return base_lines + _flavour_lines()

func _flavour_lines() -> Array:
	var out: Array = []
	if not flavour_variants.is_empty():
		out.append(str(flavour_variants[_visit_count % flavour_variants.size()]))

	var banter := _personality_banter()
	if not banter.is_empty():
		out.append(str(banter[_visit_count % banter.size()]))

	# Tide-aware islanders sprinkle the day's sea into the conversation, as
	# almanac Oda would; it costs no extra state and flips with the calendar.
	if tide_aware:
		if GameSettings.hide_tide:
			# The sea keeps its own counsel — and so does every watcher on it.
			out.append("(She does not say the tide. She does not say where the light comes from.)")
		else:
			out.append(TideReport.ambient_line())
		# If the keeper paid the dockhand for tomorrow's tide, the watcher
		# notices — foresight is the one thing she respects.
		if GameState.harbor_tip_purchased():
			out.append("Paid the dockhand for tomorrow, did you? Sly. Tomorrow keeps its own hours — but tell me, what did the water whisper?")
		# A century of tides earns a single line in her private book.
		if GameState.tide_days_visited == 100:
			out.append("A hundred tides. I put you in the book — there is room for very few names.")
		# A week with the tide is a long-standing joke between two people who
		# take staying seriously.
		if GameState.tide_streak >= 7:
			out.append("A whole week of tides. You are the reason my almanac has a spine.")

	# Milestones the island noticed — one line per earned badge, appended once
	# the unlock lands, so each beat needs no bespoke state machine.
	for beat_id in milestone_beats:
		if GameState.unlocked_achievements.has(String(beat_id)):
			var line := String(milestone_beats[beat_id])
			if not line.is_empty():
				out.append(line)
	return out

func _show_dialogue(status: String = "", positive: bool = true) -> void:
	var first_visit := not _visited_flag
	var lines := _prepare_lines()
	_bump_visit_count()
	
	_dialogue = DIALOGUE_SCENE.instantiate()
	get_tree().current_scene.add_child(_dialogue)
	_dialogue.turn_in_requested.connect(_on_turn_in_requested)
	_dialogue.present(npc_name, lines, portrait)
	
	if status != "":
		_dialogue.show_status(status, positive)
	
	if first_visit:
		var gift_deferred := reward_trash > 0 and not NpcQuests.gift_fits(reward_mat, reward_trash, GameState)
		if gift_deferred:
			# The bag cannot hold the gift this visit, so it is not given at all;
			# the player is warned to sell at the shop instead. The visit flag
			# stays clear, so the gift is offered again once the bag has room.
			_dialogue.show_status("Bag full - sell materials at the Shop!", false)
		elif reward_trash > 0:
			GameState.add_trash_type_weighted(reward_mat, reward_trash)
			_dialogue.show_reward("You received %d %s!" % [reward_trash, reward_mat])
			AudioManager.play_sfx("pickup")
			# Sparks read as the reward being handed over, so they wait until
			# the card is dismissed instead of bursting behind its dimmer.
			_dialogue.closed.connect(_spawn_reward_sparks, CONNECT_ONE_SHOT)
		if reward_trash <= 0 or not gift_deferred:
			# Visited is tracked for every NPC, not only reward-granting ones, so
			# quests reveal themselves and repeat dialogue kicks in for all.
			_save_flag("npc_visited", true)
			_visited_flag = true
			_update_ui_state()
	else:
		var tier := NpcQuests.active_tier(self)
		if tier > 0:
			_configure_quest(tier)


# The turn-in button only lights up when the player has the goods and the
# reward will actually fit in the bag.
func _configure_quest(tier: int) -> void:
	if not _dialogue:
		return
	
	var data := NpcQuests.turn_in(self, tier)
	if data.is_empty():
		return
	
	var amount := int(data.get("amount", 0))
	var mat := String(data.get("material", ""))
	var have := int(data.get("have", 0))
	_dialogue.show_quest(
		tier,
		"Quest: bring %d %s (you have %d)." % [amount, mat, have],
		"Turn in %d %s" % [amount, mat],
		have >= amount and bool(data.get("fits", false))
	)


func _on_turn_in_requested(tier: int) -> void:
	var data := NpcQuests.turn_in(self, tier)
	if data.is_empty():
		return
	
	# The hand-in frees the quest weight before the reward lands, but the
	# reward must still fit afterwards — a full bag must not swallow it. Bail
	# out (with a nudge toward the shop) instead of accepting a partial reward.
	if not bool(data.get("fits", false)):
		_dialogue.show_status("Bag full - sell materials at the Shop!", false)
		return
	
	var mat := String(data.get("material", ""))
	var amount := int(data.get("amount", 0))
	var rw_mat := String(data.get("reward_material", ""))
	var rw_amt := int(data.get("reward_amount", 0))
	
	if not GameState.consume_trash_type(mat, amount):
		return
	
	var hero_unlocked := GameState.record_quest_turn_in()
	var gained := rw_amt
	if rw_amt > 0:
		gained = GameState.add_trash_type_weighted(rw_mat, rw_amt)
	
	AudioManager.play_sfx("quest_complete")
	
	if tier == 1:
		_quest_done = true
		_save_flag("npc_quests", true)
	else:
		_quest2_done = true
		_save_flag("npc_quests2", true)
		# The Harbor Hero card is the bigger beat when both land together.
		if not hero_unlocked:
			GameState.notify_npc_quest_line_completed(npc_name)
	
	_update_ui_state()
	
	var status := ""
	if rw_amt > 0:
		status = "Reward: %d %s!" % [gained, rw_mat] if gained >= rw_amt else "Reward: %d/%d %s (cap reached)" % [gained, rw_amt, rw_mat]
	
	_close()
	await get_tree().process_frame
	_show_dialogue(status, gained >= rw_amt)


func _close() -> void:
	if _dialogue:
		_dialogue.dismiss()
		_dialogue = null
	_refresh_name_label()

# --- FX & Ambient ---

func _show_ambient_bubble() -> void:
	if not ambient_bubble:
		return
	
	if GameState.tidekeeper and randf() < 0.35:
		# Pact gossip leg — mint-green, rarer than the hum.
		ambient_bubble.text = str(PACT_GOSSIP.pick_random())
		ambient_bubble.modulate = Color(0.55, 0.97, 0.85, 0.0)
	else:
		if ambient_bubbles.is_empty():
			return
		ambient_bubble.text = str(ambient_bubbles.pick_random())
		ambient_bubble.modulate = Color(1.0, 1.0, 0.9, 0.0)
	
	var tw := create_tween()
	tw.tween_property(ambient_bubble, "modulate:a", 0.85, 0.14)
	tw.tween_interval(1.6)
	tw.tween_property(ambient_bubble, "modulate:a", 0.0, 0.4)


func _personality_banter() -> Array:
	return NpcQuests.banter(npc_id)

func _spawn_reward_sparks() -> void:
	# Rewards spark above the islander's head; burst() emits and frees for us.
	FxSparkle.burst(get_tree().current_scene, global_position + Vector2(0, -20), Color(1.0, 0.86, 0.35, 1.0), {"amount": 18, "lifetime": 0.6, "vel_min": 20.0, "vel_max": 60.0, "gravity": 40.0})
