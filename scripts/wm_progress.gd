extends CanvasLayer
class_name WorldProgress

## The world HUD progress card: Deep Cache bar, circuit bonus tracker
## and the ≈ tide line, plus route advice for the next stop.

const RouteAdvisor := preload("res://scripts/route_advisor.gd")

## Trail dots highlight the leg that leads to the advised stop.
@export var flow_dots_path: NodePath = ^"../../Navigation/FlowDots"

# --- Node References ---
@onready var flow_dots: Node2D = get_node(flow_dots_path) as Node2D
@onready var panel: PanelContainer = $"Panel"
@onready var vbox: VBoxContainer = $"Panel/VBox"
@onready var uc_bar: ProgressBar = $"Panel/VBox/UpcycleBar"
@onready var reef_bar: ProgressBar = $"Panel/VBox/ReefBar"
@onready var main_label: Label = $"Panel/VBox/Label"
@onready var inv_label: Label = $Panel/VBox/InvLabel
@onready var money_label: Label = $Panel/VBox/MoneyLabel
@onready var circuit_label: Label = $Panel/VBox/CircuitLabel
@onready var next_label: Label = $Panel/VBox/NextStop
@onready var hero_label: Label = $Panel/VBox/HeroTitle
@onready var bottle_label: Label = $Panel/VBox/BottleTitle
@onready var starfish_label: Label = $Panel/VBox/StarfishTitle
@onready var tide_label: Label = $Panel/VBox/TideTitle

var _pulse_state: float = 0.0
var _circuit_text := ""
## Frame-loop text setters run every physics tick; cache the last written
## strings so a static HUD costs nothing but a compare.
var _money_text := ""
var _main_text := ""
var _inv_text := ""
## Route advice only needs to be re-derived a few times a second.
const ADVICE_TICK_SECONDS := 0.35
var _advice_tick := 0.0

