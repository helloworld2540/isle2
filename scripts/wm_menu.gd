extends CanvasLayer
class_name WorldMenu

## The island menu (☰): volume sliders, reduced motion, upgrades bought
## with trash, and the settings/about entries for the world map.

const NOTIFICATION_QUEUE := preload("res://scenes/ui/notification_queue.tscn")
const FxSparkle := preload("res://scripts/fx_sparkle.gd")
# World map pause/menu overlay.

@onready var panel: Control = $MenuPanel
@onready var hud_menu_button: Button = $HUDMenuButton
@onready var bgm_cycle_timer: Timer = $BgmCycleTimer
@onready var resume_button: Button = $MenuPanel/Center/Card/HBoxContainer/VBoxContainer/ResumeButton
@onready var save_button: Button = $MenuPanel/Center/Card/HBoxContainer/VBoxContainer/SaveButton
@onready var journal_button: Button = $MenuPanel/Center/Card/HBoxContainer/VBoxContainer/JournalButton
@onready var cap_status: Label = $MenuPanel/Center/Card/HBoxContainer/VBoxContainer/CapStatus

@onready var card: PanelContainer = $MenuPanel/Center/Card
@onready var upcycle_progress_box: HBoxContainer = $MenuPanel/Center/Card/HBoxContainer/Infobox/ProgressBox
@onready var upcycle_label: Label = $MenuPanel/Center/Card/HBoxContainer/Infobox/ProgressBox/UpcycleLbl
@onready var upcycle_progress: ProgressBar = $MenuPanel/Center/Card/HBoxContainer/Infobox/ProgressBox/UpcycleProgress

@onready var reef_progress_box: HBoxContainer = $MenuPanel/Center/Card/HBoxContainer/Infobox/ReefProgressBox
@onready var reef_label: Label = $MenuPanel/Center/Card/HBoxContainer/Infobox/ReefProgressBox/ReefLbl
@onready var reef_progress: ProgressBar = $MenuPanel/Center/Card/HBoxContainer/Infobox/ReefProgressBox/ReefProgress

@onready var settings_button: Button = $MenuPanel/Center/Card/HBoxContainer/Infobox/SettingsButton
@onready var about_button: Button = $MenuPanel/Center/Card/HBoxContainer/VBoxContainer/AboutButton
@onready var about_canvas: CanvasLayer = $AboutCanvas
@onready var settings_view: PanelContainer = $MenuPanel/Center/Card/HBoxContainer/Infobox/SettingsView
@onready var settings_panel: VBoxContainer = $MenuPanel/Center/Card/HBoxContainer/Infobox/SettingsView/SettingsPanel
@onready var confirm_panel = $ConfirmPanel

var _toggling := false
var _bgm_cycle_index := 0
var _bgm_cycle_tracks: Array[String] = ["world", "ambience", "world", "reef"]
var _hud_queue: Node = null

func _ready() -> void:
	if panel:
		panel.visible = false

	process_mode = Node.PROCESS_MODE_ALWAYS
	_wire_signals()
	_setup_settings_ui()
	_update_progress_bars()
	_prepare_overlay()

	get_viewport().size_changed.connect(_clamp_menu_width)
	_clamp_menu_width()
	
	AudioManager.play_bgm("world")
	_setup_bgm_cycle()

func _process(_delta: float) -> void:
	if panel and panel.visible:
		_update_progress_bars()

func _wire_signals() -> void:
	if resume_button: resume_button.pressed.connect(_on_resume_pressed)
	if save_button: save_button.pressed.connect(_on_save_pressed)
	if about_button: about_button.pressed.connect(_on_about_pressed)
	if about_canvas and about_canvas.has_signal("closed"):
		about_canvas.closed.connect(_on_about_closed)
	if journal_button: journal_button.pressed.connect(_on_journal_pressed)
	if confirm_panel: confirm_panel.confirmed.connect(_do_save_and_leave)
	if hud_menu_button: hud_menu_button.pressed.connect(_toggle)
	if settings_button: settings_button.pressed.connect(_toggle_settings)

func _setup_settings_ui() -> void:
	pass


func _format_inventory() -> String:
	var lines: PackedStringArray = []
	for key in GameState.trash_by_type.keys():
		var qty: int = GameState.trash_by_type.get(key, 0)
		if qty > 0:
			lines.append("  %s x%d" % [str(key), qty])
	
	return "Inventory: empty" if lines.is_empty() else "Inventory:\n" + "\n".join(lines)

func _on_resume_pressed() -> void:
	_toggle()

