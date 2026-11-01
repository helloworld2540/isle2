extends CanvasLayer

@onready var panel: Control = $MenuPanel
@onready var resume_button: Button = $MenuPanel/VBoxContainer/ResumeButton
@onready var save_button: Button = $MenuPanel/VBoxContainer/SaveButton

var _summary_label: Label
var _upgrade_panel: Control
var _upgrade_status: Label
var _upgrade_fast_btn: Button
var _upgrade_range_btn: Button
var _deep_cache_btn: Button
var _inventory_list: Label

func _ready() -> void:
	panel.visible = false

	# Restore a previously saved player position, if any.
	var saved := SaveManager.load_game()
	if saved.has("player_position"):
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = _parse_position(saved["player_position"])

	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Add lightweight trash inventory summary to the world pause panel.
	_summary_label = Label.new()
	_summary_label.text = "Trash in inventory: %d" % GameState.trash_inventory
	_summary_label.modulate = Color(0.85, 0.9, 1.0, 0.9)
	$MenuPanel/VBoxContainer.add_child(_summary_label)

	# Progress bars for reef/upcycle relative to bests.
	_build_progress_bars()

	_create_upgrade_panel()

	_inventory_list = Label.new()
	_inventory_list.modulate = Color(0.75, 0.9, 0.8, 0.9)
	$MenuPanel/VBoxContainer.add_child(_inventory_list)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle()
		get_viewport().set_input_as_handled()
func _process(_delta: float) -> void:
	if panel and panel.visible and _summary_label:
		_summary_label.text = "Trash: %d kg | Upcycle Score: %d | Best Streak: %d" % [GameState.trash_inventory, GameState.upcycle_score, GameState.best_sort_streak]
		var inv := _format_inventory()
		_inventory_list.text = inv
		_update_progress_inline()


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
	panel.visible = not panel.visible
	get_tree().paused = panel.visible


func _on_resume_pressed() -> void:
	panel.visible = false
	get_tree().paused = false
	_summary_label.text = "Trash in inventory: %d" % GameState.trash_inventory


func _on_save_pressed() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var position_value: Array = []
	if player:
		position_value = [player.global_position.x, player.global_position.y]
	var data := SaveManager.load_game()
	data["player_position"] = position_value
	SaveManager.save_game(data)
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

func _create_upgrade_panel() -> void:
	_upgrade_panel = VBoxContainer.new()
	_upgrade_panel.name = "UpgradePanel"
	$MenuPanel/VBoxContainer.add_child(_upgrade_panel)
	var title := Label.new()
	title.text = "Upgrades"
	title.add_theme_font_size_override("font_size", 22)
	_upgrade_panel.add_child(title)
	_upgrade_status = Label.new()
	_upgrade_status.text = _upgrade_status_text()
	_upgrade_panel.add_child(_upgrade_status)
	_upgrade_fast_btn = Button.new()
	_upgrade_fast_btn.text = _move_cost_text()
	_upgrade_fast_btn.pressed.connect(_buy_move)
	_upgrade_panel.add_child(_upgrade_fast_btn)
	_upgrade_range_btn = Button.new()
	_upgrade_range_btn.text = _range_cost_text()
	_upgrade_range_btn.pressed.connect(_buy_range)
	_upgrade_panel.add_child(_upgrade_range_btn)

	_deep_cache_btn = Button.new()
	_deep_cache_btn.text = _deep_cache_text()
	_deep_cache_btn.pressed.connect(_buy_deep_cache)
	_upgrade_panel.add_child(_deep_cache_btn)

func _move_cost_text() -> String:
	return "Move Faster (8 trash each)"

func _range_cost_text() -> String:
	return "Collection Range (12 trash each)"

func _deep_cache_text() -> String:
	return "Deep Cache (30 score) — collects more debris per run" if not GameState.deep_cache else "Deep Cache: OWNED"
func _upgrade_status_text() -> String:
	var data := SaveManager.load_game()
	var mv := int(data.get("upgrade_move", 0))
	var rng := int(data.get("upgrade_range", 0))
	var dc := "DeepCache" if bool(data.get("deep_cache", false)) else "-"
	return "Upgrades -> Move: %d, Range: %d, %s" % [mv, rng, dc]

