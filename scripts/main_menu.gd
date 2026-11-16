extends Control
class_name MainMenu

@onready var new_save_button: Button = $Buttons/NewSaveButton
@onready var load_save_button: Button = $Buttons/LoadSaveButton
@onready var quit_button: Button = $Buttons/QuitButton
@onready var save_summary: Label = $SaveSummaryPanel/VBoxContainer/SaveSummary
@onready var save_summary_panel: PanelContainer = $SaveSummaryPanel
@onready var more_stats_button: Button = $SaveSummaryPanel/VBoxContainer/MoreStatsButton
@onready var confirm_panel: CanvasLayer = $ConfirmPanel

const STATS_SCENE := "res://scenes/stats_menu.tscn"
const WORLD_SCENE := "res://scenes/world.tscn"

func _ready() -> void:
	_wire_buttons()
	GameState.restore()
	_refresh_summary()
	_play_entrance_animation()
	_spawn_ambient_motion()
	AudioManager.play_bgm("menu")
	_pulse_both_titles()

func _wire_buttons() -> void:
	new_save_button.pressed.connect(_on_new_save_pressed)
	load_save_button.disabled = not SaveManager.has_save()
	load_save_button.pressed.connect(_on_load_save_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	if more_stats_button:
		more_stats_button.visible = SaveManager.has_save()
		more_stats_button.pressed.connect(_on_stats_pressed)
	if confirm_panel:
		confirm_panel.confirmed.connect(_start_fresh_save)

func _refresh_summary() -> void:
	save_summary.text = _summary_text()

func _summary_text() -> String:
	if not SaveManager.has_save():
		return "No save found yet. Start a new save to begin cleaning."
	
	# GameState restored the save in _ready; nothing to re-read here.
	var summary := "Continue summary:\nScore %d (best %d)  |  Trash %d kg  |  Fish %d \nBest streak %d  |  Lifetime earnings %d  | %d$ \nAchievements %d/%d  |  Inventory totals: %s" % [
		GameState.upcycle_score, GameState.best_upcycle_score,
		GameState.get_inventory_weight(), GameState.reef_fish,
		GameState.best_sort_streak, GameState.lifetime_earnings,
		GameState.money,
		GameState.achievement_count(), GameState.achievement_total(),
		_format_inventory_totals()
	]
	
	# How fresh is this save? Datestamp at the top of a continue screen.
	var saved := SaveManager.get_save_mtime()
	if saved > 0:
		summary += "\nLast played: %s" % Time.get_datetime_string_from_unix_time(saved, false)
	# Titles are identity, so they get their own line rather than a stat column.
	var badges: Array[String] = []
	if GameState.is_harbor_hero():
		badges.append("★ Harbor Hero")
	if GameState.island_patron:
		badges.append("◆ Patron of the Isle")
	if not badges.is_empty():
		summary += "\n" + "  ·  ".join(badges)
	return summary


## Owning both titles earns one celebratory pulse of the summary on load.
func _pulse_both_titles() -> void:
	if GameSettings.reduce_motion:
		return
	if not (GameState.is_harbor_hero() and GameState.island_patron):
		return
	if not save_summary:
		return
	save_summary.pivot_offset = save_summary.size * 0.5
	var tw := create_tween()
	tw.tween_property(save_summary, "scale", Vector2(1.08, 1.08), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(save_summary, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var color_tw := create_tween()
	color_tw.tween_property(save_summary, "modulate", Color(1.35, 1.15, 0.5, 1.0), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	color_tw.tween_property(save_summary, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _format_inventory_totals() -> String:
	var parts: Array = []
	for k in GameState.trash_by_type.keys():
		var v: int = int(GameState.trash_by_type.get(k, 0))
		if v > 0:
			parts.append("%s x%d" % [str(k), v])
	if parts.is_empty():
		return "empty"
	return ", ".join(parts)

func _on_new_save_pressed() -> void:
	# A fresh save wipes save.json AND its backup irreversibly — never let a
	# stray tap on "New Save" destroy an existing island. Confirm first.
	if SaveManager.has_save() and confirm_panel:
		AudioManager.play_sfx("open")
		confirm_panel.present("Start over?", "Your saved island — bags, dives, achievements, quests, everything — will be wiped for good.", "Start over")
		return
	_start_fresh_save()


func _start_fresh_save() -> void:
	SaveManager.new_save()
	GameState.restore()
	SceneTransition.change_scene(WORLD_SCENE)

func _on_load_save_pressed() -> void:
	if not SaveManager.has_save():
		return
	GameState.restore()
	SceneTransition.change_scene(WORLD_SCENE)

func _on_quit_pressed() -> void:
	# Quitting bypasses SceneTransition's flush, so write out the debounced
	# save explicitly or the last ~0.4 s of play is lost.
	GameState.flush_save()
	get_tree().quit()

func _on_stats_pressed() -> void:
	AudioManager.play_sfx("return")
	SceneTransition.change_scene(STATS_SCENE)

func _spawn_ambient_motion() -> void:
	var size := get_viewport_rect().size
	var count := 6
	for i in range(count):
		var dot := load("res://scenes/ui/color_rect.tscn").instantiate() as ColorRect
		dot.color = Color(0.5, 0.8, 1.0, randf_range(0.05, 0.25))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var w := randf_range(6.0, 18.0)
		var h := randf_range(6.0, 18.0)
		dot.size = Vector2(w, h)
		dot.position = Vector2(randf() * max(1.0, size.x - w), randf() * max(1.0, size.y - h))
		add_child(dot)
		if GameSettings.reduce_motion:
			continue  # scattered glow stays, the drift stops
		var tw := dot.create_tween().set_loops()
		tw.tween_property(dot, "position:x", dot.position.x + randf_range(-40.0, 40.0), randf_range(2.5, 4.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(dot, "position:y", dot.position.y + randf_range(-25.0, 25.0), randf_range(2.0, 4.0)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _play_entrance_animation() -> void:
	var targets: Array = [
		new_save_button, 
		load_save_button, 
		quit_button, 
		save_summary_panel, 
	]
	for t in targets:
		if not t:
			continue
		if GameSettings.reduce_motion:
			continue  # everything is already where it lives
		t.modulate.a = 0.0
		t.scale = Vector2(0.9, 0.9)
	var ease_tw := create_tween()
	for i in range(targets.size()):
		var t: Control = targets[i]
		if not t:
			continue
		ease_tw.tween_interval(0.08 * float(i))
		ease_tw.tween_property(t, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ease_tw.tween_property(t, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