func _toggle() -> void:
	if _toggling: return
	_toggling = true
	
	if panel:
		panel.visible = not panel.visible
		get_tree().paused = panel.visible
		# Join the modal-card handshake while open so the tutorial director
		# does not stack hint cards on top of the pause overlay.
		if panel.visible:
			panel.add_to_group("ui_modal_card")
		else:
			panel.remove_from_group("ui_modal_card")
		
		# hide world progress while paused
		var prog := get_node_or_null("../WorldProgress")
		if prog: prog.visible = not panel.visible
		
		if panel.visible:
			if settings_panel and settings_panel.has_method("sync_from_settings"):
				settings_panel.sync_from_settings()
			_clamp_menu_width()
			if resume_button:
				resume_button.grab_focus()
				
			if GameSettings.reduce_motion:
				# No fade under Reduce motion: the card is simply there.
				panel.modulate.a = 1.0
			else:
				panel.modulate.a = 0.0
				var fade_tw := create_tween()
				fade_tw.tween_property(panel, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
	_toggling = false

func _toggle_settings() -> void:
	# Settings is a bounded "view" that swaps out the progress sections
	# so the card never outgrows the screen, even with the panel expanded.
	var show_settings := not (settings_view and settings_view.visible)
	if settings_view:
		settings_view.visible = show_settings
	if upcycle_progress_box:
		upcycle_progress_box.visible = not show_settings
	if reef_progress_box:
		reef_progress_box.visible = not show_settings
	if settings_button:
		settings_button.text = "Back to upgrades" if show_settings else "Settings"
	if show_settings and settings_panel and settings_panel.has_method("sync_from_settings"):
		settings_panel.sync_from_settings()

func _clamp_menu_width() -> void:
	if not card: return

	# Viewport size is fixed in practice (stretch mode = viewport); clamp the
	# card to the safe area so the 24px margins always hold. Height is bounded
	# by construction: the settings view swaps out the upgrades sections.
	var vp := get_viewport().get_visible_rect().size
	var vw: float = maxf(vp.x, 1.0)
	var target_w: float = clampf(vw - 48.0, 320.0, 900.0)

	card.custom_minimum_size.x = target_w

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
		_toggle()
		get_viewport().set_input_as_handled()

func _prepare_overlay() -> void:
	if panel: panel.visible = false
	get_tree().paused = false

func _on_about_pressed() -> void:
	# The keeper's own page — one press, no cost.
	if about_canvas and about_canvas.has_method("present"):
		about_canvas.present()


func _on_about_closed() -> void:
	pass


func _on_save_pressed() -> void:
	# Destructive-feeling action gets one confirmation first.
	if confirm_panel:
		var island := GameState.slot_name if not GameState.slot_name.is_empty() else "this island"
		confirm_panel.present("Save & leave?", "Progress is saved automatically. \"%s\" will be waiting." % island, "Leave")
		return
	_do_save_and_leave()


func _do_save_and_leave() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		SaveManager.save_player_position(player.global_position)
	
	if panel:
		panel.visible = false
		panel.remove_from_group("ui_modal_card")
	get_tree().paused = false
	SceneTransition.change_scene("res://scenes/main_menu.tscn")

## Deep-link to the stats page; the stats scene's Back button returns here.
func _on_journal_pressed() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		SaveManager.save_player_position(player.global_position)
	GameState.return_to_scene = "res://scenes/world.tscn"
	AudioManager.play_sfx("pickup")
	if panel:
		panel.visible = false
		panel.remove_from_group("ui_modal_card")
	get_tree().paused = false
	SceneTransition.change_scene("res://scenes/stats_menu.tscn")

func _update_progress_bars() -> void:
	if upcycle_progress:
		upcycle_progress.max_value = maxf(1.0, float(GameState.get_deep_cache_cost()))
		upcycle_progress.value = minf(upcycle_progress.max_value, float(GameState.upcycle_score))
		
	if reef_progress:
		reef_progress.max_value = maxf(1.0, float(maxi(10, GameState.best_reef_depth)))
		reef_progress.value = minf(reef_progress.max_value, float(GameState.reef_garbage))
		
	_update_cap_status()

func _update_cap_status() -> void:
	if not cap_status: return
	
	var cap: int = maxi(1, GameState.get_inventory_capacity())
	var weight := GameState.get_inventory_weight()
	var ratio := float(weight) / float(cap)
	
	if ratio >= 1.0:
		cap_status.text = "Inventory FULL (%d/%d) — upgrade or sell" % [weight, cap]
		cap_status.modulate = Color(1.0, 0.35, 0.35, 1.0)
	elif ratio >= 0.85:
		cap_status.text = "Inventory heavy (%d/%d)" % [weight, cap]
		cap_status.modulate = Color(1.0, 0.85, 0.35, 1.0)
	else:
		cap_status.text = ""

# --- BGM Management ---

func _setup_bgm_cycle() -> void:
	if not bgm_cycle_timer:
		return
	
	bgm_cycle_timer.timeout.connect(_tick_bgm_cycle)
	bgm_cycle_timer.start()

func _tick_bgm_cycle() -> void:
	_bgm_cycle_index = (_bgm_cycle_index + 1) % _bgm_cycle_tracks.size()
	AudioManager.play_bgm(_bgm_cycle_tracks[_bgm_cycle_index])
