extends CanvasLayer
# World map pause/menu overlay.

@onready var panel: Control = $MenuPanel
@onready var resume_button: Button = $MenuPanel/HBoxContainer/VBoxContainer/ResumeButton
@onready var save_button: Button = $MenuPanel/HBoxContainer/VBoxContainer/SaveButton
@onready var cap_status: Label = $MenuPanel/HBoxContainer/VBoxContainer/CapStatus

@onready var upgrades_panel: PanelContainer = $MenuPanel/HBoxContainer/Infobox/UpgradesPanel
@onready var upgrade_panel: VBoxContainer = $MenuPanel/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel
@onready var upgrade_status: Label = $MenuPanel/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel/UpgradeStatus
@onready var move_faster_btn: Button = $MenuPanel/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel/MoveFasterBtn
@onready var collection_range_btn: Button = $MenuPanel/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel/CollectionRangeBtn
@onready var deep_cache_btn: Button = $MenuPanel/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel/DeepCacheBtn
@onready var deep_cache_upgrade_btn: Button = $MenuPanel/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel/DeepCacheUpgradeBtn
@onready var inventory_cap_btn: Button = $MenuPanel/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel/InventoryCapBtn

@onready var upcycle_progress_box: HBoxContainer = $MenuPanel/HBoxContainer/Infobox/ProgressBox
@onready var upcycle_label: Label = $MenuPanel/HBoxContainer/Infobox/ProgressBox/UpcycleLbl
@onready var upcycle_progress: ProgressBar = $MenuPanel/HBoxContainer/Infobox/ProgressBox/UpcycleProgress

@onready var reef_progress_box: HBoxContainer = $MenuPanel/HBoxContainer/Infobox/ReefProgressBox
@onready var reef_label: Label = $MenuPanel/HBoxContainer/Infobox/ReefProgressBox/ReefLbl
@onready var reef_progress: ProgressBar = $MenuPanel/HBoxContainer/Infobox/ReefProgressBox/ReefProgress

@onready var settings_button: Button = $MenuPanel/HBoxContainer/Infobox/SettingsButton
@onready var settings_panel: VBoxContainer = $MenuPanel/HBoxContainer/Infobox/SettingsPanel
@onready var master_slider: HSlider = $MenuPanel/HBoxContainer/Infobox/SettingsPanel/MasterSlider
@onready var music_slider: HSlider = $MenuPanel/HBoxContainer/Infobox/SettingsPanel/MusicSlider
@onready var sfx_slider: HSlider = $MenuPanel/HBoxContainer/Infobox/SettingsPanel/SfxSlider
@onready var master_label: Label = $MenuPanel/HBoxContainer/Infobox/SettingsPanel/MasterLabel
@onready var music_label: Label = $MenuPanel/HBoxContainer/Infobox/SettingsPanel/MusicLabel

var _toggling := false
var _bgm_cycle_timer: Timer = null
var _bgm_cycle_index := 0
var _bgm_cycle_tracks: Array[String] = ["world", "ambience", "world", "reef"]
var _hud_queue: Node = null

func _ready() -> void:
	if panel:
		panel.visible = false

	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_player_position()
	_wire_signals()
	_setup_settings_ui()
	_update_progress_bars()
	_add_hud_menu_button()

	get_viewport().size_changed.connect(_clamp_menu_width)
	_clamp_menu_width()
	
	AudioManager.play_bgm("world")
	_setup_bgm_cycle()

func _process(_delta: float) -> void:
	if panel and panel.visible:
		_update_progress_bars()

func _load_player_position() -> void:
	var saved := SaveManager.load_game()
	if saved.has("player_position"):
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = _parse_position(saved["player_position"])

func _wire_signals() -> void:
	if resume_button: resume_button.pressed.connect(_on_resume_pressed)
	if save_button: save_button.pressed.connect(_on_save_pressed)
	if move_faster_btn: move_faster_btn.pressed.connect(_buy_move)
	if collection_range_btn: collection_range_btn.pressed.connect(_buy_range)
	if deep_cache_btn: deep_cache_btn.pressed.connect(_buy_deep_cache)
	if deep_cache_upgrade_btn: deep_cache_upgrade_btn.pressed.connect(_buy_deep_cache_upgrade)
	if inventory_cap_btn: inventory_cap_btn.pressed.connect(_buy_inv_cap)
	if settings_button: settings_button.pressed.connect(_toggle_settings)

