extends CanvasLayer
# Small always-visible progress panel for upcycle score and reef depth.

@onready var uc_bar: ProgressBar = $Panel/VBox/UpcycleBar
@onready var reef_bar: ProgressBar = $Panel/VBox/ReefBar
@onready var label: Label = $Panel/VBox/Label
@onready var panel: PanelContainer = $Panel

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

func _process(_delta: float) -> void:
	if uc_bar:
		uc_bar.max_value = max(1.0, float(max(1, GameState.best_upcycle_score)))
		uc_bar.value = min(uc_bar.max_value, float(GameState.upcycle_score))
	if reef_bar:
		reef_bar.max_value = max(1.0, float(max(10.0, GameState.best_reef_depth)))
		reef_bar.value = min(reef_bar.max_value, GameState.reef_garbage)
	if label:
		label.text = "Upcycle %d | Reef %d m / %d fish" % [GameState.upcycle_score, int(GameState.reef_garbage), GameState.reef_fish]
