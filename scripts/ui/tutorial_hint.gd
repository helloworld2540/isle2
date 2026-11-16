extends CanvasLayer

## Non-modal step hint card used by the TutorialDirector. Slides in at the
## bottom of the screen, never pauses the tree, and never blocks input outside
## the card itself — the player can keep playing and dismiss whenever.
## The director owns which step text is shown; this card only presents it.

signal dismissed

@export_multiline var title_text := "Hint"
@export_multiline var body_text := ""
@export var button_text := "Got it"

@onready var panel: PanelContainer = $Anchor/Center/Panel
@onready var title: Label = $Anchor/Center/Panel/VBox/Title
@onready var body: RichTextLabel = $Anchor/Center/Panel/VBox/Body
@onready var dismiss_button: Button = $Anchor/Center/Panel/VBox/Button

func _ready() -> void:
	layer = 190
	process_mode = Node.PROCESS_MODE_ALWAYS
	title.text = title_text
	body.text = body_text
	dismiss_button.text = button_text
	# Gentle rise-and-fade entrance so the card reads as a nudge, not a wall.
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_dismiss_pressed() -> void:
	AudioManager.play_sfx("pickup", 1.15)
	dismissed.emit()
	queue_free()