func _setup_settings_ui() -> void:
	_refresh_upgrade_ui()

	if master_slider:
		master_slider.value = AudioManager.get_master_volume() * 100.0
		_update_master_label(master_slider.value)
		master_slider.value_changed.connect(func(v: float):
			AudioManager.set_master_volume(v / 100.0)
			_update_master_label(v)
		)
	if music_slider:
		music_slider.value = AudioManager.get_music_volume() * 100.0
		_update_music_label(music_slider.value)
		music_slider.value_changed.connect(func(v: float):
			AudioManager.set_music_volume(v / 100.0)
			_update_music_label(v)
		)
	if sfx_slider:
		sfx_slider.value = AudioManager.get_sfx_volume() * 100.0
		sfx_slider.value_changed.connect(func(v: float): AudioManager.set_sfx_volume(v / 100.0))

func _update_master_label(val: float) -> void:
	if master_label: master_label.text = "Master: %d%%" % int(val)

func _update_music_label(val: float) -> void:
	if music_label: music_label.text = "Music: %d%%" % int(val)

func _format_inventory() -> String:
	var lines: PackedStringArray = []
	for key in GameState.trash_by_type.keys():
		var qty: int = GameState.trash_by_type.get(key, 0)
		if qty > 0:
			lines.append("  %s x%d" % [str(key), qty])
	
	return "Inventory: empty" if lines.is_empty() else "Inventory:\n" + "\n".join(lines)

func _on_resume_pressed() -> void:
	_toggle()

