extends Label

func _ready() -> void:
	GameState.restore()

func _process(_delta: float) -> void:
	text = "Progress | Upcycle: %d | Reef: %d m / %d fish" % [GameState.upcycle_score, int(GameState.reef_garbage), GameState.reef_fish]
