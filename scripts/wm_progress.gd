extends CanvasLayer

# --- Node References ---
@onready var panel: PanelContainer = $"Panel"
@onready var vbox: VBoxContainer = $"Panel/VBox"
@onready var uc_bar: ProgressBar = $"Panel/VBox/UpcycleBar"
@onready var reef_bar: ProgressBar = $"Panel/VBox/ReefBar"
@onready var main_label: Label = $"Panel/VBox/Label"
@onready var inv_label: Label = $Panel/VBox/InvLabel

var _pulse_state: float = 0.0

func _ready() -> void:
	GameState.restore()
	
	_setup_panel_style()
	
	if main_label:
		main_label.modulate = Color(0.9, 0.95, 1.0, 0.9)

func _process(delta: float) -> void:
	# Calculate shared variables once per frame
	var cap: int = max(1, GameState.get_inventory_capacity())
	var inv_amount: int = GameState.trash_inventory
	var ratio: float = float(inv_amount) / float(cap)
	
	_update_progress_bars()
	_update_main_label(cap, inv_amount, ratio)
	_update_inventory_label(delta, ratio, cap, inv_amount)

# --- Initialization ---

func _setup_panel_style() -> void:
	if not panel: return
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.12, 0.8)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.border_color = Color(0.4, 0.7, 0.9, 0.35)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	
	panel.add_theme_stylebox_override("panel", sb)

# --- Update Methods ---

func _update_progress_bars() -> void:
	if uc_bar:
		uc_bar.max_value = max(1.0, float(GameState.best_upcycle_score))
		uc_bar.value = min(uc_bar.max_value, float(GameState.upcycle_score))
		
	if reef_bar:
		reef_bar.max_value = max(10.0, float(GameState.best_reef_depth))
		reef_bar.value = min(reef_bar.max_value, float(GameState.reef_garbage))

func _update_main_label(cap: int, inv_amount: int, ratio: float) -> void:
	if not main_label: return
	
	var cap_state := ""
	if ratio >= 1.0:
		cap_state = "Bag FULL (%d/%d)" % [inv_amount, cap]
	elif ratio >= 0.85:
		cap_state = "Bag heavy (%d/%d)" % [inv_amount, cap]
		
	main_label.text = "Trash %d/%d kg | %s" % [
		inv_amount, 
		cap, 
		cap_state
	]

func _update_inventory_label(delta: float, ratio: float, cap: int, inv_amount: int) -> void:
	var pulse_target := 0.0
	if ratio >= 1.0:
		pulse_target = 1.0
	elif ratio >= 0.85:
		pulse_target = 0.6 + 0.4 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006))
		
	# Smoothly transition the pulse state (replaces the old set_meta/get_meta usage)
	_pulse_state = lerpf(_pulse_state, pulse_target, delta * 4.0)

	inv_label.text = _get_inv_summary_text(inv_amount, cap)

func _get_inv_summary_text(current_inv: int, max_cap: int) -> String:
	var lines: Array[String] = []
	
	for key in GameState.trash_by_type.keys():
		var qty := int(GameState.trash_by_type.get(key, 0))
		if qty > 0:
			lines.append("%s %d" % [str(key), qty])
			
	if lines.is_empty():
		return " (empty)"
		
	return ", ".join(lines)