func _toggle() -> void:
	if _toggling: return
	_toggling = true
	
	if panel:
		panel.visible = not panel.visible
		get_tree().paused = panel.visible
		
		# hide world progress while paused
		var prog := get_node_or_null("../WorldProgress")
		if prog: prog.visible = not panel.visible
		
		if panel.visible:
			_refresh_upgrade_ui()
			_clamp_menu_width()
			if resume_button:
				resume_button.grab_focus()
				
			panel.modulate.a = 0.0
			var fade_tw := create_tween()
			fade_tw.tween_property(panel, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
	_toggling = false

func _toggle_settings() -> void:
	if settings_panel:
		settings_panel.visible = not settings_panel.visible
	if settings_button:
		settings_button.text = "Settings ▲" if settings_panel.visible else "Settings ▼"
	_clamp_menu_width()

func _clamp_menu_width() -> void:
	if not panel: return
	
	var vp := get_viewport().get_visible_rect().size
	var vw: float = maxf(vp.x, 1.0)
	var vh: float = maxf(vp.y, 1.0)
	
	# Restrain total horizontal width with safe screen padding
	var target_w: float = clampf(vw - 32.0, 260.0, 520.0)
	var max_h: float = clampf(vh - 32.0, 200.0, vh - 24.0)

	# Keep panel centered using Godot Anchors instead of manual offset calculation
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var hbox := panel.get_node_or_null("HBoxContainer") as Control
	if hbox:
		hbox.custom_minimum_size.x = target_w
		hbox.custom_minimum_size.y = minf(hbox.get_combined_minimum_size().y, max_h)

	var vbox := panel.get_node_or_null("VBoxContainer") as Control
	if vbox:
		vbox.custom_minimum_size.x = target_w

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
		_toggle()
		get_viewport().set_input_as_handled()

func _add_hud_menu_button() -> void:
	var btn := Button.new()
	btn.text = "☰"
	btn.name = "HUDMenuButton"
	btn.custom_minimum_size = Vector2(56, 48)
	btn.anchor_left = 1.0; btn.anchor_right = 1.0
	btn.anchor_top = 0.0; btn.anchor_bottom = 0.0
	btn.offset_left = -72.0
	btn.offset_top = 12.0
	btn.offset_right = -12.0
	btn.offset_bottom = 60.0
	btn.pressed.connect(_toggle)
	add_child(btn)

	if panel: panel.visible = false
	get_tree().paused = false

func _on_save_pressed() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var position_value: Array = [player.global_position.x, player.global_position.y] if player else []
	
	var data := SaveManager.load_game()
	data["player_position"] = position_value
	SaveManager.save_game(data)
	
	if panel: panel.visible = false
	get_tree().paused = false
	SceneTransition.change_scene("res://scenes/main_menu.tscn")

func _parse_position(value: Variant) -> Vector2:
	if value is Array and value.size() == 2:
		return Vector2(value[0], value[1])
	if value is String:
		var cleaned: String = value.strip_edges().trim_prefix("(").trim_suffix(")")
		var parts := cleaned.split(",")
		if parts.size() == 2:
			return Vector2(parts[0].to_float(), parts[1].to_float())
	return Vector2.ZERO

# --- Upgrades & Costs ---

func _move_cost() -> int:
	return 8 + int(SaveManager.load_game().get("upgrade_move", 0)) * 4

func _range_cost() -> int:
	return 12 + int(SaveManager.load_game().get("upgrade_range", 0)) * 6

func _move_cost_text() -> String:
	var lvl := int(SaveManager.load_game().get("upgrade_move", 0))
	return "Move Speed Lv.%d (+8%%) — %d trash" % [lvl, _move_cost()]

func _range_cost_text() -> String:
	var lvl := int(SaveManager.load_game().get("upgrade_range", 0))
	return "Range Lv.%d (+12px) — %d trash" % [lvl, _range_cost()]

func _deep_cache_text() -> String:
	if GameState.deep_cache:
		return "Deep Cache: OWNED (Tier %d)" % GameState.deep_cache_tier
	return "Deep Cache (30 score) — bonus debris"

func _upgrade_status_text() -> String:
	var data := SaveManager.load_game()
	var mv := int(data.get("upgrade_move", 0))
	var rng := int(data.get("upgrade_range", 0))
	var dc := "DeepCache" if bool(data.get("deep_cache", false)) else "-"
	return "Upgrades: Move %d | Range %d | %s" % [mv, rng, dc]

func _deep_cache_upgrade_text() -> String:
	return "Deep Cache Tier %d — %d score" % [GameState.deep_cache_tier + 1, 15 * GameState.deep_cache_tier]

func _inv_cap_text() -> String:
	var cost := 6 + GameState.inventory_capacity_level * 3
	return "Inv Cap Lv.%d (%d/%d kg) — %d trash" % [GameState.inventory_capacity_level, GameState.trash_inventory, GameState.get_inventory_capacity(), cost]

# --- Purchasing ---

func _process_upgrade(btn: Button, success: bool, failure_msg: String, upgrade_action: Callable = Callable()) -> void:
	if not success:
		_flash(btn)
		_toast(failure_msg)
		return
		
	if upgrade_action.is_valid():
		upgrade_action.call()
		
	AudioManager.play_sfx("upgrade", 1.05)
	_flash_success(btn)
	_spawn_upgrade_sparkle(btn)
	_refresh_upgrade_ui()

func _buy_move() -> void:
	_process_upgrade(move_faster_btn, GameState.spend_trash(_move_cost()), "Need more trash to upgrade Move Speed", func():
		var data := SaveManager.load_game()
		data["upgrade_move"] = int(data.get("upgrade_move", 0)) + 1
		SaveManager.save_game(data)
		GameState.restore()
	)

func _buy_range() -> void:
	_process_upgrade(collection_range_btn, GameState.spend_trash(_range_cost()), "Need more trash to upgrade Collection Range", func():
		var data := SaveManager.load_game()
		data["upgrade_range"] = int(data.get("upgrade_range", 0)) + 1
		SaveManager.save_game(data)
		GameState.restore()
	)

func _buy_deep_cache() -> void:
	if GameState.deep_cache:
		_flash_success(deep_cache_btn)
		return
	_process_upgrade(deep_cache_btn, GameState.purchase_deep_cache(), "Need 30 upcycle score to buy Deep Cache")

func _buy_deep_cache_upgrade() -> void:
	if not GameState.deep_cache:
		_flash(deep_cache_upgrade_btn)
		return
	_process_upgrade(deep_cache_upgrade_btn, GameState.upgrade_deep_cache(), "Need %d upcycle score to upgrade Deep Cache" % (15 * GameState.deep_cache_tier))

func _buy_inv_cap() -> void:
	var cost := 6 + GameState.inventory_capacity_level * 3
	_process_upgrade(inventory_cap_btn, GameState.purchase_inventory_capacity(), "Need %d trash to increase Inventory Cap" % cost)

func _refresh_upgrade_ui() -> void:
	if upgrade_status: upgrade_status.text = _upgrade_status_text()
	
	if deep_cache_btn:
		deep_cache_btn.text = _deep_cache_text()
		deep_cache_btn.disabled = GameState.deep_cache
		
	if deep_cache_upgrade_btn:
		deep_cache_upgrade_btn.text = _deep_cache_upgrade_text()
		deep_cache_upgrade_btn.disabled = not GameState.deep_cache
		
	if inventory_cap_btn:
		inventory_cap_btn.disabled = GameState.trash_inventory < (6 + GameState.inventory_capacity_level * 3)
		inventory_cap_btn.text = _inv_cap_text()
		
	if move_faster_btn:
		move_faster_btn.disabled = GameState.trash_inventory < _move_cost()
		move_faster_btn.text = _move_cost_text()
		
	if collection_range_btn:
		collection_range_btn.disabled = GameState.trash_inventory < _range_cost()
		collection_range_btn.text = _range_cost_text()

# --- UI Feedback & Effects ---

func _ensure_hud_queue() -> void:
	if not _hud_queue:
		_hud_queue = load("res://scripts/ui/notification_queue.gd").new()
		add_child(_hud_queue)

func _toast(text: String) -> void:
	_ensure_hud_queue()
	_hud_queue.push(text, Color(1.0, 0.85, 0.35, 1.0), 1.4)

func _flash(btn: Button) -> void:
	if not btn: return
	var tw := btn.create_tween()
	btn.modulate = Color(1.0, 0.4, 0.4, 1.0)
	tw.tween_property(btn, "modulate", Color.WHITE, 0.5)

func _flash_success(btn: Button) -> void:
	if not btn: return
	var tw := btn.create_tween()
	btn.modulate = Color(0.5, 1.0, 0.55, 1.0)
	tw.tween_property(btn, "modulate", Color.WHITE, 0.6)

func _spawn_upgrade_sparkle(anchor: Control) -> void:
	if not anchor: return
	
	var p := load("res://scenes/ui/c_p_u_particles2_d.tscn").instantiate() as CPUParticles2D
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 24
	p.lifetime = 0.5
	p.spread = 360.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.gravity = Vector2(0.0, 160.0)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(0.6, 1.0, 0.8, 1.0)
	
	var r := anchor.get_global_rect()
	p.global_position = r.position + r.size * 0.5
	add_child(p)
	p.emitting = true
	
	var tw := create_tween()
	tw.tween_interval(p.lifetime + 0.1)
	tw.tween_callback(p.queue_free)

func _update_progress_bars() -> void:
	if upcycle_progress:
		upcycle_progress.max_value = maxf(1.0, float(maxi(1, GameState.best_upcycle_score)))
		upcycle_progress.value = minf(upcycle_progress.max_value, float(GameState.upcycle_score))
		
	if reef_progress:
		reef_progress.max_value = maxf(1.0, float(maxi(10, GameState.best_reef_depth)))
		reef_progress.value = minf(reef_progress.max_value, float(GameState.reef_garbage))
		
	_update_cap_status()

func _update_cap_status() -> void:
	if not cap_status: return
	
	var cap: int = maxi(1, GameState.get_inventory_capacity())
	var ratio := float(GameState.trash_inventory) / float(cap)
	
	if ratio >= 1.0:
		cap_status.text = "Inventory FULL (%d/%d) — upgrade or sell" % [GameState.trash_inventory, cap]
		cap_status.modulate = Color(1.0, 0.35, 0.35, 1.0)
	elif ratio >= 0.85:
		cap_status.text = "Inventory heavy (%d/%d)" % [GameState.trash_inventory, cap]
		cap_status.modulate = Color(1.0, 0.85, 0.35, 1.0)
	else:
		cap_status.text = ""

# --- BGM Management ---

func _setup_bgm_cycle() -> void:
	if _bgm_cycle_timer: return
	
	_bgm_cycle_timer = Timer.new()
	_bgm_cycle_timer.wait_time = 18.0
	_bgm_cycle_timer.one_shot = false
	add_child(_bgm_cycle_timer)
	
	_bgm_cycle_timer.timeout.connect(_tick_bgm_cycle)
	_bgm_cycle_timer.start()

func _tick_bgm_cycle() -> void:
	_bgm_cycle_index = (_bgm_cycle_index + 1) % _bgm_cycle_tracks.size()
	AudioManager.play_bgm(_bgm_cycle_tracks[_bgm_cycle_index])
