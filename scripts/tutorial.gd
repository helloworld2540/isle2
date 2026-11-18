extends CanvasLayer

## First-run guide card. Authored in scenes/tutorial.tscn; the world map
## decides when to show it (see wm_onboarding.gd).
##
## Goes through CardQueue like every other card, so it can never open on top
## of an achievement in flight. It pauses the tree only once it is on screen.

signal dismissed

@export_multiline var title_text := "Tutorial"
@export_multiline var body_text := ""
@export var button_text := "Got it"

@onready var title: Label = $Center/Panel/VBox/Title
@onready var body: RichTextLabel = $Center/Panel/VBox/BodyScroll/Body
@onready var dismiss_button: Button = $Center/Panel/VBox/Button


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	title.text = title_text
	body.text = body_text
	dismiss_button.text = button_text
	visible = false
	CardQueue.request(self, CardQueue.PRIORITY_MODAL)


func _card_activate() -> void:
	visible = true
	# Blocks milestone cards while the guide is up (see achievement_banner).
	add_to_group("ui_modal_card")
	get_tree().paused = true


func _on_dismiss_pressed() -> void:
	get_tree().paused = false
	remove_from_group("ui_modal_card")
	CardQueue.release(self)
	dismissed.emit()
	queue_free()


func _exit_tree() -> void:
	CardQueue.withdraw(self)
