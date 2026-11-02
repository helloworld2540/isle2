extends CanvasLayer
# World map pause/menu overlay.

@onready var panel: Control = get_node_or_null("MenuPanel")
@onready var resume_button: Button = get_node_or_null("MenuPanel/VBoxContainer/ResumeButton")
@onready var save_button: Button = get_node_or_null("MenuPanel/VBoxContainer/SaveButton")
@onready var summary_label: Label = get_node_or_null("MenuPanel/VBoxContainer/SummaryLabel")
@onready var inventory_list: Label = get_node_or_null("MenuPanel/VBoxContainer/InventoryList")
@onready var cap_status: Label = get_node_or_null("MenuPanel/VBoxContainer/CapStatus")

var _toggling := false

var _upgrade_panel: VBoxContainer = null
var _upgrade_status: Label = null
var _upgrade_fast_btn: Button = null
var _upgrade_range_btn: Button = null
var _deep_cache_btn: Button = null
var _deep_cache_upgrade_btn: Button = null
var _inv_cap_btn: Button = null
var _up_bar: ProgressBar = null
var _reef_bar: ProgressBar = null
var _settings_button: Button = null
var _settings_panel: VBoxContainer = null
var _master_slider: HSlider = null
var _music_slider: HSlider = null
var _reduce_checkbox: CheckBox = null

@onready var upgrades_panel: PanelContainer = get_node_or_null("MenuPanel/VBoxContainer/UpgradesPanel")
@onready var upgrade_panel: VBoxContainer = get_node_or_null("MenuPanel/VBoxContainer/UpgradesPanel/UpgradePanel")
@onready var upgrade_status: Label = get_node_or_null("MenuPanel/VBoxContainer/UpgradesPanel/UpgradePanel/UpgradeStatus")
@onready var move_faster_btn: Button = get_node_or_null("MenuPanel/VBoxContainer/UpgradesPanel/UpgradePanel/MoveFasterBtn")
@onready var collection_range_btn: Button = get_node_or_null("MenuPanel/VBoxContainer/UpgradesPanel/UpgradePanel/CollectionRangeBtn")
@onready var deep_cache_btn: Button = get_node_or_null("MenuPanel/VBoxContainer/UpgradesPanel/UpgradePanel/DeepCacheBtn")
@onready var deep_cache_upgrade_btn: Button = get_node_or_null("MenuPanel/VBoxContainer/UpgradesPanel/UpgradePanel/DeepCacheUpgradeBtn")
@onready var inventory_cap_btn: Button = get_node_or_null("MenuPanel/VBoxContainer/UpgradesPanel/UpgradePanel/InventoryCapBtn")

@onready var upcycle_progress_box: HBoxContainer = get_node_or_null("MenuPanel/VBoxContainer/ProgressBox")
@onready var upcycle_label: Label = get_node_or_null("MenuPanel/VBoxContainer/ProgressBox/UpcycleLbl")
@onready var upcycle_progress: ProgressBar = get_node_or_null("MenuPanel/VBoxContainer/ProgressBox/UpcycleProgress")
@onready var reef_progress_box: HBoxContainer = get_node_or_null("MenuPanel/VBoxContainer/ReefProgressBox")
@onready var reef_label: Label = get_node_or_null("MenuPanel/VBoxContainer/ReefProgressBox/ReefLbl")
@onready var reef_progress: ProgressBar = get_node_or_null("MenuPanel/VBoxContainer/ReefProgressBox/ReefProgress")

@onready var settings_button: Button = get_node_or_null("MenuPanel/VBoxContainer/SettingsButton")
@onready var settings_panel: VBoxContainer = get_node_or_null("MenuPanel/VBoxContainer/SettingsPanel")
@onready var master_slider: HSlider = get_node_or_null("MenuPanel/VBoxContainer/SettingsPanel/MasterSlider")
@onready var music_slider: HSlider = get_node_or_null("MenuPanel/VBoxContainer/SettingsPanel/MusicSlider")
@onready var reduce_motion_cb: CheckBox = get_node_or_null("MenuPanel/VBoxContainer/SettingsPanel/ReduceMotionCb")
@onready var master_label: Label = get_node_or_null("MenuPanel/VBoxContainer/SettingsPanel/MasterLabel")
@onready var music_label: Label = get_node_or_null("MenuPanel/VBoxContainer/SettingsPanel/MusicLabel")

