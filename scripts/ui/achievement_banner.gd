extends CanvasLayer

## Top-of-screen celebration card for one-time milestones. Presentation only:
## GameState owns the unlocks, this scene listens and announces them.
##
## Announcements are queued: if two milestones land on the same turn-in the
## second card waits for the first to finish instead of clipping it.
##
## Cards also wait for any modal card to close. The turn-in flow closes and
## reopens its conversation while it reports the reward, and the first-run
## guide appears on the same frame the world loads; a card fired into either
## would sit half-hidden underneath. Modals join the "ui_modal_card" group,
## which keeps this file free of NPC/tutorial knowledge. Display is driven
## from _process, never synchronously from present(), so a modal that joins
## the group later in the same frame is still respected.

const SHOW_SECONDS := 5.0
const NPC_LINE_SECONDS := 3.6
## Grace period after the last modal disappears, so the NPC card's
## close/reopen turn-in sequence cannot flash a banner mid-conversation.
const MODAL_CLEAR_DELAY := 0.2

const TITLE_GOLD := Color(1.0, 0.86, 0.35, 1.0)
const TITLE_BLUE := Color(0.62, 0.86, 1.0, 1.0)
const TITLE_LEGEND := Color(1.0, 0.93, 0.6, 1.0)

## Endgame badges that get the loud treatment when they land.
const LEGENDARY_ACHIEVEMENTS := {
	"benchmark": true,
	"reef_veteran": true,
	"loop_master": true,
	"tide_keeper": true,
	"tide_messages": true,
	"whispers": true,
	"keeper_letter": true,
	"silent_chorus": true,
	"long_keeper": true,
	"steady_keeper": true,
	"far_point": true,
	"harbor_hero": true,
	"island_patron": true,
	"island_steward": true,
}

## Two card flavours: gold for milestones/route celebrations, blue for the
## achievement catalogue so a collectible never reads as a story beat.
@export var gold_style: StyleBox
@export var blue_style: StyleBox
@export var legendary_style: StyleBox

@onready var _panel: PanelContainer = $Center/Panel
@onready var _title: Label = $Center/Panel/VBox/Title
@onready var _subtitle: Label = $Center/Panel/VBox/Subtitle
@onready var _hide_timer: Timer = $HideTimer

var _queue: Array[Dictionary] = []
var _showing := false
var _fade_tween: Tween = null

## Set once a modal has been observed while a card is queued; the clear timer
## starts when it goes away so the delay is measured from the close.
var _modal_seen := false
var _modal_closed_ms := 0


func _ready() -> void:
	_panel.visible = false
	set_process(false)
	_hide_timer.timeout.connect(_dismiss)
	GameState.achievement_unlocked.connect(_on_achievement_unlocked)
	GameState.npc_quest_line_completed.connect(_on_npc_quest_line_completed)
	# play order: route celebrations, then catalogue cards, then the bottle
	# epilogue so the gift lands after the achievement it belongs to.
	_play_pending_circuits()
	_flush_pending_achievements()
	_play_tide_gift()
	_play_tide_pool()
	_play_tide_report()
	_play_tide_almanac()


# --- Announcement Sources ---

## Every one-time milestone goes through the same card, so new achievements
## need no presentation code at all.
func _on_achievement_unlocked(_id: String, _title: String, _subtitle: String) -> void:
	_flush_pending_achievements()


## Achievements can be earned in a minigame or the shop, where no banner is
## loaded. Those waits in GameState and are played the moment the map loads.
func _flush_pending_achievements() -> void:
	for def in GameState.consume_pending_achievements():
		var id := String(def.get("id", ""))
		var legendary: bool = LEGENDARY_ACHIEVEMENTS.has(id)
		present(
			String(def.get("title", "")),
			String(def.get("subtitle", "")),
			SHOW_SECONDS,
			{"achievement_id": id, "accent": "legendary" if legendary else "achievement"}
		)


func _on_npc_quest_line_completed(npc_name: String) -> void:
	present(
		"%s — QUESTS CLEARED" % npc_name.to_upper(),
		"Every request on %s's list is done." % npc_name,
		NPC_LINE_SECONDS,
		{"accent": "milestone"}
	)


## A circuit closes while the player is entering a station, so its card is
## played the next time the world map (and this banner) exists.
func _play_pending_circuits() -> void:
	var owed := GameState.consume_circuit_celebrations()
	if owed > 0:
		# The harbor bell: the island notices a finished loop.
		AudioManager.play_sfx("harbor_bell", 0.9)
	for i in range(owed):
		present(
			"ISLAND CIRCUIT",
			"Reef · Upcycle · Shop — full loop, +$%d" % GameState.CIRCUIT_BONUS_MONEY,
			NPC_LINE_SECONDS,
			{"circuit": true, "accent": "milestone"}
		)


## Bottle epilogue: the reward for reading every message in a bottle is a
## one-time 25$ gift with its own card. try_grant_tide_gift is idempotent
## (saved flag), and runs only once the third bottle has been read.
func _play_tide_gift() -> void:
	var gift := GameState.try_grant_tide_gift()
	if gift.is_empty():
		return
	present(
		String(gift.get("title", "TIDE'S GIFT")),
		String(gift.get("subtitle", "The island thanks its keeper.")),
		NPC_LINE_SECONDS,
		{"accent": "milestone"}
	)


