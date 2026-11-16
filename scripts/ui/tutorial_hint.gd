extends CanvasLayer

## Non-modal step hint card used by the TutorialDirector. Slides in at the
## bottom of the screen, never pauses the tree, and never blocks input outside
## the card itself — the player can keep playing and dismiss whenever.
## The director owns which step text is shown; this card only presents it.
##
## Layout convention: every overlay card sits inside the same 24 px screen
## margin (MarginContainer here; centered CenterContainer on the modal cards),
## so nothing ever touches a screen edge.

signal dismissed

@export_multiline var title_text := "Hint"
@export_multiline var body_text := ""
@export var button_text := "Got it"

@onready var panel: PanelContainer = $Margin/Column/Panel
@onready var title: Label = $Margin/Column/Panel/VBox/Title
@onready var body: RichTextLabel = $Margin/Column/Panel/VBox/Body
@onready var dismiss_button: Button = $Margin/Column/Panel/VBox/Button

func _ready() -> void:
	layer = 190
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Bottom-centre lane owner: toasts stack above this card, never under it.
	panel.add_to_group("hud_bottom_card")
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
