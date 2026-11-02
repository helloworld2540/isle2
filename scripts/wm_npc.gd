extends Area2D
class_name WorldNPC

@export var npc_id: String = "npc_1"
@export var npc_name: String = "Friendly Cleaner"
@export_multiline var dialogue_lines: Array[String] = ["Hello! Welcome to trash island."]
@export_multiline var repeat_dialogue_lines: Array[String] = ["Good to see you again!"]
@export_multiline var quest_complete_lines: Array[String] = ["Thanks for the help!"]
@export_multiline var tier2_lines: Array[String] = ["Tier 2 unlocked. Bring more!"]
@export_multiline var flavour_variants: Array[String] = ["The tides are calm today.", "Keep the shores clean!", "Every bit of trash helps."]
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
var _visit_count := 0
var _quest_progress_label: Label = null
var _sprite: Sprite2D = null

@export_range(1, 4) var npc_sprite_index: int = 1

func _ready() -> void:
	add_to_group("npc")
	body_entered.connect(_on_body_entered)
	_visited_flag = _load_visited()
	_visit_count = _load_visit_count()
	_quest_done = _load_quest_done(1)
	_quest2_done = _load_quest_done(2)
	if not AudioManager.get_reduced_motion():
		var tween := create_tween().set_loops()
		tween.tween_property(self, "scale", Vector2(1.06, 1.06), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_build_quest_progress()
	_apply_npc_sprite()
	if is_instance_valid(_sprite) and not AudioManager.get_reduced_motion():
		var sp_tween := create_tween().set_loops()
		sp_tween.tween_property(_sprite, "position:y", _sprite.position.y - 4.0, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sp_tween.tween_property(_sprite, "position:y", _sprite.position.y, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_refresh_name_label()
	_refresh_quest_progress()
	_glow_quest_ready()

func _build_quest_progress() -> void:
	if is_instance_valid(_quest_progress_label):
		_refresh_quest_progress()
		return
	if has_node("QuestProgress"):
		_quest_progress_label = $QuestProgress
		if not is_instance_valid(_quest_progress_label):
			_quest_progress_label = null
	if _quest_progress_label == null:
		_quest_progress_label = load("res://scenes/ui/label.tscn").instantiate() as Label
		_quest_progress_label.name = "QuestProgress"
		_quest_progress_label.offset_left = -70
		_quest_progress_label.offset_top = -78
		_quest_progress_label.offset_right = 70
		_quest_progress_label.offset_bottom = -56
		_quest_progress_label.text = ""
		_quest_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_quest_progress_label.modulate = Color(0.85, 0.9, 1.0, 0.95)
		_quest_progress_label.add_theme_font_size_override("font_size", 11)
		_quest_progress_label.z_index = 20
		add_child(_quest_progress_label)
	_refresh_quest_progress()

func _refresh_quest_progress() -> void:
	if not is_instance_valid(_quest_progress_label):
		return
	if _quest2_done:
		_quest_progress_label.text = "Quests: complete"
		_quest_progress_label.modulate = Color(1.0, 0.85, 0.3, 0.95)
		return
	if _quest_done:
		if quest2_material != "" and quest2_amount > 0 and not _quest2_done:
			var have2 := int(GameState.trash_by_type.get(quest2_material, 0))
			_quest_progress_label.text = "Quest: %d/%d %s" % [min(have2, quest2_amount), quest2_amount, quest2_material]
			_quest_progress_label.modulate = Color(0.6, 1.0, 0.7, 1.0) if have2 >= quest2_amount else Color(0.7, 0.95, 1.0, 0.9)
			return
	if _visited_flag and not _quest_done and quest_material != "" and quest_amount > 0:
		var have := int(GameState.trash_by_type.get(quest_material, 0))
		_quest_progress_label.text = "Quest: %d/%d %s" % [min(have, quest_amount), quest_amount, quest_material]
		_quest_progress_label.modulate = Color(0.6, 1.0, 0.7, 1.0) if have >= quest_amount else Color(0.7, 0.95, 1.0, 0.9)
		return
	_quest_progress_label.text = ""

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

func _load_visit_count() -> int:
	var data := SaveManager.load_game()
	var counts: Dictionary = data.get("npc_visit_counts", {})
	return int(counts.get(npc_id, 0))

func _bump_visit_count() -> void:
	_visit_count += 1
	var data := SaveManager.load_game()
	var counts: Dictionary = data.get("npc_visit_counts", {})
	counts[npc_id] = _visit_count
	data["npc_visit_counts"] = counts
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

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_panel) and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _on_body_entered(body: Node) -> void:
	if is_instance_valid(_panel):
		return
	if not (body is Node2D) or not body.is_in_group("player"):
		return
	_show_dialogue()

func _prepare_lines() -> Array:
	if not _visited_flag:
		return dialogue_lines
	if _quest2_done:
		var out := quest_complete_lines if not quest_complete_lines.is_empty() else repeat_dialogue_lines
		return out + _flavour_lines()
	if _quest_done:
		var t := tier2_lines if not tier2_lines.is_empty() else repeat_dialogue_lines
		return t + _flavour_lines()
	return repeat_dialogue_lines + _flavour_lines()

func _flavour_lines() -> Array:
	if flavour_variants.is_empty():
		return []
	var i := _visit_count % flavour_variants.size()
	return [str(flavour_variants[i])]

func _show_dialogue() -> void:
	var first_visit := not _visited_flag
	_bump_visit_count()
	var lines := _prepare_lines()
	get_tree().paused = true
	_panel = load("res://scenes/ui/canvas_layer.tscn").instantiate() as CanvasLayer
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.layer = 200
	var scene_root := get_tree().current_scene
	if is_instance_valid(scene_root):
		scene_root.add_child(_panel)

	var dim := load("res://scenes/ui/color_rect.tscn").instantiate() as ColorRect
	dim.color = Color(0, 0, 0, 0.55)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(dim)

	var container := load("res://scenes/ui/center_container.tscn").instantiate() as CenterContainer
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	_panel.add_child(container)

	var box := load("res://scenes/ui/panel_container.tscn").instantiate() as PanelContainer
	box.custom_minimum_size = Vector2(480, 0)
	container.add_child(box)

	var vbox := load("res://scenes/ui/vbox_container.tscn").instantiate() as VBoxContainer
	vbox.add_theme_constant_override("separation", 10)
	box.add_child(vbox)

	var title := load("res://scenes/ui/label.tscn").instantiate() as Label
	title.text = npc_name
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	for line in lines:
		var lbl := load("res://scenes/ui/label.tscn").instantiate() as Label
		lbl.text = str(line)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(440, 0)
		vbox.add_child(lbl)

	if first_visit and reward_trash > 0:
		var reward_lbl := load("res://scenes/ui/label.tscn").instantiate() as Label
		reward_lbl.text = "You received %d %s!" % [reward_trash, reward_mat]
		reward_lbl.modulate = Color(0.7, 1.0, 0.75, 1)
		vbox.add_child(reward_lbl)
		GameState.add_trash_type_weighted(reward_mat, reward_trash)
		AudioManager.play_sfx("pickup")
		_mark_visited()
		_visited_flag = true

	if not first_visit and not _quest_done and quest_material != "" and quest_amount > 0:
		_add_quest_ui(vbox, 1, quest_material, quest_amount, quest_reward_mat, quest_reward_amount)

	if not first_visit and _quest_done and not _quest2_done and quest2_material != "" and quest2_amount > 0:
		_add_quest_ui(vbox, 2, quest2_material, quest2_amount, quest2_reward_mat, quest2_reward_amount)

	var ok := load("res://scenes/ui/button.tscn").instantiate() as Button
	ok.text = "OK"
	ok.custom_minimum_size = Vector2(120, 44)
	ok.pressed.connect(_close)
	var _escaped_shortcut := Shortcut.new()
	var _escaped_event := InputEventKey.new()
	_escaped_event.keycode = KEY_ESCAPE
	_escaped_shortcut.events = [_escaped_event]
	ok.shortcut = _escaped_shortcut
	vbox.add_child(ok)

func _add_quest_ui(vbox: VBoxContainer, tier: int, mat: String, amount: int, reward_mat: String, reward_amount: int) -> void:
	var have := int(GameState.trash_by_type.get(mat, 0))
	var quest_lbl := load("res://scenes/ui/label.tscn").instantiate() as Label
	quest_lbl.text = "Quest: bring %d %s (you have %d)." % [amount, mat, have]
	quest_lbl.modulate = Color(0.85, 0.9, 1.0, 0.95)
	quest_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_lbl.custom_minimum_size = Vector2(440, 0)
	vbox.add_child(quest_lbl)

	var turn_in := load("res://scenes/ui/button.tscn").instantiate() as Button
	turn_in.text = "Turn in %d %s" % [amount, mat]
	turn_in.custom_minimum_size = Vector2(200, 44)
	turn_in.disabled = have < amount
	var free := GameState.get_inventory_capacity() - GameState.trash_inventory
	if reward_amount > 0 and (free + int(GameState.trash_by_type.get(mat, 0)) < reward_amount):
		turn_in.disabled = true
	turn_in.pressed.connect(func():
		if GameState.consume_trash_type(mat, amount):
			if reward_amount > 0:
				var gained := GameState.add_trash_type_weighted(reward_mat, reward_amount)
				var r := load("res://scenes/ui/label.tscn").instantiate() as Label
				if gained >= reward_amount:
					r.text = "Reward: %d %s!" % [reward_amount, reward_mat]
					r.modulate = Color(0.7, 1.0, 0.75, 1)
				else:
					r.text = "Reward: %d/%d %s (inventory cap)" % [gained, reward_amount, reward_mat]
					r.modulate = Color(0.95, 0.7, 0.35, 1.0)
				vbox.add_child(r)
			AudioManager.play_sfx("upgrade", 1.0 + float(tier) * 0.06)
			if tier == 1:
				_quest_done = true
				_mark_quest_done(1)
			else:
				_quest2_done = true
				_mark_quest_done(2)
			_refresh_name_label()
			_refresh_quest_progress()
			_close()
			_show_dialogue()
	)
	vbox.add_child(turn_in)

func _close() -> void:
	if is_instance_valid(_panel):
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

func _refresh_quest_progress_node_label() -> void:
	if not has_node("QuestProgress"):
		return
	var ql: Label = $QuestProgress
	if _quest2_done:
		ql.text = "Quests: complete"
		ql.modulate = Color(1.0, 0.85, 0.3, 0.95)
		return
	var cur_mat: String = ""
	var cur_amt: int = 0
	if (not _quest_done) and quest_material != "" and quest_amount > 0:
		cur_mat = quest_material
		cur_amt = quest_amount
	elif _quest_done and not _quest2_done and quest2_material != "" and quest2_amount > 0:
		cur_mat = quest2_material
		cur_amt = quest2_amount
	if cur_mat == "":
		ql.text = ""
		return
	var cur_have := int(GameState.trash_by_type.get(cur_mat, 0))
	ql.text = "Quest: %d/%d %s" % [min(cur_have, cur_amt), cur_amt, cur_mat]
	if cur_have >= cur_amt:
		ql.modulate = Color(0.6, 1.0, 0.7, 1.0)
	else:
		ql.modulate = Color(0.7, 0.95, 1.0, 0.9)

func _process(delta: float) -> void:
	# throttle refresh to avoid every-frame cost
	var _timer := 0.0
	_timer += delta
	if _timer < 0.4:
		return
	_timer = 0.0
	_refresh_quest_progress()
	_glow_quest_ready()

func _apply_npc_sprite() -> void:
	if has_node("Sprite"):
		_sprite = $Sprite
	var idx := clampi(npc_sprite_index, 1, 4)
	var path := "res://sprites/wm_npc/npc%d.png" % idx
	if ResourceLoader.exists(path):
		if is_instance_valid(_sprite):
			_sprite.texture = load(path)
			_sprite.centered = true
			_sprite.scale = Vector2(0.46, 0.46)
			_sprite.position = Vector2(0, -10)
			var sprite_height: float = _sprite.get_rect().size.y * _sprite.scale.y
			var top: float = _sprite.position.y - sprite_height * 0.5
			if has_node("NameLabel"):
				var name_label: Label = $NameLabel
				name_label.offset_top = top - 28.0
				name_label.offset_bottom = top - 4.0
			if has_node("QuestProgress"):
				var quest_label: Label = $QuestProgress
				quest_label.offset_top = top + 2.0
				quest_label.offset_bottom = top + 26.0
	if has_node("Body"):
		var body: ColorRect = $Body
		body.visible = false

func _glow_quest_ready() -> void:
	if not is_instance_valid(self):
		return
	var ready := false
	if _visited_flag and not _quest_done and quest_material != "" and quest_amount > 0:
		ready = int(GameState.trash_by_type.get(quest_material, 0)) >= quest_amount
	elif _quest_done and not _quest2_done and quest2_material != "" and quest2_amount > 0:
		ready = int(GameState.trash_by_type.get(quest2_material, 0)) >= quest2_amount
	if is_instance_valid(_sprite):
		if ready:
			_sprite.modulate = Color(1.0, 0.95, 0.55, 1.0)
		else:
			_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if has_node("Body") and is_instance_valid($Body):
		var body: ColorRect = $Body
		if ready:
			body.color = Color(1.0, 0.95, 0.55, 1.0)
		else:
			body.color = Color(0.95, 0.72, 0.45, 1.0)
