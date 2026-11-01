extends CanvasLayer
# Small always-visible progress panel for upcycle score and reef depth.

@onready var uc_bar: ProgressBar = $Panel/VBox/UpcycleBar
@onready var reef_bar: ProgressBar = $Panel/VBox/ReefBar
@onready var label: Label = $Panel/VBox/Label

func _ready() -> void:
	GameState.restore()
	if uc_bar:
		uc_bar.max_value = 100.0
	if reef_bar:
		reef_bar.max_value = 1000.0

func _process(_delta: float) -> void:
	if uc_bar:
		uc_bar.max_value = max(1.0, float(max(1, GameState.best_upcycle_score)))
		uc_bar.value = min(uc_bar.max_value, float(GameState.upcycle_score))
	if reef_bar:
		reef_bar.max_value = max(1.0, float(max(10.0, GameState.best_reef_depth)))
		reef_bar.value = min(reef_bar.max_value, GameState.reef_garbage)
	if label:
		label.text = "Upcycle %d | Reef %d m / %d fish" % [GameState.upcycle_score, int(GameState.reef_garbage), GameState.reef_fish]
