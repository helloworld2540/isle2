extends Node

## Step-by-step first-playthrough guide ("walk → dive → sort → sell").
##
## Autoloaded as TutorialDirector. The flow:
##   1. Brand-new save → main menu → world: wm_onboarding shows the welcome
##      card and calls TutorialDirector.start() on dismiss.
##   2. Each step arms a trigger heard through notify() / scene_started().
##      Steps are scene-scoped: the hint only appears while the player is in
##      the scene that can complete it (e.g. the "sell" hint in the shop).
##   3. Completing a step plays a chime and advances. The last step is a
##      celebratory card announcing the island circuit.
## State persists as save key `tutorial_step` (1..5, or DONE=999), so the
## guide survives quitting mid-tour and never re-arms for old saves.
##
## Scenes call in with two primitives:
##   scene_started(tag) — from _ready: "world" | "reef" | "upcycle" | "shop"
##   notify(event)      — "move" | "reef_entered" | "sorted" | "sold"

const HINT_SCENE := preload("res://scenes/ui/tutorial_hint.tscn")

const DONE := 999
const STEP_MOVE := 1
const STEP_REEF := 2
const STEP_SORT := 3
const STEP_SELL := 4
const STEP_FINALE := 5

## Per step: which scene shows the hint, and the copy to show there.
const STEPS := {
	STEP_MOVE: {
		"title": "Take a stroll",
		"body": "[font_size=20][color=#9fe2ff]Tap anywhere[/color] and your islander will walk there.\nThe glowing trail and flow dots point to the next stop on the circuit.[/font_size]",
		"button": "On my way",
	},
	STEP_REEF: {
		"title": "Dive the reef",
		"body": "[font_size=20]Head to the [color=#9fe2ff]south dock[/color] — that is Reef Rescue.\nDodge fish, scoop up junk, and bank a deep haul as Reef Debris.[/font_size]",
		"button": "Got it",
	},
	STEP_SORT: {
		"title": "Sort at the bench",
		"body": "[font_size=20]Now ride the belt at the [color=#9fe2ff]Upcycle bench[/color] (east).\nMatch each piece to its bin — correct sorts become material.[/font_size]",
		"button": "Got it",
	},
	STEP_SELL: {
		"title": "Cash in at the shop",
		"body": "[font_size=20]The [color=#9fe2ff]shop[/color] (north) turns materials into money.\nSelling 5+ of one type pays a [color=#ffd27f]+25% bulk bonus[/color].[/font_size]",
		"button": "Got it",
	},
	STEP_FINALE: {
		"title": "You know the loop!",
		"body": "[font_size=20][color=#8fd0a0]Reef → Upcycle → Shop[/color] is the island circuit.\nClear all three stops for a [color=#ffd27f]$15 circuit bonus[/color] — then chase the locals, the bottles on the shore, and the tide itself; it keeps four days and never repeats in a hurry.\nAnd if the shop counter mentions a page the courier left, that is not a rumour.[/font_size]",
		"button": "Let's clean up",
	},
}

## Where each step's hint may appear; the hint arms whenever the player is in
## one of these scenes and the step is still pending. Sell hints show on the
## map (where to go) and inside the shop (what to do there).
const STEP_SCENE_TAG := {
	STEP_MOVE: ["world"],
	STEP_REEF: ["world"],
	STEP_SORT: ["world", "upcycle"],
	STEP_SELL: ["world", "shop"],
	STEP_FINALE: ["*"],
}

## One-shot ambient nudges that live outside the linear tour: a bag-full
## warning the first time the hold crosses 85%, a bottle pointer once the
## tour is done, an upgrade pointer after your first sale, and a terminal
## pointer once you can actually afford a speed/range upgrade. Persisted
## flags make each fire exactly once per save.
const NUDGE_BAG := "nudge_bag_shown"
const NUDGE_BOTTLE := "nudge_bottle_shown"
const NUDGE_UPGRADE := "nudge_upgrade_shown"
const NUDGE_TUNE := "nudge_tune_shown"
const NUDGE_DEEP_CACHE := "nudge_deep_cache_shown"
const NUDGE_UNDO := "nudge_undo_shown"
const NUDGE_QUEST := "nudge_quest_shown"
const NUDGE_MEET := "nudge_meet_shown"
const NUDGE_LEDGER := "nudge_ledger_shown"
const NUDGE_GOLD := "nudge_gold_shown"
const NUDGE_STARFISH := "nudge_starfish_shown"
const NUDGE_STARFISH_FINAL := "nudge_starfish_final_shown"
const NUDGE_TIDE := "nudge_tide_shown"
const NUDGE_TIP := "nudge_tip_shown"
const NUDGE_WELCOME_BACK := "nudge_welcome_back_shown"
const NUDGE_WATCHER_NOTE := "nudge_watcher_note_shown"
const NUDGE_COURIER := "nudge_courier_shown"

