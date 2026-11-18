extends CanvasLayer

## NPC conversation card. Owns presentation only; WorldNPC decides what is
## said and what a quest turn-in does.

class_name NpcDialogue

signal closed
signal turn_in_requested(tier: int)

## Characters revealed per second by the typewriter reveal.
const TYPE_SPEED := 60.0

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $Center/Panel
@onready var portrait: TextureRect = $Center/Panel/VBox/Header/Portrait
@onready var title_label: Label = $Center/Panel/VBox/Header/Title
@onready var lines_label: RichTextLabel = $Center/Panel/VBox/LinesScroll/Lines
@onready var reward_label: Label = $Center/Panel/VBox/Reward
@onready var quest_box: VBoxContainer = $Center/Panel/VBox/QuestBox
@onready var quest_label: Label = $Center/Panel/VBox/QuestBox/QuestLabel
@onready var turn_in_button: Button = $Center/Panel/VBox/QuestBox/TurnIn
@onready var status_label: Label = $Center/Panel/VBox/Status
@onready var ok_button: Button = $Center/Panel/VBox/OkButton

var _quest_tier := 0


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
		return
	var intro := create_tween().set_parallel(true)
	intro.tween_property(panel, "modulate:a", 1.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Content ---

func present(npc_title: String, lines: Array, portrait_texture: Texture2D = null) -> void:
	title_label.text = npc_title
	if portrait:
		portrait.texture = portrait_texture
		portrait.visible = portrait_texture != null
	
	var text: Array[String] = []
	for line in lines:
		text.append(str(line))
	lines_label.text = "\n".join(text)
	_type_out()


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
	CardQueue.withdraw(self)


# --- Presentation ---

func _type_out() -> void:
	var chars := maxi(1, lines_label.get_total_character_count())
	if GameSettings.reduce_motion:
		# No typewriter crawl under reduced motion: show the full text at once.
		lines_label.visible_characters = -1
		return
	lines_label.visible_characters = 0
	
	# Skip straight to full text when the player already pressed OK once.
	var tw := create_tween()
	tw.tween_property(lines_label, "visible_characters", chars, float(chars) / TYPE_SPEED)
	tw.tween_callback(func(): lines_label.visible_characters = -1)


func _on_ok_pressed() -> void:
	dismiss()


func _on_turn_in_pressed() -> void:
	turn_in_requested.emit(_quest_tier)
