extends Control

const SCENE_MAIN_MENU: String = "res://scenes/main_menu.tscn"
## Display order of the guide's station sections. Entries carry a "where" tag.
const GUIDE_GROUPS: Array[String] = ["Reef Rescue", "Upcycle", "Shop", "Islanders", "Island"]

@onready var _stats_label: Label = $"Margin/VBox/StatsScroll/StatsLabel"
@onready var _back_button: Button = $"Margin/VBox/BackButton"
@onready var _guide_button: Button = $"Margin/VBox/GuideButton"
@onready var _guide_overlay: Control = $"GuideOverlay"
@onready var _guide_list: Label = $"GuideOverlay/Panel/VBox/Scroll/GuideList"
@onready var _guide_close: Button = $"GuideOverlay/Panel/VBox/GuideClose"


# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------

func _ready() -> void:
	_update_stats_display()
	_connect_signals()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Escape closes the guide first, then leaves the stats page.
		if _guide_overlay and _guide_overlay.visible:
			_close_guide()
		else:
			_on_back()


# ------------------------------------------------------------------------------
# Binding
# ------------------------------------------------------------------------------

func _connect_signals() -> void:
	if _back_button:
		_back_button.pressed.connect(_on_back)
	if _guide_button:
		_guide_button.pressed.connect(_open_guide)
	if _guide_close:
		_guide_close.pressed.connect(_close_guide)


# ------------------------------------------------------------------------------
# Display & Formatting
# ------------------------------------------------------------------------------

func _update_stats_display() -> void:
	if _stats_label:
		_stats_label.text = _build_stats_text()


## The scrap-journal reading of the page: which era of the island is the
## player in, most advanced first. Purely cosmetic — no numbers, just flavour
## earned by what the save has actually done.
func _era_name() -> String:
	if GameState.is_achievement_unlocked("island_steward"):
		return "The Steward Era"
	if GameState.tidekeeper:
		return "The Pact Era"
	if GameState.market_level >= GameState.MARKET_MAX_LEVEL:
		return "The Trading Era"
	if GameState.circuits_completed >= 3:
		return "The Circuit Era"
	if GameState.reef_dives >= 10:
		return "The Diving Era"
	if GameState.upcycle_runs >= 10:
		return "The Bench Era"
	if GameState.lifetime_earnings > 0:
		return "The First-Coin Era"
	return "The Fresh Shore"


## One line of what the name means for the bench, the reef and the till.
func _era_tag() -> String:
	if GameState.is_achievement_unlocked("island_steward"):
		return "every page of the journal is blank except yours"
	if GameState.tidekeeper:
		return "the tide answers its keeper"
	if GameState.market_level >= GameState.MARKET_MAX_LEVEL:
		return "peak prices, peak dives"
	if GameState.circuits_completed >= 3:
		return "the loop runs itself when you do"
	if GameState.reef_dives >= 10:
		return "the waterline knows your wake"
	if GameState.upcycle_runs >= 10:
		return "the bench is a reflex now"
	if GameState.lifetime_earnings > 0:
		return "the till has its first song"
	return "every page still blank"


