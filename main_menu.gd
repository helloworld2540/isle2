extends Control

@onready var new_save_button: Button = $NewSaveButton
@onready var load_save_button: Button = $LoadSaveButton

func _ready() -> void:
	new_save_button.pressed.connect(_on_new_save_pressed)
	load_save_button.pressed.connect(_on_load_save_pressed)
	load_save_button.disabled = not SaveManager.has_save()
	_create_continue_preview()

func _create_continue_preview() -> void:
	var preview := Label.new()
	preview.text = _preview_text()
	preview.position = Vector2(16, 16)
	preview.custom_minimum_size = Vector2(560, 0)
	add_child(preview)

func _preview_text() -> String:
	if not SaveManager.has_save():
		return "No save file yet."
	var d := SaveManager.load_game()
	var score := int(d.get("upcycle_score", 0))
	var garbage := float(d.get("reef_garbage", 0.0))
	var fish := int(d.get("reef_fish", 0))
	return "Last save: Score %d | Reef %dkg, %d fish | Best score %d" % [score, int(garbage), fish, int(d.get("best_upcycle_score", 0))]

func _on_start_pressed() -> void:
	SceneTransition.change_scene("res://scenes/world.tscn")

func _on_new_save_pressed() -> void:
	SaveManager.new_save()
	SceneTransition.change_scene("res://scenes/world.tscn")

func _on_load_save_pressed() -> void:
	if not SaveManager.has_save(): return
	SceneTransition.change_scene("res://scenes/world.tscn")
