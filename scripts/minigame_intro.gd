extends CanvasLayer

## Pre-round briefing overlay. Authored entirely in minigame_intro.tscn;
## each minigame instance sets intro_title / intro_lines in its own scene.

class_name MinigameIntro

@export var intro_title := "Mini-game"
@export var intro_lines: PackedStringArray = PackedStringArray()

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/Title
@onready var lines_label: RichTextLabel = $Panel/VBox/Lines
@onready var got_it_button: Button = $Panel/VBox/GotItButton
@onready var stats_label: Label = $Panel/VBox/Stats


func _ready() -> void:
	add_to_group("ui_modal_card")
	_apply_text()
	get_tree().paused = true
	get_tree().root.set_disable_input(false)
	
	panel.scale = Vector2(0.95, 0.95) if not GameSettings.reduce_motion else Vector2.ONE
	if not GameSettings.reduce_motion:
		var pop := create_tween()
		pop.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Optional runtime override; scene-authored values cover the normal case.
func configure(title_text: String, lines: Array) -> void:
	intro_title = title_text
	intro_lines = PackedStringArray(lines)
	if is_inside_tree():
		_apply_text()


## A single line of personal stake shown under the checklist —
## "Best: N · Runs: M". Empty text hides the row entirely.
func set_stat_line(text: String) -> void:
	if not stats_label:
		return
	var trimmed := text.strip_edges()
	stats_label.text = trimmed
	stats_label.visible = not trimmed.is_empty()


func _apply_text() -> void:
	if title_label:
		title_label.text = intro_title
	if not lines_label:
		return
	
	var parts: PackedStringArray = []
	for line in intro_lines:
		parts.append("• " + str(line))
	lines_label.text = "[font_size=20]%s[/font_size]" % "\n".join(parts)


func _on_got_it_pressed() -> void:
	get_tree().paused = false
	remove_from_group("ui_modal_card")
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and got_it_button:
		_on_got_it_pressed()
