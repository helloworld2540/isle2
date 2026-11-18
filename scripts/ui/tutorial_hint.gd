extends CanvasLayer

## Non-modal step hint card used by the TutorialDirector. Slides in at the
## bottom of the screen, never pauses the tree, and never blocks input outside
## the card itself — the player can keep playing and dismiss whenever.
## The director owns which step text is shown; this card only presents it.
##
## Layout convention: every overlay card sits inside the same 24 px screen
## margin (MarginContainer here; centered CenterContainer on the modal cards),
## so nothing ever touches a screen edge.
##
## Cards are serialised through CardQueue: a hint never lands on top of a
## conversation or a milestone card — it waits its turn.

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
	title.text = title_text
	body.text = body_text
	dismiss_button.text = button_text
	panel.modulate.a = 0.0
	# Wait for the one-at-a-time lane; `_card_activate` presents when it is free.
	visible = false
	CardQueue.request(self, CardQueue.PRIORITY_AMBIENT)


func _card_activate() -> void:
	visible = true
	# Bottom-centre lane owner: toasts stack above this card, never under it.
	panel.add_to_group("hud_bottom_card")
	# Gentle rise-and-fade entrance so the card reads as a nudge, not a wall.
	panel.modulate.a = 0.0
	if GameSettings.reduce_motion:
		# No rise under reduced motion: the nudge card simply is there.
		panel.modulate.a = 1.0
		return
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_dismiss_pressed() -> void:
	AudioManager.play_sfx("pickup", 1.15)
	panel.remove_from_group("hud_bottom_card")
	CardQueue.release(self)
	dismissed.emit()
	queue_free()


func _exit_tree() -> void:
	CardQueue.withdraw(self)
