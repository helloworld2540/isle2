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
@onready var upgrades_label: Label = $MenuPanel/Center/Card/HBoxContainer/Infobox/UpgradesLabel
@onready var upgrades_panel: PanelContainer = $MenuPanel/Center/Card/HBoxContainer/Infobox/UpgradesPanel
@onready var upgrade_panel: VBoxContainer = $MenuPanel/Center/Card/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel
@onready var upgrade_status: Label = $MenuPanel/Center/Card/HBoxContainer/Infobox/Header/TitleCol/UpgradeStatus
@onready var tide_status: Label = $MenuPanel/Center/Card/HBoxContainer/Infobox/Header/TitleCol/TideStatus
@onready var move_faster_btn: Button = $MenuPanel/Center/Card/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel/MoveFasterBtn
@onready var collection_range_btn: Button = $MenuPanel/Center/Card/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel/CollectionRangeBtn
@onready var deep_cache_btn: Button = $MenuPanel/Center/Card/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel/DeepCacheBtn
@onready var deep_cache_upgrade_btn: Button = $MenuPanel/Center/Card/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel/DeepCacheUpgradeBtn
@onready var inventory_cap_btn: Button = $MenuPanel/Center/Card/HBoxContainer/Infobox/UpgradesPanel/UpgradePanel/InventoryCapBtn

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
	if move_faster_btn: move_faster_btn.pressed.connect(_buy_move)
	if collection_range_btn: collection_range_btn.pressed.connect(_buy_range)
	if deep_cache_btn: deep_cache_btn.pressed.connect(_buy_deep_cache)
	if deep_cache_upgrade_btn: deep_cache_upgrade_btn.pressed.connect(_buy_deep_cache_upgrade)
	if inventory_cap_btn: inventory_cap_btn.pressed.connect(_buy_inv_cap)
	if settings_button: settings_button.pressed.connect(_toggle_settings)

func _setup_settings_ui() -> void:
	_refresh_upgrade_ui()


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
			_refresh_upgrade_ui()
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
	# Settings is a bounded "view" that swaps out the upgrades/progress sections
	# so the card never outgrows the screen, even with the panel expanded.
	var show_settings := not (settings_view and settings_view.visible)
	if settings_view:
		settings_view.visible = show_settings
	if upgrades_panel:
		upgrades_panel.visible = not show_settings
	if upgrades_label:
		upgrades_label.visible = not show_settings
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

# --- Upgrades & Costs ---

func _move_cost() -> int:
	return GameState.get_move_speed_cost()

func _range_cost() -> int:
	return GameState.get_range_cost()

func _move_cost_text() -> String:
	return "Move Speed Lv.%d (+8%%) — %d trash" % [GameState.upgrade_move, GameState.get_move_speed_cost()]

func _range_cost_text() -> String:
	return "Range Lv.%d (+12px) — %d trash" % [GameState.upgrade_range, GameState.get_range_cost()]

func _deep_cache_text() -> String:
	if GameState.deep_cache:
		return "Deep Cache: OWNED · Tier %d (+%d kg)" % [GameState.deep_cache_tier, 5 * GameState.deep_cache_tier + 3 * GameState.inventory_capacity_level]
	return "Deep Cache (30 score) — bonus debris, never wasted"

func _upgrade_status_text() -> String:
	var dc := "DeepCache" if GameState.deep_cache else "-"
	return "Upgrades: Move %d | Range %d | %s" % [GameState.upgrade_move, GameState.upgrade_range, dc]

func _deep_cache_upgrade_text() -> String:
	var next_tier := GameState.deep_cache_tier + 1
	return "Deep Cache Tier %d — %d score (+%d kg/run)" % [next_tier, 15 * GameState.deep_cache_tier, 5 * next_tier + 3 * GameState.inventory_capacity_level]

func _inv_cap_text() -> String:
	var cost := 6 + GameState.inventory_capacity_level * 3
	return "Inv Cap Lv.%d (%d/%d kg) — %d trash" % [GameState.inventory_capacity_level, GameState.get_inventory_weight(), GameState.get_inventory_capacity(), cost]

# --- Purchasing ---

func _process_upgrade(btn: Button, success: bool, failure_msg: String) -> void:
	if not success:
		_flash(btn)
		_toast(failure_msg)
		return
	
	_refresh_player_upgrades()
	AudioManager.play_sfx("upgrade", 1.05)
	_flash_success(btn)
	_spawn_upgrade_sparkle(btn)
	_refresh_upgrade_ui()


