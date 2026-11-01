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
	var panel := PanelContainer.new()
	panel.name = "SaveSummaryPanel"
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(640, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.14, 0.8)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.border_color = Color(0.4, 0.7, 0.9, 0.4)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	var summary := Label.new()
	summary.name = "SaveSummary"
	summary.text = _summary_text()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.custom_minimum_size = Vector2(600, 0)
	vbox.add_child(summary)
	# thumbnail-style mini stats
	var stats := Label.new()
	stats.name = "MiniStats"
	stats.text = _mini_stats_text()
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.modulate = Color(0.85, 0.95, 1.0, 0.95)
	vbox.add_child(stats)

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

func _mini_stats_text() -> String:
	if not SaveManager.has_save():
		return "No runs yet — try Reef Rescue or Upcycle!"
	return "Best fish %d  •  Best streak %d  •  Lifetime %d" % [GameState.best_reef_fish, GameState.best_sort_streak, GameState.lifetime_earnings]

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
