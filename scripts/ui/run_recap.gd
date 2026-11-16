extends CanvasLayer

## HUD card shown when the player walks back onto the world map from a
## minigame. Reads (and clears) the pending run recorded in GameState.

const SHOW_SECONDS := 7.0

@onready var panel: PanelContainer = $"Panel"
@onready var title_label: Label = $"Panel/VBox/Title"
@onready var body_label: Label = $"Panel/VBox/Body"
@onready var hint_label: Label = $"Panel/VBox/Hint"
@onready var hide_timer: Timer = $"HideTimer"


func _ready() -> void:
	panel.visible = false
	hide_timer.timeout.connect(_dismiss)
	
	var recap := GameState.consume_last_run()
	if recap.is_empty():
		return
	
	_show(recap)


func _show(recap: Dictionary) -> void:
	title_label.text = str(recap.get("title", "Run complete"))
	
	var lines: Array[String] = []
	for line in recap.get("lines", []):
		lines.append(str(line))
	body_label.text = "\n".join(lines)
	
	var hint := str(recap.get("hint", ""))
	hint_label.text = hint
	hint_label.visible = not hint.is_empty()
	
	panel.visible = true
	panel.modulate.a = 0.0
	var resting_y := panel.position.y
	if GameSettings.reduce_motion:
		# No rise: the card simply appears where it lives.
		panel.position.y = resting_y
		panel.modulate.a = 1.0
	else:
		panel.position.y = resting_y - 14.0
		var tw := create_tween()
		tw.tween_property(panel, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(panel, "position:y", resting_y, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	hide_timer.start(SHOW_SECONDS)


func _dismiss() -> void:
	if not panel.visible:
		return
	
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): panel.visible = false)
