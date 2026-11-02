extends Control
# Lightweight pause/settings overlay, triggered from wm_menu Save & Quit path.

@onready var master_slider: HSlider = $"MasterVolume"
@onready var sfx_slider: HSlider = $"SFXVolume"


func _ready() -> void:
	if master_slider:
		master_slider.value = AudioManager.get_master_volume() * 100.0
		master_slider.value_changed.connect(_on_master_changed)
	if sfx_slider:
		sfx_slider.value = AudioManager.get_sfx_volume() * 100.0
		sfx_slider.value_changed.connect(_on_sfx_changed)

func _on_master_changed(v: float) -> void:
	AudioManager.set_master_volume(v / 100.0)
	var sd := SaveManager.load_game()
	sd["master_volume"] = v / 100.0
	SaveManager.save_game(sd)

func _on_sfx_changed(v: float) -> void:
	AudioManager.set_sfx_volume(v / 100.0)
	var sd := SaveManager.load_game()
	sd["sfx_volume"] = v / 100.0
	SaveManager.save_game(sd)

	SaveManager.save_game(sd)