func _ready() -> void:
	# GameState restores the save itself on boot; the HUD only reads it.
	# The Steward Era earns a golden hush over the world — subtle, alpha 0.12,
	# no motion, reduced-motion safe (it is not motion at all).
	var tint := get_node("StewardTint") as ColorRect
	if tint:
		tint.visible = GameState.is_achievement_unlocked("island_steward")
	if main_label:
		main_label.modulate = Color(0.9, 0.95, 1.0, 0.9)
	if uc_bar:
		# The bar fills toward the score price of the next Deep Cache purchase.
		uc_bar.tooltip_text = "Progress toward the Deep Cache (score banks at the bench and on dives)"
	GameState.harbor_hero_unlocked.connect(_refresh_hero_title)
	GameState.circuit_progress_changed.connect(_refresh_circuit_label)
	GameState.bottle_read.connect(_refresh_bottle_label)
	GameState.starfish_collected.connect(_refresh_starfish_label)
	_refresh_hero_title()
	_refresh_circuit_label()
	_refresh_bottle_label()
	_refresh_starfish_label()
	_refresh_tide_label()
	_refresh_next_stop()
	# On the first world load of the day the tide line arrives fresh — swell
	# it gently so the keeper feels the card land in the HUD too. Reduced
	# motion holds perfectly still.
	if tide_label and GameState.tide_report_day == TideReport.day_index() and not GameSettings.reduce_motion:
		tide_label.scale = Vector2(1.25, 1.25)
		var tw := create_tween()
		tw.tween_property(tide_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	# Calculate shared variables once per frame
	var cap: int = max(1, GameState.get_inventory_capacity())
	var inv_amount: int = GameState.get_inventory_weight()
	var ratio: float = float(inv_amount) / float(cap)
	
	_update_progress_bars()
	_update_main_label(cap, inv_amount, ratio)
	_update_money_label()
	_update_inventory_label(delta, ratio, cap, inv_amount)
	
	_advice_tick += delta
	if _advice_tick >= ADVICE_TICK_SECONDS:
		_advice_tick = 0.0
		_refresh_next_stop()

	# Once-ever ambient nudge when the hold first gets heavy. The director
	# throttles itself (persisted flag + skips while another card is up).
	if ratio >= 0.85:
		TutorialDirector.nudge("bag")
	
	# Once the tour is understood, point at the island-map upgrade terminal the
	# first time the player can actually afford a speed/range tier. Gated on the
	# tour so the intro never stacks this on top of a step card.
	if TutorialDirector.is_tour_complete():
		var tune_cost := mini(GameState.get_move_speed_cost(), GameState.get_range_cost())
		if inv_amount >= tune_cost:
			TutorialDirector.nudge("tune")
	# Same idea, score-priced: point at the Deep Cache once the player can
	# afford the 30-score unlock. One-shot, persisted, gated on the tour.
	if TutorialDirector.is_tour_complete() and not GameState.deep_cache:
		if GameState.upcycle_score >= 30:
			TutorialDirector.nudge("deep_cache")

# --- Initialization ---

# --- Update Methods ---

func _update_progress_bars() -> void:
	if uc_bar:
		uc_bar.max_value = max(1.0, float(GameState.get_deep_cache_cost()))
		uc_bar.value = min(uc_bar.max_value, float(GameState.upcycle_score))
		
	if reef_bar:
		reef_bar.max_value = max(10.0, float(GameState.best_reef_depth))
		reef_bar.value = min(reef_bar.max_value, float(GameState.reef_garbage))

func _update_money_label() -> void:
	if money_label:
		var text := "Money: %d$" % GameState.money
		if text != _money_text:
			_money_text = text
			money_label.text = text


## Bottles found so far. The line is hidden at 0 until the first one is read
## so the HUD stays calm for players who are not collecting; it then counts up,
## flips gold at the base set, and flips again once the Pact's reply is read.
func _refresh_bottle_label(_count: int = -1) -> void:
	if not bottle_label:
		return
	var pact_read := GameState.is_story_read("bottle_pact")
	# The Pact's answer is never counted toward the base three.
	var base_count := 0
	for id in GameState.bottles_read:
		if id != "bottle_pact":
			base_count += 1
	if base_count <= 0 and not pact_read:
		bottle_label.visible = false
		return
	var chorus := GameState.is_achievement_unlocked("silent_chorus")
	var whole := GameState.is_achievement_unlocked("whole_sea")
	if whole:
		# Every voice, including the far point's — the sea is finished talking.
		bottle_label.text = "✦ The Whole Sea"
		bottle_label.modulate = Color(1.0, 0.93, 0.6, 1.0)
	elif chorus:
		# The full chorus never needs counting — it is the weather now.
		bottle_label.text = "✦ The Silent Chorus"
		bottle_label.modulate = Color(1.0, 0.84, 0.32, 1.0)
	elif pact_read:
		bottle_label.text = "✦ The Pact is Kept"
		bottle_label.modulate = Color(0.55, 0.95, 0.85, 1.0)
	elif base_count >= 3:
		bottle_label.text = "✦ Tide Keeper"
		bottle_label.modulate = Color(1.0, 0.84, 0.32, 1.0)
	else:
		bottle_label.text = "◆ Bottles %d/3" % base_count
		bottle_label.modulate = Color(0.72, 0.92, 1.0, 0.95)
	bottle_label.visible = true


## Starfish found so far — hidden until the first one is collected, like the
## bottle line; counts up to a gold "STARLIGHT KEEPER" flip at five.
func _refresh_starfish_label(_id: String = "") -> void:
	if not starfish_label:
		return
	var found := GameState.starfish_found.size()
	if found <= 0:
		starfish_label.visible = false
		return
	if found >= 5:
		starfish_label.text = "✦ STARLIGHT KEEPER"
		starfish_label.modulate = Color(1.0, 0.82, 0.32, 1.0)
	else:
		starfish_label.text = "★ Starfish %d/5" % found
		starfish_label.modulate = Color(1.0, 0.82, 0.55, 1.0)
	starfish_label.visible = true


## Today's sea conditions, always visible: the player should know why the belt
## or the reef feels different before they walk into a portal.
func _refresh_tide_label() -> void:
	if not tide_label:
		return
	# The dockhand's bought foresight: tomorrow goes right on the HUD as a
	# second line — tooltips don't exist on touch. Day-stamped, so it lapses
	# on its own when the day rolls over. Two short lines beat one wide one
	# in this 264 px-wide panel.
	# A fresh island is, by definition, on its first day — the claim lands
	# after this HUD is built, so never show a nonsense "day 0".
	var days: int = GameState.island_day()
	# Hidden tide: the sea keeps its own counsel. Same rules, same rumors —
	# just no cheating.
	if GameSettings.hide_tide:
		tide_label.text = "≈ Tide hidden — read the water yourself."
		tide_label.tooltip_text = "Hide the tide is on. Read the water yourself."
		return
	# After the island shows its keeper the fifth tide, the HUD simply keeps it.
	if GameState.fifth_tide_granted:
		tide_label.text = "✦ The Fifth Tide"
	elif GameState.tide_almanac_granted:
		tide_label.text = "✦ The Almanac Is Kept"
		tide_label.tooltip_text = "THE FIFTH TIDE — the island's own.\nThe keeper keeps the water now."
		return
	if GameState.harbor_tip_purchased():
		tide_label.text = "≈ %s · day %d\nTomorrow: %s" % [TideReport.hud_line(), days, GameState.tomorrow_tide_title()]
	else:
		tide_label.text = "≈ %s · day %d" % [TideReport.hud_line(), days]
	var tooltip := "Tide report — %s\n%s" % [TideReport.summary(), TideReport.blurb()]
	if GameState.harbor_tip_purchased():
		tooltip += "\nTomorrow (paid tip): %s" % GameState.tomorrow_tide_title()
	tide_label.tooltip_text = tooltip


## The earned title lives on the always-visible progress card, not only in the
## stats page, so the reward stays present while the player loops the island.
func _refresh_hero_title() -> void:
	if not hero_label:
		return
	hero_label.visible = GameState.is_harbor_hero()
	if hero_label.visible:
		var bonus_kg: int = GameState.HARBOR_HERO_CAPACITY_BONUS * 10
		hero_label.text = "★ Harbor Hero · +%d kg bag" % bonus_kg


## Route progress for the island circuit: which of the three stops are ticked
## off, plus how many full loops have been paid out. Filled dots follow the
## RouteAdvisor's station order, not the order the player visited them.
func _refresh_circuit_label(_visited: Array = []) -> void:
	if not circuit_label:
		return
	
	var dots := ""
	for id in GameState.CIRCUIT_STATIONS:
		dots += "●" if GameState.has_visited_station(id) else "○"
	
	var text := "Route %s %d/%d" % [dots, GameState.circuit_visits.size(), GameState.CIRCUIT_STATIONS.size()]
	if GameState.circuits_completed > 0:
		text += " · %d" % GameState.circuits_completed
	
	if text == _circuit_text:
		return
	_circuit_text = text
	circuit_label.text = text
	circuit_label.modulate = Color(0.55, 1.0, 0.72, 1.0) if GameState.circuit_visits.size() >= GameState.CIRCUIT_STATIONS.size() - 1 else Color(0.72, 0.91, 1.0, 1.0)


## "Next: 2 · Upcycle — 3 Reef Debris to sort". The same advice drives the
## portal highlight, so the loop reads as one route instead of a menu.
func _refresh_next_stop() -> void:
	if not next_label:
		return
	var advice := RouteAdvisor.next_stop(get_tree())
	var station := String(advice.get("station", ""))
	next_label.text = "Next: %s — %s" % [String(advice.get("label", "")), String(advice.get("reason", ""))]
	next_label.modulate = Color(1.0, 0.86, 0.35, 1.0) if station == "npc" else Color(0.6, 0.94, 0.78, 1.0)

	# The dots only know how to point at the three stations; an NPC errand is
	# already marked by the gold star over that islander, so leave the trail
	# neutral for it.
	if flow_dots and flow_dots.has_method("set_hint"):
		flow_dots.set_hint("" if station == "npc" else station)


func _update_main_label(cap: int, inv_amount: int, ratio: float) -> void:
	if not main_label: return
	
	var cap_state := ""
	if ratio >= 1.0:
		cap_state = "Bag FULL (%d/%d)" % [inv_amount, cap]
	elif ratio >= 0.85:
		cap_state = "Bag heavy (%d/%d)" % [inv_amount, cap]
		
	var text := "Trash %d/%d kg" % [inv_amount, cap]
	if cap_state != "":
		text += " | " + cap_state
	if text != _main_text:
		_main_text = text
		main_label.text = text

func _update_inventory_label(delta: float, ratio: float, cap: int, inv_amount: int) -> void:
	var pulse_target := 0.0
	if ratio >= 1.0:
		pulse_target = 1.0
	elif ratio >= 0.85:
		pulse_target = 0.6 + 0.4 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006))
		
	# Smoothly transition the pulse state (replaces the old set_meta/get_meta usage)
	_pulse_state = lerpf(_pulse_state, pulse_target, delta * 4.0)
	
	var inv_text := _get_inv_summary_text(inv_amount, cap)
	if inv_text != _inv_text:
		_inv_text = inv_text
		inv_label.text = inv_text
	if inv_label:
		inv_label.visible = inv_text.is_empty()
	_apply_capacity_pulse()


