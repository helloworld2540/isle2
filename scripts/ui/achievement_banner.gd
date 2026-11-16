extends CanvasLayer

## Top-of-screen celebration card for one-time milestones. Presentation only:
## GameState owns the unlocks, this scene listens and announces them.
##
## Announcements are queued: if two milestones land on the same turn-in the
## second card waits for the first to finish instead of clipping it.

const SHOW_SECONDS := 5.0
const NPC_LINE_SECONDS := 3.6

@onready var _panel: PanelContainer = $Center/Panel
@onready var _title: Label = $Center/Panel/VBox/Title
@onready var _subtitle: Label = $Center/Panel/VBox/Subtitle
@onready var _hide_timer: Timer = $HideTimer

var _queue: Array[Dictionary] = []
var _showing := false
var _fade_tween: Tween = null


func _ready() -> void:
	_panel.visible = false
	_hide_timer.timeout.connect(_dismiss)
	GameState.harbor_hero_unlocked.connect(_on_harbor_hero_unlocked)
	GameState.npc_quest_line_completed.connect(_on_npc_quest_line_completed)


# --- Announcement Sources ---

func _on_harbor_hero_unlocked() -> void:
	var bonus_kg: int = GameState.HARBOR_HERO_CAPACITY_BONUS * 10
	present(
		"HARBOR HERO",
		"Every quest tier cleared — bag capacity +%d kg!" % bonus_kg
	)


func _on_npc_quest_line_completed(npc_name: String) -> void:
	present(
		"%s — QUESTS CLEARED" % npc_name.to_upper(),
		"Every request on %s's list is done." % npc_name,
		NPC_LINE_SECONDS
	)


## Queues a celebration card. Reusable by future achievements.
func present(title: String, subtitle: String, seconds: float = SHOW_SECONDS) -> void:
	_queue.append({"title": title, "subtitle": subtitle, "seconds": maxf(0.5, seconds)})
	if not _showing:
		_show_next()


# --- Playback ---

func _show_next() -> void:
	if _showing or _queue.is_empty():
		return
	
	var entry: Dictionary = _queue.pop_front()
	_showing = true
	_title.text = str(entry.get("title", ""))
	_subtitle.text = str(entry.get("subtitle", ""))
	_panel.visible = true
	_hide_timer.start(float(entry.get("seconds", SHOW_SECONDS)))
	
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
	
	_panel.modulate.a = 0.0
	if GameSettings.reduce_motion:
		_panel.modulate.a = 1.0
		_panel.scale = Vector2.ONE
		return
	
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.92, 0.92)
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(_panel, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _dismiss() -> void:
	if not _showing:
		return
	_showing = false
	_hide_timer.stop()
	
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
	
	if GameSettings.reduce_motion:
		_panel.visible = false
		_show_next()
		return
	
	_fade_tween = create_tween()
	_fade_tween.tween_property(_panel, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_fade_tween.tween_callback(func():
		_panel.visible = false
		_show_next()
	)