var _step: int = 0
var _active_hint: CanvasLayer = null
## A nudge deferred because a card or modal owned the screen. Fires once the
## current card is dismissed — so a two-card trigger (first bulk sale) still
## lands both cards instead of the second evaporating.
var _pending_nudge: String = ""
var _pending_tick: float = 0.0
var _nudge_state: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_step()


func _load_step() -> void:
	var data := SaveManager.load_game()
	_step = int(data.get("tutorial_step", 0))
	if _step <= 0:
		# Missing key: either a fresh tour still pending the welcome card
		# (seen=false) or a save from before the step system existed.
		_step = DONE if bool(data.get("tutorial_seen", false)) else 0
		if _step == DONE:
			SaveManager.update_game({"tutorial_step": DONE})


## Called by wm_onboarding when the welcome card is dismissed (fresh save).
## Arms the tour unconditionally from the live save — never infers step 0
## from `seen`, which is already true by the time this runs.
func start() -> void:
	var data := SaveManager.load_game()
	if int(data.get("tutorial_step", 0)) > 0:
		# Tour already armed or finished; don't re-arm mid-session.
		_step = int(data.get("tutorial_step", DONE))
		return
	_step = 0
	_set_step(STEP_MOVE)
	_show_hint(_step)


## Called from each relevant scene's _ready. Shows the hint for the current
## step when the player is standing in the scene that step cares about.
func scene_started(tag: String) -> void:
	_load_step()
	match tag:
		"reef":
			notify("reef_entered")
		_: pass
	if _step >= DONE or _step == 0:
		return
	var wanted: Variant = STEP_SCENE_TAG.get(_step, [])
	if wanted is Array and not "*" in wanted and not tag in wanted:
		_clear_hint()
		return
	_show_hint(_step)
## One-shot events from gameplay. Unknown events for the current step are ignored.
func notify(event: String) -> void:
	var completed := false
	match _step:
		STEP_MOVE:
			completed = event == "move"
		STEP_REEF:
			completed = event == "reef_entered"
		STEP_SORT:
			completed = event == "sorted"
		STEP_SELL:
			completed = event == "sold"
		_:
			completed = false
	if completed:
		_advance()


func _advance() -> void:
	AudioManager.play_sfx("quest_complete", 1.15)
	_set_step(_step + 1)
	_clear_hint()
	# Re-arm immediately if the new step's scenes include the current one —
	# otherwise the next hint would not appear until the player re-enters.
	if _step == STEP_FINALE:
		_show_hint(STEP_FINALE)
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var tag := String(scene.name).to_lower()
	if tag.contains("reef"):
		tag = "reef"
	elif tag.contains("upcycle"):
		tag = "upcycle"
	elif tag.contains("shop"):
		tag = "shop"
	elif tag.contains("world"):
		tag = "world"
	else:
		return
	var wanted: Variant = STEP_SCENE_TAG.get(_step, [])
	if wanted is Array and ("*" in wanted or tag in wanted):
		_show_hint(_step)


func _set_step(n: int) -> void:
	_step = n
	SaveManager.update_game({"tutorial_step": n})
	if n >= DONE:
		_clear_hint()
		SaveManager.update_game({"tutorial_complete": true})


func _show_hint(step: int) -> void:
	_clear_hint()
	# Defer one frame: during a scene change, _ready fires before SceneTree
	# swaps current_scene, so attaching now would parent the card to the
	# dying scene (or the autoload) and it would vanish or linger forever.
	call_deferred("_spawn_hint", step)


func _spawn_hint(step: int) -> void:
	if step != _step or _step >= DONE:
		return  # the step finished or advanced while we were deferring
	var info: Dictionary = STEPS.get(step, {})
	if info.is_empty():
		return
	# A modal card (welcome guide / minigame briefing) owns the screen. Wait it
	# out instead of stacking the step card on top of the briefing.
	if _modal_card_active():
		await _wait_for_modal()
		if step != _step or _step >= DONE:
			return  # dismissed into an advance or a finished tour
	_spawn_card(String(info.get("title", "")), String(info.get("body", "")), String(info.get("button", "Got it")))


## True while a dimming modal card (welcome guide, minigame briefing) is up.
## Those cards register in the "ui_modal_card" group, the same handshake the
## achievement banner uses to avoid talking over them.
func _modal_card_active() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	return not tree.get_nodes_in_group("ui_modal_card").is_empty()


## Resumes when the last modal card is gone. process_frame keeps firing while
## the tree is paused (the modals pause it), so this does not deadlock.
func _wait_for_modal() -> void:
	while _modal_card_active():
		await get_tree().process_frame


