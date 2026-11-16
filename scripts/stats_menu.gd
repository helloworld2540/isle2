extends Control

const SCENE_MAIN_MENU: String = "res://scenes/main_menu.tscn"

@onready var _stats_label: Label = $"Margin/VBox/StatsLabel"
@onready var _back_button: Button = $"Margin/VBox/BackButton"


# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------

func _ready() -> void:
	GameState.restore()
	_update_stats_display()
	_connect_signals()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()


# ------------------------------------------------------------------------------
# Binding
# ------------------------------------------------------------------------------

func _connect_signals() -> void:
	if _back_button:
		_back_button.pressed.connect(_on_back)


# ------------------------------------------------------------------------------
# Display & Formatting
# ------------------------------------------------------------------------------

func _update_stats_display() -> void:
	if _stats_label:
		_stats_label.text = _build_stats_text()


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
	lines.append("Fish bumps taken: %d  (best %d)" % [GameState.reef_fish, GameState.best_reef_fish])
	lines.append("Best sort streak: %d" % GameState.best_sort_streak)
	lines.append("Deep Cache: %s" % ("tier %d" % GameState.deep_cache_tier if GameState.deep_cache else "not owned"))
	lines.append("Quests turned in: %d" % GameState.quests_completed)
	if GameState.is_harbor_hero():
		var bonus_kg: int = GameState.HARBOR_HERO_CAPACITY_BONUS * 10
		lines.append("Title: Harbor Hero — every quest tier cleared (+%d kg bag)." % bonus_kg)
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

func _on_back() -> void:
	AudioManager.play_sfx("return")
	SceneTransition.change_scene(SCENE_MAIN_MENU)
