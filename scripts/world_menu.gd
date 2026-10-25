extends CanvasLayer

@onready var panel: Control = $MenuPanel
@onready var resume_button: Button = $MenuPanel/VBoxContainer/ResumeButton
@onready var save_button: Button = $MenuPanel/VBoxContainer/SaveButton

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	panel.visible = not panel.visible
	get_tree().paused = panel.visible


func _on_resume_pressed() -> void:
	panel.visible = false
	get_tree().paused = false


func _on_save_pressed() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var position_value: Array = []
	if player:
		position_value = [player.global_position.x, player.global_position.y]
	SaveManager.save_game({"player_position": position_value})
	panel.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _parse_position(value) -> Vector2:
	if value is Array and value.size() == 2:
		return Vector2(value[0], value[1])
	if value is String:
		var cleaned := (value as String).strip_edges().trim_prefix("(").trim_suffix(")")
		var parts := cleaned.split(",")
		if parts.size() == 2:
			return Vector2(parts[0].to_float(), parts[1].to_float())
	return Vector2.ZERO
