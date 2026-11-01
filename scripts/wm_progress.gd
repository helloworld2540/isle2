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
		uc_bar.value = min(100.0, float(GameState.upcycle_score))
	if reef_bar:
		reef_bar.value = min(1000.0, GameState.reef_garbage)
	if label:
		label.text = "Upcycle %d | Reef %d m / %d fish" % [GameState.upcycle_score, int(GameState.reef_garbage), GameState.reef_fish]
