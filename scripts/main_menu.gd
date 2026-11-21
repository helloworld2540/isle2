extends Control
class_name MainMenu

## The front door: New Save / Load Island / Quit, the island vista with
## ambient motes, version stamp and the keeper's one-line motto.

@onready var new_save_button: Button = $LeftColumn/Buttons/NewSaveButton
@onready var load_save_button: Button = $LeftColumn/Buttons/LoadSaveButton
@onready var quit_button: Button = $LeftColumn/Buttons/QuitButton
@onready var save_summary: Label = $RightColumn/SaveSummaryPanel/VBoxContainer/Scroll/Body/SaveSummary
@onready var tide_line: Label = $RightColumn/SaveSummaryPanel/VBoxContainer/TideLine
@onready var about_button: Button = $AboutButton
@onready var about_canvas: CanvasLayer = $AboutCanvas
@onready var save_summary_panel: PanelContainer = $RightColumn/SaveSummaryPanel
@onready var more_stats_button: Button = $RightColumn/SaveSummaryPanel/VBoxContainer/MoreStatsButton
@onready var confirm_panel: CanvasLayer = $ConfirmPanel
@onready var slot_picker: CanvasLayer = $SlotPicker

const STATS_SCENE := "res://scenes/stats_menu.tscn"
const WORLD_SCENE := "res://scenes/world.tscn"

func _ready() -> void:
	_wire_buttons()
	# Bind the slot the player last used (migrating a legacy single-file save
	# on first boot), then restore that island into GameState.
	SaveManager.ensure_bound()
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
	if about_button:
		about_button.pressed.connect(_on_about_pressed)
	if slot_picker:
		slot_picker.slot_picked.connect(_on_slot_picked)
		slot_picker.slot_created.connect(_on_slot_created)
		slot_picker.closed.connect(_on_slot_picker_closed)


## The picker may have changed slots, or deleted the one the summary showed.
## Re-read the (possibly new) active slot before redrawing the summary.
func _on_slot_picker_closed() -> void:
	GameState.restore()
	_refresh_summary()


func _on_about_pressed() -> void:
	if about_canvas and about_canvas.has_method("present"):
		about_canvas.call("present")


func _refresh_summary() -> void:
	load_save_button.disabled = not SaveManager.has_save()
	if more_stats_button:
		more_stats_button.visible = SaveManager.has_save()
	if save_summary:
		save_summary.text = _summary_text()
	if tide_line and GameSettings.hide_tide:
		tide_line.text = "≈ The sea keeps its own counsel — and so do you."
		tide_line.tooltip_text = "Hide the tide is on. Earn it with your eyes."
	elif tide_line:
		tide_line.text = "≈ %s · day %d" % [TideReport.hud_line(), GameState.island_day()]
		tide_line.tooltip_text = "Today's tide. The stats page almanac lists all four — the rotation is four days, and every one comes round."


func _summary_text() -> String:
	if not SaveManager.has_save():
		return "No save found yet. Start a new save to begin cleaning."

	# GameState restored the save in _ready; nothing to re-read here.
	var summary := "Score %d (best %d)  ·  Trash %d kg\nFish bumps %d  ·  Best streak %d\nMoney %d$  ·  Lifetime %d$\nAchievements %d/%d  ·  Days on the island: %d" % [
		GameState.upcycle_score, GameState.best_upcycle_score,
		GameState.get_inventory_weight(),
		GameState.reef_fish, GameState.best_sort_streak,
		GameState.money, GameState.lifetime_earnings,
		GameState.achievement_count(), GameState.achievement_total(),
		GameState.tide_days_visited,
	]
	summary += "\nInventory: %s" % _format_inventory_totals()
	var all_days := SaveManager.total_tide_days()
	if all_days > GameState.tide_days_visited:
		summary += "\nAll islands: %d days one keeper" % all_days

	# Which island is this? A one-line identity above the stats.
	summary = "Slot: %s\n%s" % [GameState.slot_name, summary]
	var almanac_suffix := "  ·  almanac kept" if GameState.tide_almanac_granted else ""
	if GameState.tide_best_streak > 1:
		almanac_suffix += "  ·  best streak %d" % GameState.tide_best_streak
	summary += "\nTide almanac %d/4%s" % [GameState.tides_logged.size(), almanac_suffix]

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
	if GameState.is_achievement_unlocked("pale_courier"):
		badges.append("✳ The Pale Courier")
	if GameState.is_achievement_unlocked("whole_sea"):
		badges.append("✦ The Whole Sea")
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
	# A fresh save wipes the slot's save AND its backups irreversibly — never
	# let a stray tap on "New Save" destroy an existing island. Confirm first.
	if SaveManager.has_save() and confirm_panel:
		AudioManager.play_sfx("open")
		confirm_panel.present("Start over?", "Your saved island — bags, dives, achievements, quests, everything — will be wiped for good.", "Start over")
		return
	_start_fresh_save()


func _start_fresh_save() -> void:
	SaveManager.new_save()
	GameState.restore()
	GameState.flush_save()
	SceneTransition.change_scene(WORLD_SCENE)


func _on_load_save_pressed() -> void:
	if not SaveManager.has_save():
		return
	# Always open the island picker so the keeper can choose or confirm their island.
	if slot_picker:
		AudioManager.play_sfx("open")
		slot_picker.present()


func _load_current() -> void:
	GameState.restore()
	SceneTransition.change_scene(WORLD_SCENE)


## Picks a slot from the picker and loads its island.
func _on_slot_picked(slot_id: String) -> void:
	if slot_id.is_empty():
		return
	if not SaveManager.switch_slot(slot_id):
		return
	GameState.restore()
	_refresh_summary()
	SceneTransition.change_scene(WORLD_SCENE)


## Creates a fresh slot from a name typed in the picker, then loads it.
func _on_slot_created(slot_id: String) -> void:
	if slot_id.is_empty():
		return
	if not SaveManager.switch_slot(slot_id):
		return
	GameState.restore()
	_refresh_summary()
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
		# Keep the drifting glow behind the menu cards and buttons: dots are
		# added after the authored UI, so without this they drift over text.
		move_child(dot, 2)
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