func _buy_move() -> void:
	if not GameState.spend_trash(8):
		_flash(_upgrade_fast_btn)
		return
	var data := SaveManager.load_game()
	var up: int = int(data.get("upgrade_move", 0)) + 1
	data["upgrade_move"] = up
	SaveManager.save_game(data)
	AudioManager.play_sfx("upgrade")
	_flash_success(_upgrade_fast_btn)
	_refresh_upgrade_ui()

func _buy_range() -> void:
	if not GameState.spend_trash(12):
		_flash(_upgrade_range_btn)
		return
	var data := SaveManager.load_game()
	var up: int = int(data.get("upgrade_range", 0)) + 1
	data["upgrade_range"] = up
	SaveManager.save_game(data)
	AudioManager.play_sfx("upgrade")
	_flash_success(_upgrade_range_btn)
	_refresh_upgrade_ui()

func _buy_deep_cache() -> void:
	if GameState.deep_cache:
		_flash_success(_deep_cache_btn)
		return
	if not GameState.purchase_deep_cache():
		_flash(_deep_cache_btn)
		return
	AudioManager.play_sfx("upgrade")
	_flash_success(_deep_cache_btn)
	_refresh_upgrade_ui()

func _flash(btn: Button) -> void:
	var tw := btn.create_tween()
	btn.modulate = Color(1.0, 0.4, 0.4, 1.0)
	tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

func _refresh_upgrade_ui() -> void:
	_upgrade_status.text = _upgrade_status_text()
	if _deep_cache_btn:
		_deep_cache_btn.text = _deep_cache_text()
		_deep_cache_btn.disabled = GameState.deep_cache
	_summary_label.text = "Trash: %d kg | Upcycle Score: %d | Best Streak: %d" % [GameState.trash_inventory, GameState.upcycle_score, GameState.best_sort_streak]

func _flash_success(btn: Button) -> void:
	if not btn: return
	var tw := btn.create_tween()
	btn.modulate = Color(0.5, 1.0, 0.55, 1.0)
	tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6)


func _build_progress_bars() -> void:
	var up_box := HBoxContainer.new()
	up_box.custom_minimum_size = Vector2(420, 0)
	$MenuPanel/VBoxContainer.add_child(up_box)
	var up_lbl := Label.new()
	up_lbl.text = "Upcycle"
	up_lbl.custom_minimum_size = Vector2(90, 0)
	up_box.add_child(up_lbl)
	var up_bar := ProgressBar.new()
	up_bar.name = "UpcycleProgress"
	up_bar.custom_minimum_size = Vector2(320, 20)
	up_bar.max_value = max(1, GameState.best_upcycle_score)
	up_bar.value = min(GameState.upcycle_score, up_bar.max_value)
	up_box.add_child(up_bar)

	var reef_box := HBoxContainer.new()
	reef_box.custom_minimum_size = Vector2(420, 0)
	$MenuPanel/VBoxContainer.add_child(reef_box)
	var reef_lbl := Label.new()
	reef_lbl.text = "Reef"
	reef_lbl.custom_minimum_size = Vector2(90, 0)
	reef_box.add_child(reef_lbl)
	var reef_bar := ProgressBar.new()
	reef_bar.name = "ReefProgress"
	reef_bar.custom_minimum_size = Vector2(320, 20)
	reef_bar.max_value = max(1, GameState.best_reef_depth)
	reef_bar.value = min(int(GameState.reef_garbage), int(reef_bar.max_value))
	reef_box.add_child(reef_bar)

func _update_progress_bars() -> void:
func _find_node(root: Node, target_name: String) -> Node:
	if root.name == target_name:
		return root
	for c in root.get_children():
		var r := _find_node(c, target_name)
		if r: return r
	return null

	if up_bar:
		up_bar.max_value = max(1, GameState.best_upcycle_score)
		up_bar.value = min(GameState.upcycle_score, up_bar.max_value)
	if reef_bar:
		reef_bar.max_value = max(1, GameState.best_reef_depth)
		reef_bar.value = min(int(GameState.reef_garbage), int(reeef_bar.max_value)) if False else min(int(GameState.reef_garbage), int(reef_bar.max_value))
