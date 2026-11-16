extends CanvasLayer

## First-run guide card. Authored in scenes/tutorial.tscn; the world map
## decides when to show it (see wm_onboarding.gd).

signal dismissed

@export_multiline var title_text := "Tutorial"
@export_multiline var body_text := ""
@export var button_text := "Got it"

@onready var title: Label = $Center/Panel/VBox/Title
@onready var body: RichTextLabel = $Center/Panel/VBox/Body
@onready var dismiss_button: Button = $Center/Panel/VBox/Button


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Blocks milestone cards while the guide is up (see achievement_banner).
	add_to_group("ui_modal_card")
	title.text = title_text
	body.text = body_text
	dismiss_button.text = button_text
	get_tree().paused = true


func _on_dismiss_pressed() -> void:
	get_tree().paused = false
	remove_from_group("ui_modal_card")
	dismissed.emit()
	queue_free()
