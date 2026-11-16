extends CanvasLayer

## Generic yes/no confirmation card. Authored scene; the caller connects to
## `confirmed` (and optionally `cancelled`) and decides what each means.
## Runs PROCESS_MODE_ALWAYS so it works while the world pauses itself.

signal confirmed
signal cancelled

@onready var title: Label = $Center/Panel/VBox/Title
@onready var message: Label = $Center/Panel/VBox/Message
@onready var cancel_button: Button = $Center/Panel/VBox/Buttons/CancelButton
@onready var confirm_button: Button = $Center/Panel/VBox/Buttons/ConfirmButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	cancel_button.pressed.connect(_on_cancel)
	confirm_button.pressed.connect(_on_confirm)


## Show the card; the world tree is already paused by the caller's menu.
func present(title_text: String, message_text: String, confirm_text: String = "Yes") -> void:
	title.text = title_text
	message.text = message_text
	confirm_button.text = confirm_text
	visible = true
	confirm_button.grab_focus()


func _on_confirm() -> void:
	visible = false
	confirmed.emit()


func _on_cancel() -> void:
	visible = false
	cancelled.emit()
