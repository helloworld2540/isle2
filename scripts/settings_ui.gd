extends Control
# Lightweight pause/settings overlay, triggered from wm_menu Save & Quit path.

@onready var master_slider: HSlider = get_node_or_null("MasterVolume")
@onready var reduced_motion_check: CheckButton = get_node_or_null("ReducedMotion")
@onready var sfx_slider: HSlider = get_node_or_null("SFXVolume")


func _ready() -> void:
	if is_instance_valid(master_slider):
		master_slider.value = AudioManager.get_master_volume() * 100.0
		master_slider.value_changed.connect(_on_master_changed)
	if is_instance_valid(sfx_slider):
		sfx_slider.value = AudioManager.get_sfx_volume() * 100.0
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if is_instance_valid(reduced_motion_check):
		reduced_motion_check.button_pressed = AudioManager.get_reduced_motion()
		reduced_motion_check.toggled.connect(_on_reduced_motion_toggled)

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

func _on_reduced_motion_toggled(on: bool) -> void:
	AudioManager.set_reduced_motion(on)
	var sd := SaveManager.load_game()
	sd["reduced_motion"] = on
	SaveManager.save_game(sd)
