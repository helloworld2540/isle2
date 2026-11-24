extends CanvasLayer

## HUD card shown when the player walks back onto the world map from a
## minigame. Reads (and clears) the pending run recorded in GameState.
##
## Goes through CardQueue like every other card: if a welcome guide, a
## conversation or a hint already owns the screen, the recap waits its turn
## instead of landing underneath it.

const SHOW_SECONDS := 7.0

@onready var panel: PanelContainer = $"Panel"
@onready var title_label: Label = $"Panel/VBox/TitleRow/Title"
@onready var body_label: Label = $"Panel/VBox/Body"
@onready var hint_label: Label = $"Panel/VBox/Hint"
@onready var hide_timer: Timer = $"HideTimer"

## The recap consumed at _ready but not yet presented (waiting in the queue).
var _pending: Dictionary = {}


func _ready() -> void:
	panel.visible = false
	hide_timer.timeout.connect(_dismiss)

	var recap := GameState.consume_last_run()
	if recap.is_empty():
		return

	_pending = recap
	# Ask the shared card lane for the screen; `_card_activate` presents it
	# once the cards ahead of it have closed.
	CardQueue.request(self, CardQueue.PRIORITY_AMBIENT)


## The lane granted us the screen: build and show the recap.
func _card_activate() -> void:
	var recap := _pending
	_pending = {}
	if recap.is_empty():
		# Lost to a scene change while waiting: hand the lane straight back.
		CardQueue.release(self)
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


## The small "X" in the card's top-right corner dismisses early (the auto-hide
## timer is the fallback). Same fade-out path as the timer.
func _on_close_pressed() -> void:
	_dismiss()


func _dismiss() -> void:
	if not panel.visible:
		return
	# Release the lane only once the card has actually left the screen, so the
	# next card never rises through the fading panel.
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		panel.visible = false
		CardQueue.release(self)
	)


## Left the tree without a close (scene change): the queue must not try to
## present a recap that no longer exists.
func _exit_tree() -> void:
	CardQueue.withdraw(self)
