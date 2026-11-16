extends VBoxContainer

## Shared volume + accessibility controls. Used by the world-menu overlay and
## the stats page so both always agree with AudioManager and GameSettings.

@onready var master_label: Label = $MasterRow/MasterLabel
@onready var master_slider: HSlider = $MasterRow/MasterSlider
@onready var music_label: Label = $MusicRow/MusicLabel
@onready var music_slider: HSlider = $MusicRow/MusicSlider
@onready var ambience_label: Label = $AmbienceRow/AmbienceLabel
@onready var ambience_slider: HSlider = $AmbienceRow/AmbienceSlider
@onready var sfx_label: Label = $SfxRow/SfxLabel
@onready var sfx_slider: HSlider = $SfxRow/SfxSlider
@onready var reduce_motion_checkbox: CheckBox = $ReduceMotion


func _ready() -> void:
	sync_from_settings()
	
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	ambience_slider.value_changed.connect(_on_ambience_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	reduce_motion_checkbox.toggled.connect(_on_reduce_motion_toggled)


func sync_from_settings() -> void:
	master_slider.value = AudioManager.get_master_volume() * 100.0
	music_slider.value = AudioManager.get_music_volume() * 100.0
	ambience_slider.value = AudioManager.get_ambience_volume() * 100.0
	sfx_slider.value = AudioManager.get_sfx_volume() * 100.0
	reduce_motion_checkbox.button_pressed = GameSettings.reduce_motion
	_refresh_labels()


func _refresh_labels() -> void:
	master_label.text = "Master Volume: %d%%" % int(master_slider.value)
	music_label.text = "Music Volume: %d%%" % int(music_slider.value)
	ambience_label.text = "Ambience Volume: %d%%" % int(ambience_slider.value)
	sfx_label.text = "SFX Volume: %d%%" % int(sfx_slider.value)


func _on_master_changed(value: float) -> void:
	AudioManager.set_master_volume(value / 100.0)
	_refresh_labels()


func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value / 100.0)
	_refresh_labels()


func _on_ambience_changed(value: float) -> void:
	AudioManager.set_ambience_volume(value / 100.0)
	_refresh_labels()


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value / 100.0)
	_refresh_labels()


func _on_reduce_motion_toggled(pressed: bool) -> void:
	GameSettings.set_reduce_motion(pressed)
