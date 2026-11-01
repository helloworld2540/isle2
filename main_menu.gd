extends Control

@onready var new_save_button: Button = $NewSaveButton
@onready var load_save_button: Button = $LoadSaveButton
@onready var quit_button: Button = $QuitButton

const STATS_SCENE := "res://scenes/stats_menu.tscn"

func _ready() -> void:
	new_save_button.pressed.connect(_on_new_save_pressed)
	load_save_button.pressed.connect(_on_load_save_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	load_save_button.disabled = not SaveManager.has_save()
	GameState.restore()
	AudioManager.play_bgm("menu")
	_build_summary()
	_build_stats_button()

func _build_summary() -> void:
	var summary := Label.new()
	summary.name = "SaveSummary"
	summary.position = Vector2(30, 30)
	summary.custom_minimum_size = Vector2(600, 0)
	summary.text = _summary_text()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(summary)

func _summary_text() -> String:
	if not SaveManager.has_save():
		return "No save found yet. Start a new save to begin cleaning."
	var sd := SaveManager.load_game()
	GameState.restore()
	return "Continue summary:\nScore %d (best %d)  |  Trash %d kg  |  Fish %d (best %d)\nBest streak %d  |  Lifetime earnings %d" % [
		GameState.upcycle_score, GameState.best_upcycle_score,
		GameState.trash_inventory, GameState.reef_fish, GameState.best_reef_fish,
		GameState.best_sort_streak, GameState.lifetime_earnings
	]

func _build_stats_button() -> void:
	var stats := Button.new()
	stats.text = "Stats"
	stats.position = Vector2(60, 100)
	stats.custom_minimum_size = Vector2(140, 0)
	stats.pressed.connect(func():
		AudioManager.play_sfx("return")
		SceneTransition.change_scene(STATS_SCENE)
	)
	add_child(stats)

func _on_start_pressed() -> void:
	SceneTransition.change_scene("res://scenes/world.tscn")

func _on_new_save_pressed() -> void:
	SaveManager.new_save()
	SceneTransition.change_scene("res://scenes/world.tscn")

func _on_load_save_pressed() -> void:
	if not SaveManager.has_save():
		return
	SceneTransition.change_scene("res://scenes/world.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