var _bgm_cycle_timer: Timer = null
var _bgm_cycle_index := 0
var _bgm_cycle_tracks := ["world", "ambience", "world", "reef"]

var _upgrade_status_text_cache := ""

func _ready() -> void:
	if is_instance_valid(panel):
		panel.visible = false

	var saved := SaveManager.load_game()
	if saved.has("player_position"):
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = _parse_position(saved["player_position"])

	_wire_signals()
	_build_settings_ui_static()
	_build_progress_bars_static()

	if is_instance_valid(resume_button):
		resume_button.pressed.connect(_on_resume_pressed)
	if is_instance_valid(save_button):
		save_button.pressed.connect(_on_save_pressed)

	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(_clamp_menu_width)
	_clamp_menu_width()
	AudioManager.play_bgm("world")
	_setup_bgm_cycle()

func _wire_signals() -> void:
	if is_instance_valid(move_faster_btn):
		move_faster_btn.pressed.connect(_buy_move)
	if is_instance_valid(collection_range_btn):
		collection_range_btn.pressed.connect(_buy_range)
	if is_instance_valid(deep_cache_btn):
		deep_cache_btn.pressed.connect(_buy_deep_cache)
	if is_instance_valid(deep_cache_upgrade_btn):
		deep_cache_upgrade_btn.pressed.connect(_buy_deep_cache_upgrade)
	if is_instance_valid(inventory_cap_btn):
		inventory_cap_btn.pressed.connect(_buy_inv_cap)
	if is_instance_valid(settings_button):
		settings_button.pressed.connect(_toggle_settings)

func _build_settings_ui_static() -> void:
	_upgrade_panel = upgrade_panel
	_upgrade_status = upgrade_status
	_upgrade_fast_btn = move_faster_btn
	_upgrade_range_btn = collection_range_btn
	_deep_cache_btn = deep_cache_btn
	_deep_cache_upgrade_btn = deep_cache_upgrade_btn
	_inv_cap_btn = inventory_cap_btn
	_up_bar = upcycle_progress
	_reef_bar = reef_progress
	_settings_button = settings_button
	_settings_panel = settings_panel
	_master_slider = master_slider
	_music_slider = music_slider
	_reduce_checkbox = reduce_motion_cb

	_refresh_upgrade_ui()

	if is_instance_valid(_master_slider):
		_master_slider.value = AudioManager.get_master_volume() * 100.0
		_master_slider.value_changed.connect(func(v): AudioManager.set_master_volume(v / 100.0))
	if is_instance_valid(_music_slider):
		_music_slider.value = AudioManager.get_music_volume() * 100.0
		_music_slider.value_changed.connect(func(v): AudioManager.set_music_volume(v / 100.0))
	if is_instance_valid(_reduce_checkbox):
		_reduce_checkbox.button_pressed = AudioManager.get_reduced_motion()
		_reduce_checkbox.toggled.connect(func(v): AudioManager.set_reduced_motion(v))

func _build_progress_bars_static() -> void:
	if is_instance_valid(_up_bar):
		_up_bar.max_value = max(1.0, float(max(1, GameState.best_upcycle_score)))
		_up_bar.value = min(_up_bar.max_value, float(GameState.upcycle_score))
	if is_instance_valid(_reef_bar):
		_reef_bar.max_value = max(1.0, float(max(10, GameState.best_reef_depth)))
		_reef_bar.value = min(_reef_bar.max_value, GameState.reef_garbage)

