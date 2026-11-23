extends CanvasLayer

## NPC conversation card. Owns presentation only; WorldNPC decides what is
## said and what a quest turn-in does.
##
## The card speaks ONE line at a time. Each press of the button (or Enter /
## Space) first completes the line being typed, then advances to the next one;
## the last press closes the conversation. ESC skips the rest and closes.
## Reward / quest / status rows are supplied by the caller and stay put — only
## the spoken lines are paced, so a multi-topic greeting no longer lands as a
## single wall of text.

class_name NpcDialogue

signal closed
signal turn_in_requested(tier: int)

## Characters revealed per second by the typewriter reveal.
const TYPE_SPEED := 60.0

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $Center/Panel
@onready var portrait: TextureRect = $Center/Panel/VBox/Header/Portrait
@onready var title_label: Label = $Center/Panel/VBox/Header/Title
@onready var lines_scroll: ScrollContainer = $Center/Panel/VBox/LinesScroll
@onready var lines_label: RichTextLabel = $Center/Panel/VBox/LinesScroll/Lines
@onready var reward_label: Label = $Center/Panel/VBox/Reward
@onready var quest_box: VBoxContainer = $Center/Panel/VBox/QuestBox
@onready var quest_label: Label = $Center/Panel/VBox/QuestBox/QuestLabel
@onready var turn_in_button: Button = $Center/Panel/VBox/QuestBox/TurnIn
@onready var status_label: Label = $Center/Panel/VBox/Status
@onready var ok_button: Button = $Center/Panel/VBox/OkButton

var _quest_tier := 0
## The spoken lines, revealed one per press.
var _lines: Array[String] = []
var _line_index := 0
## True while the current line is still being typed out.
var _typing := false
var _reveal: Tween = null
## True once the shared queue has granted this card the screen.
var _activated := false


func _ready() -> void:
	reward_label.visible = false
	quest_box.visible = false
	status_label.visible = false
	
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)
	# A conversation never opens on top of another card. Wait for the shared
	# queue; it calls `_card_activate()` when this conversation is next.
	visible = false
	CardQueue.request(self, CardQueue.PRIORITY_MODAL)


## The queue granted us the screen: become the visible conversation.
func _card_activate() -> void:
	_activated = true
	visible = true
	# Milestone banners watch this group so celebrations never play underneath
	# a conversation. Joined on activation, so a *waiting* card is never
	# mistaken for one that is open.
	add_to_group("ui_modal_card")
	# A conversation should not fight the BGM; duck while the card is up and
	# let the AudioManager fade it back in when the card closes.
	AudioManager.duck_music()
	if GameSettings.reduce_motion:
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
	else:
		var intro := create_tween().set_parallel(true)
		intro.tween_property(panel, "modulate:a", 1.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		intro.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Start the first line only now: a card parked behind another must not
	# spend its opening line (and its typewriter) while the player cannot see it.
	if not _lines.is_empty():
		_show_line()


# --- Content ---

func present(npc_title: String, lines: Array, portrait_texture: Texture2D = null) -> void:
	title_label.text = npc_title
	if portrait:
		portrait.texture = portrait_texture
		portrait.visible = portrait_texture != null
	
	_lines.clear()
	for line in lines:
		var text := str(line)
		if not text.strip_edges().is_empty():
			_lines.append(text)
	if _lines.is_empty():
		_lines.append("...")
	_line_index = 0
	# present() normally runs right after the card enters the tree and before
	# the queue grants the screen; `_card_activate()` then shows line one. If we
	# are already on screen, show it here.
	if _activated:
		_show_line()


func show_reward(text: String) -> void:
	reward_label.text = text
	reward_label.visible = true


func show_quest(tier: int, text: String, button_text: String, enabled: bool) -> void:
	_quest_tier = tier
	quest_label.text = text
	turn_in_button.text = button_text
	turn_in_button.disabled = not enabled
	quest_box.visible = true


func show_status(text: String, positive: bool) -> void:
	status_label.text = text
	status_label.modulate = Color(0.7, 1.0, 0.75, 1.0) if positive else Color(0.95, 0.7, 0.35, 1.0)
	status_label.visible = true


# --- Pacing ---

## Reveal the current line from the top, typing it out.
func _show_line() -> void:
	if _lines.is_empty():
		return
	lines_label.text = _lines[_line_index]
	if lines_scroll:
		lines_scroll.scroll_vertical = 0
	_type_out()
	_sync_button()


## One step of the conversation: finish a line mid-type, else move to the next
## line, else close. Bound to the button and to Enter / Space.
func advance() -> void:
	if _typing:
		if _reveal and _reveal.is_valid():
			_reveal.kill()
		_finish_line()
		return
	if _line_index < _lines.size() - 1:
		_line_index += 1
		_show_line()
		return
	dismiss()


## The button tells the player what the next press will do.
func _sync_button() -> void:
	ok_button.text = "OK" if _line_index >= _lines.size() - 1 else "Next"


func _type_out() -> void:
	if GameSettings.reduce_motion:
		# No typewriter crawl under reduced motion: show the full line at once.
		_finish_line()
		return
	var chars := maxi(1, lines_label.get_total_character_count())
	if _reveal and _reveal.is_valid():
		_reveal.kill()
	_typing = true
	lines_label.visible_characters = 0
	_reveal = create_tween()
	_reveal.tween_property(lines_label, "visible_characters", chars, float(chars) / TYPE_SPEED)
	_reveal.tween_callback(func(): lines_label.visible_characters = -1)


func _finish_line() -> void:
	_typing = false
	lines_label.visible_characters = -1
	_sync_button()


func dismiss() -> void:
	if not is_inside_tree():
		return
	remove_from_group("ui_modal_card")
	AudioManager.restore_music()
	CardQueue.release(self)
	closed.emit()
	queue_free()


func _exit_tree() -> void:
	# Left the tree without a close (scene change): the queue must not try to
	# show a conversation that no longer exists.
	if _reveal and _reveal.is_valid():
		_reveal.kill()
	CardQueue.withdraw(self)


# --- Input ---

## Keyboard pacing. The button already handles mouse and a focused Enter /
## Space; this covers the unfocused case and lets ESC bail out of a long
## conversation. A queued card (not yet on screen) ignores keys entirely.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		advance()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		dismiss()


func _on_ok_pressed() -> void:
	advance()


func _on_turn_in_pressed() -> void:
	turn_in_requested.emit(_quest_tier)