func _spawn_card(title: String, body: String, button: String) -> void:
	_clear_hint()
	var hint := HINT_SCENE.instantiate()
	hint.title_text = title
	hint.body_text = body
	hint.button_text = button
	hint.dismissed.connect(_on_hint_dismissed)
	var scene := get_tree().current_scene
	if scene:
		scene.add_child(hint)
	else:
		get_tree().root.add_child(hint)
	_active_hint = hint


## Drains a deferred nudge once the screen is free again. The hint-dismiss
## path also drains one, but a nudge parked behind a modal (minigame briefing)
## with no tour step pending would otherwise never fire.
func _process(delta: float) -> void:
	if _pending_nudge.is_empty():
		set_process(false)
		return
	_pending_tick += delta
	if _pending_tick < 0.4:
		return
	_pending_tick = 0.0
	if (_active_hint and is_instance_valid(_active_hint)) or _modal_card_active():
		return
	var k := _pending_nudge
	_pending_nudge = ""
	set_process(false)
	call_deferred("nudge", k)


func _on_hint_dismissed() -> void:
	_active_hint = null
	if not _pending_nudge.is_empty():
		var k := _pending_nudge
		_pending_nudge = ""
		call_deferred("nudge", k)
	if _step == STEP_FINALE:
		_set_step(DONE)
		# The tour is over; point at the optional lore collectathon once,
		# right as the player is looking for what to do next.
		call_deferred("nudge", "bottle")


## True once the five-step tour has been seen through (or the save predates it).
## Ambient nudges that teach post-tour systems gate on this so the intro never
## gets crowded.
func is_tour_complete() -> bool:
	return _step >= DONE