## Starfish epilogue: the same 25$ thanks for a finished tidepool set.
func _play_tide_pool() -> void:
	var gift := GameState.try_grant_tide_pool()
	if gift.is_empty():
		return
	present(
		String(gift.get("title", "TIDE POOL")),
		String(gift.get("subtitle", "The island's coastline thanks its keeper.")),
		NPC_LINE_SECONDS,
		{"accent": "milestone"}
	)


## The day's sea conditions, once per island per local day. It plays after the
## rewards so a tide card never buries a payout; the HUD keeps a reminder for
## the rest of the session.
func _play_tide_report() -> void:
	var report := GameState.try_claim_tide_report()
	if report.is_empty():
		return
	present(
		String(report.get("title", "TIDE REPORT")),
		String(report.get("subtitle", "The sea is quiet today.")),
		SHOW_SECONDS,
		{"accent": "tide", "tide": String(report.get("key", ""))}
	)
	# First-tide pointer: explain the HUD line the first time the card appears.
	# Nudge queues behind the active card rather than smothering it.
	TutorialDirector.nudge("tide")


## Almanac epilogue: the four-tide payout. Runs after the report card, so the
## card that completes the almanac is immediately followed by its reward.
func _play_tide_almanac() -> void:
	var gift := GameState.try_grant_tide_almanac()
	if gift.is_empty():
		return
	# The almanac completes — the whole island hears it.
	AudioManager.play_sfx("harbor_bell", 0.75)
	present(
		String(gift.get("title", "THE ALMANAC PAGE")),
		String(gift.get("subtitle", "The keeper's last entry.")),
		NPC_LINE_SECONDS + 1.4,
		{"accent": "milestone"}
	)


## Queues a celebration card. Reusable by future achievements; `owner_data`
## lets the card be replayed if the map unloads before it is shown.
func present(title: String, subtitle: String, seconds: float = SHOW_SECONDS, owner_data: Dictionary = {}) -> void:
	var entry := {
		"title": title,
		"subtitle": subtitle,
		"seconds": maxf(0.5, seconds),
	}
	for key in owner_data.keys():
		entry[key] = owner_data[key]
	_queue.append(entry)
	set_process(true)


func _exit_tree() -> void:
	# Cards that never got on screen go back to the state queue: walking into
	# a portal a second after earning something must not eat the celebration.
	for entry in _queue:
		var achievement_id := String(entry.get("achievement_id", ""))
		if not achievement_id.is_empty():
			GameState.requeue_achievement_card(achievement_id)
		elif bool(entry.get("circuit", false)):
			GameState.requeue_circuit_celebration()


# --- Playback ---

## True while any modal card (dialogue, first-run guide, briefing) is up.
func _modal_open() -> bool:
	return get_tree().get_first_node_in_group("ui_modal_card") != null


func _process(_delta: float) -> void:
	if _showing or _queue.is_empty():
		set_process(false)
		return
	
	if _modal_open():
		_modal_seen = true
		_modal_closed_ms = 0
		return
	
	if _modal_seen:
		if _modal_closed_ms == 0:
			_modal_closed_ms = Time.get_ticks_msec()
			return
		if Time.get_ticks_msec() - _modal_closed_ms < int(MODAL_CLEAR_DELAY * 1000.0):
			return
	
	_modal_seen = false
	_modal_closed_ms = 0
	_show_next()


func _show_next() -> void:
	if _showing or _queue.is_empty():
		set_process(false)
		return
	
	# A card requested during a conversation is held until it ends.
	if _modal_open():
		_modal_seen = true
		_modal_closed_ms = 0
		set_process(true)
		return
	
	var entry: Dictionary = _queue.pop_front()
	if _queue.is_empty():
		set_process(false)
	
	_showing = true
	_title.text = str(entry.get("title", ""))
	_subtitle.text = str(entry.get("subtitle", ""))
	_apply_accent(String(entry.get("accent", "milestone")))
	var accent := String(entry.get("accent", "milestone"))
	# Soft chime so a card is noticed while the player is mid-swipe/steering.
	# Achievements ring a touch higher than story milestones; legends higher still.
	var pitch := 0.9
	if accent == "achievement":
		pitch = 1.0
	elif accent == "tide":
		pitch = 0.7
		# The tide gets the sea's own voice, not the chime.
		AudioManager.play_sfx("reef_swell", 0.9)
	elif accent == "legendary":
		pitch = 1.25
	if accent == "legendary":
		# Legends ring the harbor bell — the island hears a big one.
		AudioManager.play_sfx("harbor_bell", 0.85)
	AudioManager.play_sfx("achievement", pitch)
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


## Blue band for catalogue achievements, gold for everything else — and a
## thick-rimmed halo treatment for the endgame legends.
func _apply_accent(accent: String) -> void:
	if accent == "legendary":
		if legendary_style and _panel:
			_panel.add_theme_stylebox_override("panel", legendary_style)
		if _title:
			_title.add_theme_color_override("font_color", TITLE_LEGEND)
		return

	var achievement := accent == "achievement" or accent == "tide"
	var style: StyleBox = blue_style if achievement else gold_style
	if style and _panel:
		_panel.add_theme_stylebox_override("panel", style)
	if _title:
		_title.add_theme_color_override("font_color", TITLE_BLUE if achievement else TITLE_GOLD)


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