func _build_stats_text() -> String:
	var lines: Array[String] = [
		"Stats",
		"Upcycle score: %d  (best %d)" % [GameState.upcycle_score, GameState.best_upcycle_score],
		"Money: %d$  (lifetime %d$)" % [GameState.money, GameState.lifetime_earnings],
		"Bag: %d/%d kg" % [GameState.get_inventory_weight(), GameState.get_inventory_capacity()],
	]
	
	var carried: Array[String] = []
	for mat: String in GameState.trash_by_type.keys():
		var count: int = int(GameState.trash_by_type[mat])
		if count > 0:
			carried.append("%s %d" % [mat, count])
	lines.append("  " + ("nothing yet" if carried.is_empty() else ", ".join(carried)))
	
	lines.append("Reef garbage: %d kg  (best depth %d m)" % [int(GameState.reef_garbage), int(GameState.best_reef_depth)])
	lines.append("Lifetime garbage: %d kg" % GameState.lifetime_garbage_kg)
	lines.append("Fish bumps taken: %d  (best %d)" % [GameState.reef_fish, GameState.best_reef_fish])
	lines.append("Best sort streak: %d" % GameState.best_sort_streak)
	lines.append("Deep Cache: %s" % ("tier %d" % GameState.deep_cache_tier if GameState.deep_cache else "not owned"))
	lines.append("Market Contact: +%d$/unit  ·  Reef Charter: %d dive bumps" % [
		GameState.get_market_bonus(), 3 + GameState.get_reef_bonus_lives()
	])
	lines.append("Quests turned in: %d" % GameState.quests_completed)
	lines.append("Island circuits completed: %d  (+$%d each)" % [GameState.circuits_completed, GameState.CIRCUIT_BONUS_MONEY])
	lines.append("Field log: %d dives · %d bench runs" % [GameState.reef_dives, GameState.upcycle_runs])
	lines.append("Era: %s — %s" % [_era_name(), _era_tag()])
	
	# Compact achievement roll: the banner cards carry the full text, this is
	# the checklist players scroll to when they want to know what is left.
	var marks: Array[String] = []
	for def in GameState.achievement_definitions():
		var id := String(def.get("id", ""))
		var mark := "✓" if GameState.is_achievement_unlocked(id) else "·"
		marks.append("%s %s" % [mark, String(def.get("short", id))])
	lines.append("Achievements %d/%d: %s" % [
		GameState.achievement_count(),
		GameState.achievement_total(),
		"  ".join(marks),
	])
	if GameState.is_harbor_hero():
		var bonus_kg: int = GameState.HARBOR_HERO_CAPACITY_BONUS * 10
		lines.append("Title: Harbor Hero — every quest tier cleared (+%d kg bag)." % bonus_kg)
	if GameState.island_patron:
		lines.append("✦ Patron of the Isle — 1500$ given back to keep the island clean.")
	if GameState.tidekeeper:
		lines.append("✦ Tidekeeper of the Isle — 2500$ pact funded; the reef keeps your bag (+10 kg).")
	elif GameState.quests_completed > 0:
		lines.append("Title progress: Harbor Hero at %d turn-ins (%d/%d)" % [
			GameState.HARBOR_HERO_TURNS,
			GameState.quests_completed,
			GameState.HARBOR_HERO_TURNS,
		])
	
	return "\n".join(lines)


# ------------------------------------------------------------------------------
# Signal Handlers
# ------------------------------------------------------------------------------

## The compact roll in the stats text only shows short names; this page spells
## out what each one actually means.
func _open_guide() -> void:
	if _guide_overlay == null:
		return
	if _guide_list:
		_guide_list.text = _build_guide_text()
	_guide_overlay.visible = true
	AudioManager.play_sfx("pickup")


func _close_guide() -> void:
	if _guide_overlay == null:
		return
	_guide_overlay.visible = false
	AudioManager.play_sfx("return")


func _build_guide_text() -> String:
	var definitions := GameState.achievement_definitions()
	var lines: Array[String] = []
	
	# Grouped by where the goal is earned, so the page doubles as a route map
	# of the island. Unknown tags fall through to a trailing section.
	for group in GUIDE_GROUPS:
		var section: Array[String] = []
		for def in definitions:
			if String(def.get("where", "")) != group:
				continue
			var id := String(def.get("id", ""))
			var mark := "✓" if GameState.is_achievement_unlocked(id) else "·"
			section.append("%s  %s\n     %s" % [mark, String(def.get("title", "")), String(def.get("subtitle", ""))])
		if section.is_empty():
			continue
		lines.append("— %s —" % group.to_upper())
		lines.append_array(section)
		lines.append("")
	
	lines.append("%d of %d earned." % [GameState.achievement_count(), GameState.achievement_total()])
	return "\n".join(lines)


func _on_back() -> void:
	AudioManager.play_sfx("return")
	SceneTransition.change_scene(SCENE_MAIN_MENU)
