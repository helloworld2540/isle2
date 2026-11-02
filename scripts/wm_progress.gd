extends CanvasLayer
# Small always-visible progress panel for upcycle score and reef depth.

@onready var uc_bar: ProgressBar = get_node_or_null("Panel/VBox/UpcycleBar")
@onready var reef_bar: ProgressBar = get_node_or_null("Panel/VBox/ReefBar")
@onready var label: Label = get_node_or_null("Panel/VBox/Label")
@onready var panel: PanelContainer = get_node_or_null("Panel")
@onready var _inv_label: Label = get_node_or_null("Panel/VBox/InventoryLabel")

func _ready() -> void:
	GameState.restore()
	if uc_bar:
		uc_bar.max_value = 100.0
	if reef_bar:
		reef_bar.max_value = 1000.0
	if panel:
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
	if label:
		label.modulate = Color(0.9, 0.95, 1.0, 0.9)

	# Dynamic inventory breakdown label (added at runtime, no tscn change needed).
	_inv_label = load("res://scenes/ui/label.tscn").instantiate() as Label
	_inv_label.name = "InventoryLabel"
	_inv_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inv_label.custom_minimum_size = Vector2(220, 0)
	_inv_label.set_meta("pulse", 0.0)
	if panel and panel.get_node_or_null("VBox"):
		panel.get_node("VBox").add_child(_inv_label)

func _process(_delta: float) -> void:
	if uc_bar:
		uc_bar.max_value = max(1.0, float(max(1, GameState.best_upcycle_score)))
		uc_bar.value = min(uc_bar.max_value, float(GameState.upcycle_score))
	if reef_bar:
		reef_bar.max_value = max(1.0, float(max(10.0, GameState.best_reef_depth)))
		reef_bar.value = min(reef_bar.max_value, GameState.reef_garbage)
	if label:
		label.text = "Upcycle %d | Reef %d m / %d fish  |  Trash %d/%d kg" % [GameState.upcycle_score, int(GameState.reef_garbage), GameState.reef_fish, GameState.trash_inventory, GameState.get_inventory_capacity()]
	if _inv_label:
		var prev_pulse: float = float(_inv_label.get_meta("pulse", 0.0))
		var cap: int = max(1, GameState.get_inventory_capacity())
		var ratio := float(GameState.trash_inventory) / float(cap)
		var pulse_target := 0.0
		if ratio >= 1.0:
			pulse_target = 1.0
		elif ratio >= 0.85:
			pulse_target = 0.6 + 0.4 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006))
		var new_pulse: float = lerpf(prev_pulse, pulse_target, _delta * 4.0)
		_inv_label.set_meta("pulse", new_pulse)
		_inv_label.modulate = Color(0.9 + 0.1 * new_pulse, 0.95 - 0.15 * new_pulse, 0.85 - 0.25 * new_pulse, 1.0)
		_inv_label.text = _inv_summary_text()

# extend _process label to include inventory material breakdown in a second label

func _inv_summary_text() -> String:
	var lines := []
	for key in GameState.trash_by_type.keys():
		var qty := int(GameState.trash_by_type.get(key, 0))
		if qty > 0:
			lines.append("%s %d" % [str(key).substr(0, 4), qty])
	var head := "Inv %d/%d" % [GameState.trash_inventory, GameState.get_inventory_capacity()]
	if lines.is_empty():
		return head + " (empty)"
	return head + " | " + ", ".join(lines)
