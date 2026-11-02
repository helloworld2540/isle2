extends Control

@onready var stats_label: Label = $"StatsLabel"
@onready var back_button: Button = $"BackButton"
@onready var volume_slider: HSlider = $"VolumeSlider"
@onready var reduce_checkbox: CheckBox = $"ReduceMotion"

func _ready() -> void:
	GameState.restore()
	if stats_label:
		stats_label.text = _stats_text()
	if back_button:
		back_button.pressed.connect(_on_back)
	if volume_slider:
		volume_slider.value = AudioManager.get_master_volume() * 100.0
		volume_slider.value_changed.connect(_on_volume_changed)
	if reduce_checkbox:
		reduce_checkbox.toggled.connect(_on_reduce_toggled)

func _stats_text() -> String:
	var sd := SaveManager.load_game()
	var lines := []
	lines.append("Stats")
	lines.append("Score: %d  (best %d)" % [GameState.upcycle_score, GameState.best_upcycle_score])
	lines.append("Lifetime shop earnings: %d" % GameState.lifetime_earnings)
	lines.append("Trash total: %d kg" % GameState.trash_inventory)
	for k in GameState.trash_by_type.keys():
		lines.append("  %s: %d" % [k, int(GameState.trash_by_type[k])])
	lines.append("Reef garbage: %d kg (best depth %d)" % [int(GameState.reef_garbage), int(GameState.best_reef_depth)])
	lines.append("Fish rescued: %d (best %d)" % [GameState.reef_fish, GameState.best_reef_fish])
	lines.append("Best sort streak: %d" % GameState.best_sort_streak)
	lines.append("Last save master volume: %d%%" % int(round(float(sd.get("master_volume", AudioManager.get_master_volume())) * 100.0)))
	return "\n".join(lines)

func _on_volume_changed(v: float) -> void:
	AudioManager.set_master_volume(v / 100.0)
	var sd := SaveManager.load_game()
	sd["master_volume"] = v / 100.0
	SaveManager.save_game(sd)

func _on_reduce_toggled(v: bool) -> void:
	var sd := SaveManager.load_game()
	SaveManager.save_game(sd)

func _on_back() -> void:
	AudioManager.play_sfx("return")
	SceneTransition.change_scene("res://scenes/main_menu.tscn")
