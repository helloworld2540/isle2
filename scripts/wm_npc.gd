extends Area2D
class_name WorldNPC

@export var npc_id: String = "npc_1"
@export var npc_name: String = "Friendly Cleaner"
@export_multiline var dialogue_lines: Array = ["Hello! Welcome to trash island."]
@export_multiline var repeat_dialogue_lines: Array = ["Good to see you again!"]
@export_multiline var quest_complete_lines: Array = ["Thanks for the help!"]
@export_multiline var tier2_lines: Array = ["Tier 2 unlocked. Bring more!"]
@export var reward_trash: int = 5
@export var reward_mat: String = "Polyethylene"

@export var quest_material: String = ""
@export var quest_amount: int = 0
@export var quest_reward_mat: String = "Polyethylene"
@export var quest_reward_amount: int = 0

@export var quest2_material: String = ""
@export var quest2_amount: int = 0
@export var quest2_reward_mat: String = "Polyethylene"
@export var quest2_reward_amount: int = 0

var _panel: CanvasLayer = null
var _visited_flag := false
var _quest_done := false
var _quest2_done := false

func _ready() -> void:
	add_to_group("npc")
	body_entered.connect(_on_body_entered)
	_visited_flag = _load_visited()
	_quest_done = _load_quest_done(1)
	_quest2_done = _load_quest_done(2)
	var tween := create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_refresh_name_label()

func _load_visited() -> bool:
	var data := SaveManager.load_game()
	var visited: Dictionary = data.get("npc_visited", {})
	return bool(visited.get(npc_id, false))

func _mark_visited() -> void:
	var data := SaveManager.load_game()
	var visited: Dictionary = data.get("npc_visited", {})
	visited[npc_id] = true
	data["npc_visited"] = visited
	SaveManager.save_game(data)

func _load_quest_done(tier: int) -> bool:
	var data := SaveManager.load_game()
	var key := "npc_quests" if tier == 1 else "npc_quests2"
	var done: Dictionary = data.get(key, {})
	return bool(done.get(npc_id, false))

func _mark_quest_done(tier: int) -> void:
	var data := SaveManager.load_game()
	var key := "npc_quests" if tier == 1 else "npc_quests2"
	var done: Dictionary = data.get(key, {})
	done[npc_id] = true
	data[key] = done
	SaveManager.save_game(data)

func _on_body_entered(body: Node) -> void:
	if _panel and is_instance_valid(_panel):
		return
	if not (body is Node2D) or not body.is_in_group("player"):
		return
	_show_dialogue()

func _prepare_lines() -> Array:
	if not _visited_flag:
		return dialogue_lines
	if _quest2_done:
		return quest_complete_lines if not quest_complete_lines.is_empty() else repeat_dialogue_lines
	if _quest_done:
		return tier2_lines if not tier2_lines.is_empty() else repeat_dialogue_lines
	return repeat_dialogue_lines

func _show_dialogue() -> void:
	var first_visit := not _visited_flag
	var lines := _prepare_lines()

	get_tree().paused = true
	_panel = CanvasLayer.new()
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.layer = 200
	get_tree().current_scene.add_child(_panel)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(dim)

	var container := CenterContainer.new()
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	_panel.add_child(container)

	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(480, 0)
	container.add_child(box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	box.add_child(vbox)

	var title := Label.new()
	title.text = npc_name
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	for line in lines:
		var lbl := Label.new()
		lbl.text = str(line)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(440, 0)
		vbox.add_child(lbl)

	if first_visit and reward_trash > 0:
		var reward_lbl := Label.new()
		reward_lbl.text = "You received %d %s!" % [reward_trash, reward_mat]
		reward_lbl.modulate = Color(0.7, 1.0, 0.75, 1)
		vbox.add_child(reward_lbl)
		GameState.add_trash_type(reward_mat, reward_trash)
		AudioManager.play_sfx("pickup")
		_mark_visited()
		_visited_flag = true

	# Tier 1 quest.
	if not first_visit and not _quest_done and quest_material != "" and quest_amount > 0:
		_add_quest_ui(vbox, 1, quest_material, quest_amount, quest_reward_mat, quest_reward_amount)

	# Tier 2 quest.
	if not first_visit and _quest_done and not _quest2_done and quest2_material != "" and quest2_amount > 0:
		_add_quest_ui(vbox, 2, quest2_material, quest2_amount, quest2_reward_mat, quest2_reward_amount)

	var ok := Button.new()
	ok.text = "OK"
	ok.custom_minimum_size = Vector2(120, 44)
	ok.pressed.connect(_close)
	vbox.add_child(ok)

func _add_quest_ui(vbox: VBoxContainer, tier: int, mat: String, amount: int, reward_mat: String, reward_amount: int) -> void:
	var have := int(GameState.trash_by_type.get(mat, 0))
	var quest_lbl := Label.new()
	quest_lbl.text = "Quest: bring %d %s (you have %d)." % [amount, mat, have]
	quest_lbl.modulate = Color(0.85, 0.9, 1.0, 0.95)
	quest_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_lbl.custom_minimum_size = Vector2(440, 0)
	vbox.add_child(quest_lbl)

	var turn_in := Button.new()
	turn_in.text = "Turn in %d %s" % [amount, mat]
	turn_in.custom_minimum_size = Vector2(200, 44)
	turn_in.disabled = have < amount
	turn_in.pressed.connect(func():
		if GameState.consume_trash_type(mat, amount):
			if reward_amount > 0:
				GameState.add_trash_type(reward_mat, reward_amount)
				var r := Label.new()
				r.text = "Reward: %d %s!" % [reward_amount, reward_mat]
				r.modulate = Color(0.7, 1.0, 0.75, 1)
				vbox.add_child(r)
			AudioManager.play_sfx("upgrade")
			if tier == 1:
				_quest_done = true
				_mark_quest_done(1)
			else:
				_quest2_done = true
				_mark_quest_done(2)
			_refresh_name_label()
			_close()
			_show_dialogue()
	)
	vbox.add_child(turn_in)

func _close() -> void:
	if _panel and is_instance_valid(_panel):
		_panel.queue_free()
		_panel = null
	get_tree().paused = false
	_refresh_name_label()

func _refresh_name_label() -> void:
	if not has_node("NameLabel"):
		return
	var nl: Label = $NameLabel
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