## Public entry for ambient nudges. `kind` is "bag", "bottle", "upgrade",
## "tune", "deep_cache", "undo", "quest" or "meet". Cheap to call every frame: after
## the first delivery the flag is cached in memory.
func nudge(kind: String) -> void:
	var key := ""
	match kind:
		"bag": key = NUDGE_BAG
		"bottle": key = NUDGE_BOTTLE
		"upgrade": key = NUDGE_UPGRADE
		"tune": key = NUDGE_TUNE
		"deep_cache": key = NUDGE_DEEP_CACHE
		"undo": key = NUDGE_UNDO
		"quest": key = NUDGE_QUEST
		"meet": key = NUDGE_MEET
		"ledger": key = NUDGE_LEDGER
		"gold": key = NUDGE_GOLD
		"starfish": key = NUDGE_STARFISH
		"starfish_final": key = NUDGE_STARFISH_FINAL
		"tide": key = NUDGE_TIDE
		"tip": key = NUDGE_TIP
		"welcome_back": key = NUDGE_WELCOME_BACK
		"watcher_note": key = NUDGE_WATCHER_NOTE
		"courier": key = NUDGE_COURIER
		_: return
	if not _nudge_state.has(key):
		_nudge_state[key] = bool(SaveManager.load_game().get(key, false))
	if bool(_nudge_state[key]):
		return
	# Don't smother an active step card or a modal guide/briefing; queue the
	# nudge to fire once the current card is dismissed instead of dropping it.
	if (_active_hint and is_instance_valid(_active_hint)) or _modal_card_active():
		_pending_nudge = kind
		_pending_tick = 0.0
		set_process(true)
		return
	_nudge_state[key] = true
	SaveManager.update_game({key: true})
	match kind:
		"bag":
			_spawn_card("Bag almost full!",
				"[font_size=20]Your hold is over [color=#ffd27f]85% capacity[/color].\nSell at the [color=#9fe2ff]shop[/color] (north) before the next run — bulk sales of 5+ pay a bonus.[/font_size]",
				"Got it")
		"bottle":
			_spawn_card("Bottles on the shore",
				"[font_size=20]Keep an eye on the waterline — [color=#9fe2ff]message bottles[/color] wash up along the beach.\nRead the six notes for a secret. (They sparkle. Usually.)\nFive [color=#ffd27f]starfish[/color] also hide around the island — worth a poke while you are wandering.[/font_size]",
				"Nice")
		"upgrade":
			_spawn_card("Room for more?",
				"[font_size=20]Your first sale — nice work.\nThe [color=#9fe2ff]shop[/color] sells a [color=#ffd27f]+10 kg bag[/color] for cash, and the terminal up on the [color=#9fe2ff]island map[/color] can grow it with trash instead.\nEither way, a bigger hold means fewer trips home.[/font_size]",
				"Got it")
		"tune":
			_spawn_card("Tune up the dock",
				"[font_size=20]Your scrap can buy upgrades now.\nOpen the [color=#9fe2ff]island menu[/color] (top-right) — Move Speed costs [color=#ffd27f]%d trash[/color], with Collection Range and Deep Cache beside it.\nUpgrades spend materials, not money, so weigh them against a sale.[/font_size]" % GameState.get_move_speed_cost(),
				"Got it")
		"deep_cache":
			_spawn_card("Deep Cache",
				"[font_size=20]Both [color=#9fe2ff]Reef Rescue[/color] (combo pickups) and the [color=#9fe2ff]Upcycle bench[/color] bank [color=#ffd27f]Upcycle score[/color].\nSpend it at the [color=#9fe2ff]island menu[/color] on the [color=#ffd27f]Deep Cache[/color] — it deepens every dive.\nDeep Cache upgrades spend the same score.[/font_size]",
				"Got it")
		"undo":
			_spawn_card("Oops — bulk sale?",
				"[font_size=20]Sold the whole pile by accident?\nThe [color=#ffd27f]Undo last sale[/color] button at the bottom of the shop puts it all back — materials and cash — as long as your bag can fit the lot.[/font_size]",
				"Got it")
		"quest":
			_spawn_card("Someone needs a hand",
				"[font_size=20]An islander is holding out for a trade.\nThe [color=#9fe2ff]quest tracker[/color] (left) shows who wants what, and a [color=#ffd27f]glowing sprite with a ★[/color] means you have enough to deliver right now.\nTalk to them on the map — the reward can go straight into your bag.[/font_size]",
				"Let's go")
		"tide":
			_spawn_card("The sea has moods",
				"[font_size=20]The HUD line ([color=#9fe2ff]≈ …[/color]) is today's tide report.\nIt is the same for every keeper on that day — it bends the reef, the belt and the golden rolls.\nCheck the water before you work; it always tells the truth eventually.[/font_size]",
				"Good to know")
		"watcher_note":
			_spawn_card("A page from the far point",
				"[font_size=20]The note was waiting on the path to the lantern.\nThe island counts those the keeper keeps — so does whatever watches it.[/font_size]",
				"I understand")
		"courier":
			_spawn_card("The courier is real",
				"[font_size=20]The counter keeps a page from the Silverfin itself.\nThe reef knows this fish — the [color=#9fe2ff]Reef Registry[/color] keeps its name.\nDive on an [color=#9fe2ff]Eel Run[/color] tide: the courier rides the fast water.[/font_size]",
				"I'll look")
		"welcome_back":
			_spawn_card("Welcome back, keeper",
				"[font_size=20]The island held its breath while you were gone.\n				The tide kept its four days without you — here is where things stand, and who has been waiting.[/font_size]",
				"Good to be home")
		"tip":
			_spawn_card("The dockhand knows the sea",
				"[font_size=20]Look closely at the [color=#9fe2ff]Spend money[/color] column — a dockhand will tell you tomorrow's tide for [color=#ffd27f]25$[/color].\nOne day of foresight is all he sells. The HUD keeps it for the day, and the tide will make you rich or poor.[/font_size]",
				"Worth a listen")
		"starfish_final":
			_spawn_card("One more…",
				"[font_size=20]Four starfish down. One still hides on the island.\n" +
				"Walk the coast at low tide — the shelves along the rocks are where they lie closest.[/font_size]",
				"Nearly there")
		"starfish":
			_spawn_card("A starfish!",
				"[font_size=20]Starfish hide along the walkable coast.\n" +
				"Five of them are out there — collect them all for a [color=#ffd27f]+$25 Tide Pool[/color] and a [color=#9fe2ff]STARLIGHT[/color] badge on your journal.\n" +
				"The stats page keeps count next to the bottles.[/font_size]",
				"Got it")
		"gold":
			_spawn_card("A golden find",
				"[font_size=20]Something on the belt shines different.\n" +
				"[color=#ffd27f]Golden scrap[/color] is worth double for correct sorts — and a golden [color=#ffd27f]Goldie[/color] in the reef pays +5 when you graze it on purpose.\n" +
				"The stats page keeps a running count of everything glinting on your route.[/font_size]",
				"Shiny")
		"ledger":
			_spawn_card("Every note found",
				"[font_size=20]You have read all three shoreline bottles.\n" +
				"The [color=#9fe2ff]stats page[/color] (from the main menu) has a [color=#ffd27f]Tide Ledger[/color] — every note you found, re-readable any time.\n" +
				"Something about the Pact might make a fourth note wash up…[/font_size]",
				"Lovely")
		"meet":
			_spawn_card("Islanders about",
				"[font_size=20]You have not met everyone yet.\nThe islanders walking the trail hand out a little [color=#9fe2ff]first-visit gift[/color] each — and the [color=#ffd27f]quest tracker[/color] glares when someone wants a trade.\nHave a wander.[/font_size]",
				"Let's say hi")


func _clear_hint() -> void:
	if _active_hint and is_instance_valid(_active_hint):
		_active_hint.queue_free()
	_active_hint = null