func _refresh_player_upgrades() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("refresh_upgrades"):
		player.refresh_upgrades()

func _buy_move() -> void:
	_process_upgrade(move_faster_btn, GameState.purchase_move_speed(), "Need more trash to upgrade Move Speed")

func _buy_range() -> void:
	_process_upgrade(collection_range_btn, GameState.purchase_range(), "Need more trash to upgrade Collection Range")

func _buy_deep_cache() -> void:
	if GameState.deep_cache:
		_flash_success(deep_cache_btn)
		return
	_process_upgrade(deep_cache_btn, GameState.purchase_deep_cache(), "Need 30 upcycle score to buy Deep Cache")

func _buy_deep_cache_upgrade() -> void:
	if not GameState.deep_cache:
		_flash(deep_cache_upgrade_btn)
		return
	_process_upgrade(deep_cache_upgrade_btn, GameState.upgrade_deep_cache(), "Need %d upcycle score to upgrade Deep Cache" % (15 * GameState.deep_cache_tier))

func _buy_inv_cap() -> void:
	var cost := 6 + GameState.inventory_capacity_level * 3
	_process_upgrade(inventory_cap_btn, GameState.purchase_inventory_capacity(), "Need %d trash to increase Inventory Cap" % cost)

func _refresh_upgrade_ui() -> void:
	if upgrade_status: upgrade_status.text = _upgrade_status_text()
	if tide_status and GameSettings.hide_tide:
		tide_status.text = "Today: the sea keeps its own counsel — and so do you."
		tide_status.tooltip_text = "Hide the tide is on. Earn the tide with your eyes."
	elif tide_status:
		tide_status.text = "Today: %s · day %d%s" % [TideReport.hud_line(), GameState.island_day(), ("  ·  streak %d" % GameState.tide_streak) if GameState.tide_streak > 1 else ""]
		tide_status.tooltip_text = "Tide report — %s
%s" % [TideReport.summary(), TideReport.blurb()]
	
	if deep_cache_btn:
		deep_cache_btn.text = _deep_cache_text()
		deep_cache_btn.disabled = GameState.deep_cache
		
	if deep_cache_upgrade_btn:
		deep_cache_upgrade_btn.text = _deep_cache_upgrade_text()
		deep_cache_upgrade_btn.disabled = not GameState.deep_cache
		
	if inventory_cap_btn:
		inventory_cap_btn.disabled = GameState.get_inventory_weight() < (6 + GameState.inventory_capacity_level * 3)
		inventory_cap_btn.text = _inv_cap_text()
		
	if move_faster_btn:
		move_faster_btn.disabled = GameState.get_inventory_weight() < _move_cost()
		move_faster_btn.text = _move_cost_text()
		
	if collection_range_btn:
		collection_range_btn.disabled = GameState.get_inventory_weight() < _range_cost()
		collection_range_btn.text = _range_cost_text()

# --- UI Feedback & Effects ---

func _ensure_hud_queue() -> void:
	if not _hud_queue:
		_hud_queue = NOTIFICATION_QUEUE.instantiate()
		add_child(_hud_queue)

func _toast(text: String) -> void:
	_ensure_hud_queue()
	_hud_queue.push(text, Color(1.0, 0.85, 0.35, 1.0), 1.4)

func _flash(btn: Button) -> void:
	if not btn: return
	var tw := btn.create_tween()
	btn.modulate = Color(1.0, 0.4, 0.4, 1.0)
	tw.tween_property(btn, "modulate", Color.WHITE, 0.5)

func _flash_success(btn: Button) -> void:
	if not btn: return
	var tw := btn.create_tween()
	btn.modulate = Color(0.5, 1.0, 0.55, 1.0)
	tw.tween_property(btn, "modulate", Color.WHITE, 0.6)

func _spawn_upgrade_sparkle(anchor: Control) -> void:
	if not anchor or GameSettings.reduce_motion: return
	
	var r := anchor.get_global_rect()
	FxSparkle.burst(self, r.position + r.size * 0.5, Color(0.6, 1.0, 0.8, 1.0), {"amount": 24, "lifetime": 0.5, "vel_min": 40.0, "vel_max": 110.0, "gravity": 160.0})

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