## Subtle near-full bag pulse. A heavy bag tints the inventory line toward
## amber and breathes ±3.5% around 1.0 on the same sine that drives the
## pulse target, so the signal reads as "sell soon" breathing rather than an
## alarm. Under reduced motion the breath freezes and only the tint remains.
func _apply_capacity_pulse() -> void:
	if not inv_label:
		return
	var p := _pulse_state
	if p <= 0.05:
		inv_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		inv_label.scale = Vector2.ONE
		return
	# Pivot at the label's center so the breath scales in place, not from the corner.
	inv_label.pivot_offset = inv_label.size * 0.5
	var breath := 1.0
	if not GameSettings.reduce_motion:
		breath = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
	inv_label.modulate = Color(1.0, 1.0, 1.0, 1.0).lerp(Color(1.0, 0.78, 0.35, 1.0), p * (0.45 + 0.55 * breath))
	var s := 1.0 + 0.035 * p * (breath - 0.5) * 2.0
	inv_label.scale = Vector2(s, s)

func _get_inv_summary_text(current_inv: int, max_cap: int) -> String:
	var lines: Array[String] = []
	
	for key in GameState.trash_by_type.keys():
		var qty := int(GameState.trash_by_type.get(key, 0))
		if qty > 0:
			lines.append("%s %d" % [str(key), qty])
			
	if lines.is_empty():
		return ""
		
	return ", ".join(lines)
