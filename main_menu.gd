extends Control

@onready var new_save_button: Button = $NewSaveButton
@onready var load_save_button: Button = $LoadSaveButton

func _ready() -> void:
	new_save_button.pressed.connect(_on_new_save_pressed)
	load_save_button.pressed.connect(_on_load_save_pressed)
	load_save_button.disabled = not SaveManager.has_save()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_new_save_pressed() -> void:
	SaveManager.new_save()
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_load_save_pressed() -> void:
	if not SaveManager.has_save(): return
	get_tree().change_scene_to_file("res://scenes/world.tscn")
