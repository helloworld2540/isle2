extends Control
# Lightweight pause/settings overlay, triggered from wm_menu Save & Quit path.

@onready var master_slider: HSlider = get_node_or_null("MasterVolume")

func _ready() -> void:
	if is_instance_valid(master_slider):
		master_slider.value = AudioManager.get_master_volume() * 100.0
		master_slider.value_changed.connect(_on_master_changed)

func _on_master_changed(v: float) -> void:
	AudioManager.set_master_volume(v / 100.0)
	# AudioManager already persists this key; merge defensively to avoid
	# replacing unrelated save data.
	var sd := SaveManager.load_game()
	sd["master_volume"] = v / 100.0
	SaveManager.save_game(sd)
