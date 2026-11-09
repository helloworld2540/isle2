extends Control

const SCENE_MAIN_MENU: String = "res://scenes/main_menu.tscn"

@onready var _stats_label: Label = $"StatsLabel"
@onready var _back_button: Button = $"BackButton"
@onready var _volume_slider: HSlider = $"VolumeSlider"
@onready var _reduce_checkbox: CheckBox = $"ReduceMotion"


# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------

func _ready() -> void:
	GameState.restore()
	_load_settings()
	_update_stats_display()
	_connect_signals()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()


# ------------------------------------------------------------------------------
# Initialization & Binding
# ------------------------------------------------------------------------------

func _load_settings() -> void:
	var sd: Dictionary = SaveManager.load_game()

	if _volume_slider:
		var master_vol: float = float(sd.get("master_volume", AudioManager.get_master_volume()))
		_volume_slider.value = master_vol * 100.0

	if _reduce_checkbox:
		_reduce_checkbox.button_pressed = bool(sd.get("reduce_motion", false))


func _connect_signals() -> void:
	if _back_button and not _back_button.pressed.is_connected(_on_back):
		_back_button.pressed.connect(_on_back)

	if _volume_slider and not _volume_slider.value_changed.is_connected(_on_volume_changed):
		_volume_slider.value_changed.connect(_on_volume_changed)

# ------------------------------------------------------------------------------
# Display & Formatting
# ------------------------------------------------------------------------------

func _update_stats_display() -> void:
	if _stats_label:
		_stats_label.text = _build_stats_text()


func _build_stats_text() -> String:
	var sd: Dictionary = SaveManager.load_game()
	var lines: Array[String] = [
		"Stats",
		"Score: %d  (best %d)" % [GameState.upcycle_score, GameState.best_upcycle_score],
		"Money: %d" % GameState.money,
		"Lifetime shop earnings: %d" % GameState.lifetime_earnings,
		"Trash total: %d kg" % GameState.trash_inventory
	]

	for mat: String in GameState.trash_by_type.keys():
		var count: int = int(GameState.trash_by_type[mat])
		lines.append("  %s: %d" % [mat, count])

	var reef_garb: int = int(GameState.reef_garbage)
	var best_depth: int = int(GameState.best_reef_depth)
	lines.append("Reef garbage: %d kg (best depth %d)" % [reef_garb, best_depth])
	lines.append("Fish rescued: %d (best %d)" % [GameState.reef_fish, GameState.best_reef_fish])
	lines.append("Best sort streak: %d" % GameState.best_sort_streak)

	var saved_vol: float = float(sd.get("master_volume", AudioManager.get_master_volume()))
	lines.append("Last save master volume: %d%%" % int(round(saved_vol * 100.0)))

	return "\n".join(lines)


# ------------------------------------------------------------------------------
# Signal Handlers & Event Callbacks
# ------------------------------------------------------------------------------

func _on_volume_changed(value: float) -> void:
	var normalized_vol: float = value / 100.0
	AudioManager.set_master_volume(normalized_vol)

	var sd: Dictionary = SaveManager.load_game()
	sd["master_volume"] = normalized_vol
	SaveManager.save_game(sd)

func _on_back() -> void:
	AudioManager.play_sfx("return")
	SceneTransition.change_scene(SCENE_MAIN_MENU)
