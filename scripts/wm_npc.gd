extends Area2D
class_name WorldNPC

@export_group("NPC Identity")
@export var npc_id: String = "npc_1"
@export var npc_name: String = "Friendly Cleaner"
@export_range(1, 4) var npc_sprite_index: int = 1

@export_group("Dialogue")
@export_multiline var dialogue_lines: Array[String] = ["Hello! Welcome to trash island."]
@export_multiline var repeat_dialogue_lines: Array[String] = ["Good to see you again!"]
@export_multiline var quest_complete_lines: Array[String] = ["Thanks for the help!"]
@export_multiline var tier2_lines: Array[String] = ["Tier 2 unlocked. Bring more!"]
@export_multiline var flavour_variants: Array[String] = ["The tides are calm today.", "Keep the shores clean!", "Every bit of trash helps."]
@export_multiline var ambient_bubbles: Array[String] = ["*quietly humming*", "Cleanup in progress...", "Another shore, another day."]

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
var _panel: CanvasLayer = null
var _visited_flag: bool = false
var _quest_done: bool = false
var _quest2_done: bool = false
var _visit_count: int = 0

# Nodes
var _quest_progress_label: Label = null
var _sprite: Sprite2D = null
var _ambient_bubble: Label = null

# Timers
var _ambient_timer: float = 0.0
var _ambient_next: float = 4.5
var _refresh_tick: float = 0.0

func _ready() -> void:
	add_to_group("npc")
	body_entered.connect(_on_body_entered)
	
	_load_saved_data()
	_apply_npc_sprite()
	_build_quest_progress()
	_start_idle_animations()
	_update_ui_state()

func _process(delta: float) -> void:
	_ambient_timer += delta
	if _ambient_timer >= _ambient_next:
		_ambient_timer = 0.0
		_ambient_next = randf_range(3.0, 7.5)
		if not _panel:
			_show_ambient_bubble()
			
	_refresh_tick += delta
	if _refresh_tick >= 0.4:
		_refresh_tick = 0.0
		_update_ui_state()

func _unhandled_input(event: InputEvent) -> void:
	if not _panel: return
	
	if event.is_action_pressed("ui_cancel") or \
		(event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]):
		get_viewport().set_input_as_handled()
		_close()

func _on_body_entered(body: Node) -> void:
	if not _panel and body is Node2D and body.is_in_group("player"):
		_show_dialogue()

# --- Initialization & State ---

func _load_saved_data() -> void:
	var data := SaveManager.load_game()
	_visited_flag = data.get("npc_visited", {}).get(npc_id, false)
	_visit_count = data.get("npc_visit_counts", {}).get(npc_id, 0)
	_quest_done = data.get("npc_quests", {}).get(npc_id, false)
	_quest2_done = data.get("npc_quests2", {}).get(npc_id, false)

func _save_flag(dict_key: String, value: Variant) -> void:
	var data := SaveManager.load_game()
	var dict: Dictionary = data.get(dict_key, {})
	dict[npc_id] = value
	data[dict_key] = dict
	SaveManager.save_game(data)

func _bump_visit_count() -> void:
	_visit_count += 1
	_save_flag("npc_visit_counts", _visit_count)

# --- Animations ---