func _process(_delta: float) -> void:
	if is_instance_valid(panel) and panel.visible and is_instance_valid(summary_label):
		summary_label.text = "Trash: %d kg | Upcycle Score: %d | Best Streak: %d" % [GameState.trash_inventory, GameState.upcycle_score, GameState.best_sort_streak]
		if is_instance_valid(inventory_list):
			inventory_list.text = _format_inventory()
		_update_progress_bars()
		_update_cap_status()

func _format_inventory() -> String:
	var lines := []
	for key in GameState.trash_by_type.keys():
		var qty := int(GameState.trash_by_type.get(key, 0))
		if qty > 0:
			lines.append("  %s x%d" % [str(key), qty])
	if lines.is_empty():
		return "Inventory: empty"
	return "Inventory:\n" + "\n".join(lines)

func _toggle() -> void:
	if _toggling:
		return
	_toggling = true
	if is_instance_valid(panel):
		panel.visible = not panel.visible
		get_tree().paused = panel.visible
		if panel.visible:
			_refresh_upgrade_ui()
			if is_instance_valid(resume_button):
				resume_button.grab_focus()
			if not AudioManager.get_reduced_motion():
				var fade_tw := create_tween()
				panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
				fade_tw.tween_property(panel, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			else:
				panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_toggling = false

func _toggle_settings() -> void:
	if is_instance_valid(_settings_panel):
		_settings_panel.visible = not _settings_panel.visible
	if is_instance_valid(_settings_button):
		_settings_button.text = "Settings ▲" if _settings_panel.visible else "Settings ▼"

func _clamp_menu_width() -> void:
	var vp := get_viewport().get_visible_rect().size
	var vw: float = vp.x
	var vh: float = vp.y
	if vw < 1.0 or vh < 1.0:
		vw = maxf(1.0, float(DisplayServer.window_get_size().x))
		vh = maxf(1.0, float(DisplayServer.window_get_size().y))
	var w: float = clampf(min(440.0, vw - 32.0), 200.0, 440.0)
	if is_instance_valid(panel):
		var vbox := panel.get_node_or_null("VBoxContainer")
		if vbox:
			vbox.custom_minimum_size.x = w
			vbox.custom_maximum_size.x = w
			var menu_h: float = 420.0
			var y_off: float = clampf((vh - menu_h) * 0.5, 12.0, 120.0)
			vbox.offset_top = - (menu_h * 0.5) + y_off
			vbox.offset_bottom = (menu_h * 0.5) + y_off

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
		_toggle()
		get_viewport().set_input_as_handled()

func _on_resume_pressed() -> void:
	if is_instance_valid(panel):
		panel.visible = false
	get_tree().paused = false
	if is_instance_valid(summary_label):
		summary_label.text = "Trash in inventory: %d" % GameState.trash_inventory

func _on_save_pressed() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var position_value: Array = []
	if player:
		position_value = [player.global_position.x, player.global_position.y]
	var data := SaveManager.load_game()
	data["player_position"] = position_value
	SaveManager.save_game(data)
	if is_instance_valid(panel):
		panel.visible = false
	get_tree().paused = false
	SceneTransition.change_scene("res://scenes/main_menu.tscn")

func _parse_position(value) -> Vector2:
	if value is Array and value.size() == 2:
		return Vector2(value[0], value[1])
	if value is String:
		var cleaned := (value as String).strip_edges().trim_prefix("(").trim_suffix(")")
		var parts := cleaned.split(",")
		if parts.size() == 2:
			return Vector2(parts[0].to_float(), parts[1].to_float())
	return Vector2.ZERO

func _move_cost_text() -> String:
	var lvl := int(SaveManager.load_game().get("upgrade_move", 0))
	var cost := 8 + lvl * 4
	return "Move Faster: Lv.%d (+8%% speed) — %d trash" % [lvl, cost]

func _range_cost_text() -> String:
	var lvl := int(SaveManager.load_game().get("upgrade_range", 0))
	var cost := 12 + lvl * 6
	return "Collection Range: Lv.%d (+12 px) — %d trash" % [lvl, cost]

func _deep_cache_text() -> String:
	if GameState.deep_cache:
		return "Deep Cache: OWNED (tier %d)" % GameState.deep_cache_tier
	return "Deep Cache (30 upcycle score) — bonus debris per run"

func _upgrade_status_text() -> String:
	var data := SaveManager.load_game()
	var mv := int(data.get("upgrade_move", 0))
	var rng := int(data.get("upgrade_range", 0))
	var dc := "DeepCache" if bool(data.get("deep_cache", false)) else "-"
	return "Upgrades -> Move: %d, Range: %d, %s" % [mv, rng, dc]

func _deep_cache_upgrade_text() -> String:
	return "Upgrade Deep Cache -> tier %d (+debris) — %d upcycle score" % [GameState.deep_cache_tier + 1, 15 * (GameState.deep_cache_tier)]

func _inv_cap_text() -> String:
	return "Inventory Cap: Lv.%d — %d/%d kg (cost %d trash)" % [GameState.inventory_capacity_level, GameState.trash_inventory, GameState.get_inventory_capacity(), 6 + GameState.inventory_capacity_level * 3]

func _buy_move() -> void:
	if not GameState.spend_trash(_move_cost()):
		_flash(_upgrade_fast_btn)
		return
	var data := SaveManager.load_game()
	var up: int = int(data.get("upgrade_move", 0)) + 1
	data["upgrade_move"] = up
	SaveManager.save_game(data)
	GameState.restore()
	AudioManager.play_sfx("upgrade", 1.05)
	_flash_success(_upgrade_fast_btn)
	_spawn_upgrade_sparkle(_upgrade_fast_btn)
	_refresh_upgrade_ui()

func _buy_range() -> void:
	if not GameState.spend_trash(_range_cost()):
		_flash(_upgrade_range_btn)
		return
	var data := SaveManager.load_game()
	var up: int = int(data.get("upgrade_range", 0)) + 1
	data["upgrade_range"] = up
	SaveManager.save_game(data)
	GameState.restore()
	AudioManager.play_sfx("upgrade", 1.05)
	_flash_success(_upgrade_range_btn)
	_spawn_upgrade_sparkle(_upgrade_range_btn)
	_refresh_upgrade_ui()

func _buy_deep_cache() -> void:
	if GameState.deep_cache:
		_flash_success(_deep_cache_btn)
		return
	if not GameState.purchase_deep_cache():
		_flash(_deep_cache_btn)
		return
	AudioManager.play_sfx("upgrade", 1.05)
	_flash_success(_deep_cache_btn)
	_refresh_upgrade_ui()

func _buy_deep_cache_upgrade() -> void:
	if not GameState.deep_cache:
		_flash(_deep_cache_upgrade_btn)
		return
	if not GameState.upgrade_deep_cache():
		_flash(_deep_cache_upgrade_btn)
		return
	AudioManager.play_sfx("upgrade", 1.05)
	_flash_success(_deep_cache_upgrade_btn)
	_refresh_upgrade_ui()

func _buy_inv_cap() -> void:
	if not GameState.purchase_inventory_capacity():
		_flash(_inv_cap_btn)
		return
	AudioManager.play_sfx("upgrade", 1.05)
	_flash_success(_inv_cap_btn)
	_refresh_upgrade_ui()

func _move_cost() -> int:
	return 8 + int(SaveManager.load_game().get("upgrade_move", 0)) * 4

func _range_cost() -> int:
	return 12 + int(SaveManager.load_game().get("upgrade_range", 0)) * 6

func _refresh_upgrade_ui() -> void:
	if is_instance_valid(_upgrade_status):
		_upgrade_status.text = _upgrade_status_text()
	if is_instance_valid(_deep_cache_btn):
		_deep_cache_btn.text = _deep_cache_text()
		_deep_cache_btn.disabled = GameState.deep_cache
	if is_instance_valid(_deep_cache_upgrade_btn):
		_deep_cache_upgrade_btn.text = _deep_cache_upgrade_text()
		_deep_cache_upgrade_btn.disabled = (not GameState.deep_cache)
	if is_instance_valid(_inv_cap_btn):
		var cost := 6 + GameState.inventory_capacity_level * 3
		_inv_cap_btn.disabled = GameState.trash_inventory < cost
		_inv_cap_btn.text = _inv_cap_text()
	if is_instance_valid(_upgrade_fast_btn):
		var cost := _move_cost()
		_upgrade_fast_btn.disabled = GameState.trash_inventory < cost
		_upgrade_fast_btn.text = _move_cost_text()
	if is_instance_valid(_upgrade_range_btn):
		var cost := _range_cost()
		_upgrade_range_btn.disabled = GameState.trash_inventory < cost
		_upgrade_range_btn.text = _range_cost_text()
	if is_instance_valid(summary_label):
		summary_label.text = "Trash: %d kg | Upcycle Score: %d | Best Streak: %d" % [GameState.trash_inventory, GameState.upcycle_score, GameState.best_sort_streak]

func _flash(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	var tw := btn.create_tween()
	btn.modulate = Color(1.0, 0.4, 0.4, 1.0)
	tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

func _flash_success(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	var tw := btn.create_tween()
	btn.modulate = Color(0.5, 1.0, 0.55, 1.0)
	tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6)

func _spawn_upgrade_sparkle(anchor: Control) -> void:
	if not is_instance_valid(anchor):
		return
	var p := load("res://scenes/ui/c_p_u_particles2_d.tscn").instantiate() as CPUParticles2D
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 24
	p.lifetime = 0.5
	var r := anchor.get_global_rect()
	p.global_position = r.position + r.size * 0.5
	p.spread = 360.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.gravity = Vector2(0.0, 160.0)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(0.6, 1.0, 0.8, 1.0)
	add_child(p)
	p.emitting = true
	var tw := create_tween()
	tw.tween_interval(p.lifetime + 0.1)
	tw.tween_callback(p.queue_free)

func _update_progress_bars() -> void:
	if not is_instance_valid(_up_bar) or not is_instance_valid(_reef_bar):
		return
	_up_bar.max_value = max(1.0, float(max(1, GameState.best_upcycle_score)))
	_up_bar.value = min(_up_bar.max_value, float(GameState.upcycle_score))
	_reef_bar.max_value = max(1.0, float(max(10, GameState.best_reef_depth)))
	_reef_bar.value = min(_reef_bar.max_value, GameState.reef_garbage)

func _update_cap_status() -> void:
	if not is_instance_valid(cap_status):
		return
	var cap: int = max(1, GameState.get_inventory_capacity())
	var ratio := float(GameState.trash_inventory) / float(cap)
	if ratio >= 1.0:
		cap_status.text = "Inventory FULL (%d/%d) — upgrade or sell" % [GameState.trash_inventory, cap]
		cap_status.modulate = Color(1.0, 0.35, 0.35, 1.0)
	elif ratio >= 0.85:
		cap_status.text = "Inventory heavy (%d/%d)" % [GameState.trash_inventory, cap]
		cap_status.modulate = Color(1.0, 0.85, 0.35, 1.0)
	else:
		cap_status.text = ""

func _setup_bgm_cycle() -> void:
	if is_instance_valid(_bgm_cycle_timer):
		return
	_bgm_cycle_timer = load("res://scenes/ui/timer.tscn").instantiate() as Timer
	_bgm_cycle_timer.wait_time = 18.0
	_bgm_cycle_timer.one_shot = false
	add_child(_bgm_cycle_timer)
	_bgm_cycle_timer.timeout.connect(_tick_bgm_cycle)
	_bgm_cycle_timer.start()

func _tick_bgm_cycle() -> void:
	if AudioManager.get_reduced_motion():
		return
	_bgm_cycle_index = (_bgm_cycle_index + 1) % _bgm_cycle_tracks.size()
	AudioManager.play_bgm(_bgm_cycle_tracks[_bgm_cycle_index])