func _start_idle_animations() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if _sprite:
		var sp_tween := create_tween().set_loops()
		sp_tween.tween_property(_sprite, "position:y", _sprite.position.y - 4.0, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sp_tween.tween_property(_sprite, "position:y", _sprite.position.y, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply_npc_sprite() -> void:
	_sprite = get_node_or_null("Sprite")
	var idx := clampi(npc_sprite_index, 1, 4)
	var path := "res://sprites/wm_npc/npc%d.png" % idx
	
	if ResourceLoader.exists(path) and _sprite:
		_sprite.texture = load(path)
		_sprite.centered = true
		_sprite.scale = Vector2(0.46, 0.46)
		_sprite.position = Vector2(0, -10)
		
		var sprite_height: float = _sprite.get_rect().size.y * _sprite.scale.y
		var top: float = _sprite.position.y - sprite_height * 0.5
		
		if has_node("NameLabel"):
			$NameLabel.offset_top = top - 28.0
			$NameLabel.offset_bottom = top - 4.0
		if has_node("QuestProgress"):
			$QuestProgress.offset_top = top + 2.0
			$QuestProgress.offset_bottom = top + 26.0
			
	if has_node("Body"):
		$Body.visible = false

# --- UI Updates ---

func _update_ui_state() -> void:
	_refresh_name_label()
	_refresh_quest_progress()
	_glow_quest_ready()

func _build_quest_progress() -> void:
	if _quest_progress_label: return
	
	_quest_progress_label = get_node_or_null("QuestProgress")
	if not _quest_progress_label:
		_quest_progress_label = load("res://scenes/ui/label.tscn").instantiate() as Label
		_quest_progress_label.name = "QuestProgress"
		_quest_progress_label.offset_left = -70
		_quest_progress_label.offset_top = -78
		_quest_progress_label.offset_right = 70
		_quest_progress_label.offset_bottom = -56
		_quest_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_quest_progress_label.add_theme_font_size_override("font_size", 11)
		_quest_progress_label.z_index = 20
		add_child(_quest_progress_label)
		
	_refresh_quest_progress()

func _refresh_quest_progress() -> void:
	if not _quest_progress_label: return
	
	if _quest2_done:
		_quest_progress_label.text = "Quests: complete"
		_quest_progress_label.modulate = Color(1.0, 0.85, 0.3, 0.95)
		return
		
	var active_mat := ""
	var active_amt := 0
	
	if _visited_flag and not _quest_done and quest_amount > 0:
		active_mat = quest_material
		active_amt = quest_amount
	elif _quest_done and not _quest2_done and quest2_amount > 0:
		active_mat = quest2_material
		active_amt = quest2_amount
		
	if active_mat.is_empty():
		_quest_progress_label.text = ""
		return
		
	var have := int(GameState.trash_by_type.get(active_mat, 0))
	_quest_progress_label.text = "Quest: %d/%d %s" % [min(have, active_amt), active_amt, active_mat]
	_quest_progress_label.modulate = Color(0.6, 1.0, 0.7, 1.0) if have >= active_amt else Color(0.7, 0.95, 1.0, 0.9)

func _refresh_name_label() -> void:
	var nl: Label = get_node_or_null("NameLabel")
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
	var ready := false
	if _visited_flag and not _quest_done and quest_amount > 0:
		ready = int(GameState.trash_by_type.get(quest_material, 0)) >= quest_amount
	elif _quest_done and not _quest2_done and quest2_amount > 0:
		ready = int(GameState.trash_by_type.get(quest2_material, 0)) >= quest2_amount
		
	if _sprite:
		_sprite.modulate = Color(1.0, 0.95, 0.55, 1.0) if ready else Color(1.0, 1.0, 1.0, 1.0)
		
	if has_node("Body") and $Body:
		$Body.color = Color(1.0, 0.95, 0.55, 1.0) if ready else Color(0.95, 0.72, 0.45, 1.0)

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
	return out

func _show_dialogue() -> void:
	var first_visit := not _visited_flag
	_bump_visit_count()
	
	_panel = load("res://scenes/ui/canvas_layer.tscn").instantiate() as CanvasLayer
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.layer = 200
	get_tree().current_scene.add_child(_panel)

	# Setup background dimming
	var dim := load("res://scenes/ui/color_rect.tscn").instantiate() as ColorRect
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(dim)

	# Container structure
	var container := load("res://scenes/ui/center_container.tscn").instantiate() as CenterContainer
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(container)

	var box := load("res://scenes/ui/panel_container.tscn").instantiate() as PanelContainer
	box.custom_minimum_size = Vector2(480, 0)
	container.add_child(box)

	var vbox := load("res://scenes/ui/vbox_container.tscn").instantiate() as VBoxContainer
	vbox.add_theme_constant_override("separation", 10)
	box.add_child(vbox)

	# Text Elements
	var title := load("res://scenes/ui/label.tscn").instantiate() as Label
	title.text = npc_name
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var line_labels: Array = []
	for line in _prepare_lines():
		var lbl := load("res://scenes/ui/label.tscn").instantiate() as Label
		lbl.text = str(line)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(440, 0)
		vbox.add_child(lbl)
		line_labels.append(lbl)

	# Animate Text
	for lbl in line_labels: 
		lbl.visible_characters = 0
	
	var tw := create_tween()
	for lbl in line_labels:
		var n: int = lbl.text.length()
		tw.tween_method(func(v): 
			if lbl:
				lbl.visible_characters = v, 0, n, clamp(float(n) * 0.018, 0.18, 1.3
			))
		tw.tween_interval(0.15)

	# Quests and Rewards
	if first_visit and reward_trash > 0:
		var reward_lbl := load("res://scenes/ui/label.tscn").instantiate() as Label
		reward_lbl.text = "You received %d %s!" % [reward_trash, reward_mat]
		reward_lbl.modulate = Color(0.7, 1.0, 0.75, 1)
		vbox.add_child(reward_lbl)
		GameState.add_trash_type_weighted(reward_mat, reward_trash)
		AudioManager.play_sfx("pickup")
		_spawn_reward_sparks()
		_save_flag("npc_visited", true)
		_visited_flag = true

	if not first_visit:
		if not _quest_done and quest_amount > 0:
			_add_quest_ui(vbox, 1, quest_material, quest_amount, quest_reward_mat, quest_reward_amount)
		elif _quest_done and not _quest2_done and quest2_amount > 0:
			_add_quest_ui(vbox, 2, quest2_material, quest2_amount, quest2_reward_mat, quest2_reward_amount)

	# OK Button
	var ok := load("res://scenes/ui/button.tscn").instantiate() as Button
	ok.text = "OK"
	ok.custom_minimum_size = Vector2(120, 44)
	ok.pressed.connect(_close)
	var shortcut := Shortcut.new()
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	shortcut.events = [event]
	ok.shortcut = shortcut
	vbox.add_child(ok)

func _add_quest_ui(vbox: VBoxContainer, tier: int, mat: String, amount: int, rw_mat: String, rw_amt: int) -> void:
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
	
	var inventory_space_available = GameState.get_inventory_capacity() - GameState.trash_inventory + int(GameState.trash_by_type.get(mat, 0))
	turn_in.disabled = have < amount or (rw_amt > 0 and inventory_space_available < rw_amt)
	
	turn_in.pressed.connect(func():
		if GameState.consume_trash_type(mat, amount):
			if rw_amt > 0:
				var gained := GameState.add_trash_type_weighted(rw_mat, rw_amt)
				var r := load("res://scenes/ui/label.tscn").instantiate() as Label
				r.text = "Reward: %d %s!" % [rw_amt, rw_mat] if gained >= rw_amt else "Reward: %d/%d %s (cap reached)" % [gained, rw_amt, rw_mat]
				r.modulate = Color(0.7, 1.0, 0.75, 1) if gained >= rw_amt else Color(0.95, 0.7, 0.35, 1.0)
				vbox.add_child(r)
				
			AudioManager.play_sfx("upgrade", 1.0 + float(tier) * 0.06)
			
			if tier == 1:
				_quest_done = true
				_save_flag("npc_quests", true)
			else:
				_quest2_done = true
				_save_flag("npc_quests2", true)
				
			_update_ui_state()
			_close()
			_show_dialogue()
	)
	vbox.add_child(turn_in)

func _close() -> void:
	if _panel:
		_panel.queue_free()
		_panel = null
	_refresh_name_label()

# --- FX & Ambient ---

func _show_ambient_bubble() -> void:
	if ambient_bubbles.is_empty(): return
	
	if not _ambient_bubble:
		_ambient_bubble = load("res://scenes/ui/label.tscn").instantiate() as Label
		_ambient_bubble.add_theme_font_size_override("font_size", 11)
		_ambient_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_ambient_bubble.custom_minimum_size = Vector2(180, 0)
		_ambient_bubble.z_index = 25
		_ambient_bubble.position = Vector2(-90, -95)
		add_child(_ambient_bubble)
		
	_ambient_bubble.text = str(ambient_bubbles.pick_random())
	_ambient_bubble.modulate = Color(1.0, 1.0, 0.9, 0.0)
	
	var tw := create_tween()
	tw.tween_property(_ambient_bubble, "modulate:a", 0.85, 0.14)
	tw.tween_interval(1.6)
	tw.tween_property(_ambient_bubble, "modulate:a", 0.0, 0.4)

func _personality_banter() -> Array:
	match npc_id:
		"npc_mara": return ["The garden looks greener when you recycle.", "I swept the beach twice this morning!", "Ever notice glass sparkles in the tide?"]
		"npc_tom": return ["The sea is calm — perfect diving weather.", "Don't let the fish stare you down!", "Nylon and coffee keep me going."]
		"npc_nina": return ["Shop's freshly stocked today!", "Bulk sales mean bonus days.", "I love the clink of glass rewards."]
		"npc_kai": return ["Shelves empty; bring me Glass!", "A clean shop is a happy shop.", "Polypropylene pays the rent around here."]
		_: return []

func _spawn_reward_sparks() -> void:
	var p := load("res://scenes/ui/c_p_u_particles2_d.tscn").instantiate() as CPUParticles2D
	if not p: return
	
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 18
	p.lifetime = 0.6
	p.global_position = global_position + Vector2(0, -20)
	p.spread = 360.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 60.0
	p.gravity = Vector2(0, 40)
	get_tree().current_scene.add_child(p)
